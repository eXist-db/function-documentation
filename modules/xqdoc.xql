xquery version "3.0";

(:~
 : Searches the XQuery function documentation. Called from the templating in app.xql.
 :)
module namespace xqdoc="http://www.xqdoc.org/1.0";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare function xqdoc:browse($node as node()) {
    let $module := request:get-parameter("module", ())
    let $functions :=
        if( $module eq "All" ) then
            collection($config:app-data)/xqdoc:xqdoc//xqdoc:function
        else
            collection($config:app-data)/xqdoc:xqdoc[xqdoc:module/xqdoc:uri = $module]//xqdoc:function
    return
        templates:process($node/node(), $functions)
};

declare function xqdoc:search($node as node()) {
    let $q := request:get-parameter("q", ())
    let $type := request:get-parameter("type", ("name"))
    let $module := request:get-parameter("module", ())
    
    let $functions :=
        switch( $type )
            case "name" return
                collection($config:app-data)/xqdoc:xqdoc//xqdoc:function[ngram:contains(xqdoc:name, $q)]
            case "desc" return
                collection($config:app-data)/xqdoc:xqdoc//xqdoc:function[ngram:contains(xqdoc:comment/xqdoc:description, $q)]
        default return ()
        
(:    let $filteredFuncs := :)
(:        if( $module eq "All" ) then $functions:)
(:        else $functions[ancestor::xqdoc:xqdoc/xqdoc:module/xqdoc:uri = $module]:)
    
    return
        templates:process($node/node(), $functions)
};

(:~
 :  Make sure the default function module always comes first.
 :)
declare function xqdoc:module-order($module as element(xqdoc:xqdoc)) {
    let $uri := $module/xqdoc:module/xqdoc:uri
    return
        if ($uri eq "http://www.w3.org/2005/xpath-functions") then
            "0" || $uri
        else
            $uri
};

declare function xqdoc:print-module($module as element(xqdoc:xqdoc), $functions as element(xqdoc:function)) {
    <div class="module" id="{util:document-name($module)}">
        <div class="module-head">
            <h3>{ $module/xqdoc:module/xqdoc:uri/text() }</h3>
            {
                if ($module/xqdoc:control/xqdoc:location) then
                    <h4>{$module/xqdoc:control/xqdoc:location/text()}</h4>
                else
                    ()
            }
            { xqdoc:parse-text($module/xqdoc:module/xqdoc:comment/xqdoc:description) }
        </div>
        <div class="functions">
        {
            for $function in $functions
            order by $function/xqdoc:name/string() ascending
            return
                xqdoc:print-function($function)
        }
        </div>
    </div>
};

declare function xqdoc:print-function($function as element(xqdoc:function)) {
    <div class="function">
        <div class="function-head">
            <h4>{ $function/xqdoc:name/node() }</h4>
            <p class="signature">{ $function/xqdoc:signature/node() }</p>
        </div>
        <div class="function-detail">
            { xqdoc:parse-text($function/xqdoc:comment/xqdoc:description) }
            
            <div class="parameters">
                <p>Parameters:</p>
                <ul>
                {
                    for $param in $function/xqdoc:comment/xqdoc:param
                    return
                        <li>{  $param/node() }</li>
                }
                </ul>
            </div>
            
            {
                let $returnValue := $function/xqdoc:comment/xqdoc:return/node()
                return
                    if ($returnValue) then
                        <p><strong>Returns: </strong>{ $returnValue }</p>
                    else
                        ()
            }
        </div>
    </div>
};

declare function xqdoc:parse-text($elem as element()) {
    let $splits := tokenize($elem/string(), "\n")
    for $para in $splits
    where string-length($para) gt 0
    return
        <p class="description">{ $para }</p>
};