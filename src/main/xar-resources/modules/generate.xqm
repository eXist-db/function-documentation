xquery version "3.1";


(:~
 : This module scans the database instance for library modules and
 : generates XQDoc for each one that is found.
 : This collection of XQDoc definitions is then used to render
 : the function documentation.
 :)
module namespace generate="http://exist-db.org/apps/fundocs/generate";


import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace inspect="http://exist-db.org/xquery/inspection" at "java:org.exist.xquery.functions.inspect.InspectionModule";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace dbutil="http://exist-db.org/xquery/dbutil" at "dbutil.xqm";


declare namespace xqdoc="http://www.xqdoc.org/1.0";


declare variable $generate:doc-collection := $config:app-root || "/data";


declare function generate:fundocs() {
    (
        generate:load-mapped-modules(),
        generate:load-internal-modules(),
        generate:load-stored-modules()
    )
        => filter(generate:has-definition#1)
        => for-each(generate:generate-and-store-xqdoc#1)
};

declare %private function generate:load-mapped-modules() as array(*)* {
    for $path in util:mapped-modules()
    let $uri := xs:anyURI($path)
    return generate:safe-inspect($uri, inspect:inspect-module-uri#1)
};

declare %private function generate:load-internal-modules() as array(*)* {
    for $path in util:registered-modules()
    let $uri := xs:anyURI($path)
    return generate:safe-inspect($uri, inspect:inspect-module-uri#1)
};

declare %private function generate:load-stored-modules() as array(*)* {
    for $uri in dbutil:find-by-mimetype(xs:anyURI("/db"), "application/xquery")
    return generate:safe-inspect($uri, inspect:inspect-module#1)
};

declare %private function generate:safe-inspect ($moduleUri as xs:anyURI, $inspect as function(xs:anyURI) as element(module)?) as array(*)? {
    try {
        [$moduleUri, $inspect($moduleUri)]
    } catch * {
        (:
         : Expected to fail if XQuery file is not a library module
         : Will also guard against malformed and missing modules
         :)
        util:log("WARN", (
            "Could not compile function documentation for: ",
            $moduleUri, " (", $err:code, ")", $err:description
        ))
    }
};

declare %private function generate:has-definition($module-info as array(*)) as xs:boolean {
    exists($module-info?2)
};

declare %private function generate:generate-and-store-xqdoc ($module-info as array(*)) {
    let $filename := concat(util:hash($module-info?1, "md5"), ".xml"),
        $xqdoc := generate:module-to-xqdoc($module-info?2)

    return
        xmldb:store($generate:doc-collection, $filename, $xqdoc)
            => xs:anyURI()
            => sm:chmod("rw-rw-r--")
};

declare %private function generate:module-to-xqdoc($module as element(module)) as element(xqdoc:xqdoc) {
    <xqdoc:xqdoc xmlns:xqdoc="http://www.xqdoc.org/1.0">
        <xqdoc:control>
            <xqdoc:date>{current-dateTime()}</xqdoc:date>
            <xqdoc:location>{$module/@location/string()}</xqdoc:location>
        </xqdoc:control>
        <xqdoc:module type="library">
            <xqdoc:uri>{$module/@uri/string()}</xqdoc:uri>
            <xqdoc:name>{$module/@prefix/string()}</xqdoc:name>
            <xqdoc:comment>
                <xqdoc:description>{$module/description/string()}</xqdoc:description>
                {
                    if (empty($module/version)) then ()
                    else
                        <xqdoc:version>{$module/version/string()}</xqdoc:version>
                }
                {
                    if (empty($module/author)) then ()
                    else
                        <xqdoc:author>{$module/author/string()}</xqdoc:author>
                }
                {
                    if (empty($module/see)) then ()
                    else
                        <xqdoc:see>{$module/see/string()}</xqdoc:see>
                }
            </xqdoc:comment>
        </xqdoc:module>
        <xqdoc:variables>
        {
            for $variable in $module/variable
            return <xqdoc:variable><xqdoc:name>{ $variable/@name/string() }</xqdoc:name></xqdoc:variable>
        }
        </xqdoc:variables>
        <xqdoc:functions>
        {
            for $function in $module/function
            return generate:function-to-xqdoc($function)
        }
        </xqdoc:functions>
    </xqdoc:xqdoc>
};

declare %private function generate:function-to-xqdoc($function as element(function)) as element(xqdoc:function) {
    <xqdoc:function>
        <xqdoc:name>{$function/@name/string()}</xqdoc:name>
        <xqdoc:signature>{generate:signature($function)}</xqdoc:signature>
        <xqdoc:parameters>{$function/argument ! generate:parameter(.)}</xqdoc:parameters>
        <xqdoc:arity>{count($function/argument)}</xqdoc:arity>
        <xqdoc:return>
            <xqdoc:type occurrence="{generate:cardinality($function/returns/@cardinality)}">{ 
                $function/returns/@type/string() }</xqdoc:type>
        </xqdoc:return>
        {
        if (empty($function/annotation)) then () else
            <xqdoc:annotations>
            {
                for $annotation in $function/annotation 
                return
                    <xqdoc:annotation>
                        <xqdoc:name>{ $annotation/@name/string() }</xqdoc:name>
                        <xqdoc:literal>{
                            if (empty($annotation/value)) then () else
                                "(" || string-join($annotation/value, ", ") || ")"
                        }</xqdoc:literal>
                    </xqdoc:annotation>
            }
            </xqdoc:annotations>
        }
        <xqdoc:comment>
            <xqdoc:description>{$function/description/string()}</xqdoc:description>
            {
                for $argument in $function/argument
                return
                    <xqdoc:param>{ "$" || $argument/@var || " " || $argument/text() }</xqdoc:param>
            }
            <xqdoc:return>
            {
                $function/returns/@type/string() || generate:cardinality($function/returns/@cardinality)
            }{
                if (empty($function/returns/text())) then ()
                else " : " || $function/returns/text()
            }
            </xqdoc:return>
            {
                if (empty($function/deprecated)) then ()
                else
                    <xqdoc:deprecated>{$function/deprecated/string()}</xqdoc:deprecated>
            }  
        </xqdoc:comment>
    </xqdoc:function>
};

declare %private function generate:cardinality($cardinality as xs:string) as xs:string? {
    switch ($cardinality)
        case "zero or one" return "?"
        case "zero or more" return "*"
        case "one or more" return "+"
        default return ()
};

declare %private function generate:parameter($argument as element(argument)) as element(xqdoc:parameter) {
    <xqdoc:parameter>
        <xqdoc:name>{ "$" || $argument/@var }</xqdoc:name>
        <xqdoc:type occurrence="{generate:cardinality($argument/@cardinality)}">{
            $argument/@type/string() }</xqdoc:type>
    </xqdoc:parameter>
};

declare %private function generate:signature($function as element(function)) as xs:string {
    let $arguments :=
        for $argument in $function/argument
        return
            "$" || $argument/@var || " as " || $argument/@type || generate:cardinality($argument/@cardinality)

    return
        $function/@name/string() || "(" || string-join($arguments, ", ") || ")" ||
            " as " || $function/returns/@type || generate:cardinality($function/returns/@cardinality)
};
