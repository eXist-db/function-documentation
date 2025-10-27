xquery version "3.1";

module namespace app="http://exist-db.org/xquery/app";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";


declare namespace xqdoc="http://www.xqdoc.org/1.0";

(: TODO: we should consider a setting to use a cache for instances that
  do not change often but are browsed frequently like exist-db.org  :)
declare variable $app:data := collection($config:app-data)/xqdoc:xqdoc;

declare %private function app:check-user-is-dba() as xs:boolean {
    let $user := sm:id()/sm:id/(sm:effective|sm:real)[1]/sm:username
    return sm:is-dba($user)
};

declare function app:check-dba-user($node as node(), $model as map(*)) {
    if (app:check-user-is-dba()) then $node else ()
};

declare function app:check-dba-user-and-not-data($node as node(), $model as map(*)) {
    if (not(app:check-user-is-dba()) or exists($app:data)) then () else (
        element { node-name($node) } {
            $node/@* except $node/@data-template, $node/node()
        }
    )
};

declare function app:check-dba-user-and-data($node as node(), $model as map(*)) {
    if (not(app:check-user-is-dba()) or empty($app:data)) then () else (
        element { node-name($node) } {
            $node/@* except $node/@data-template, $node/node()
        }
    )
};

declare function app:check-not-data($node as node(), $model as map(*)) {
    if (exists($app:data)) then () else $node
};

declare function app:check-not-dba-user-and-not-data($node as node(), $model as map(*)) {
    if (app:check-user-is-dba() or exists($app:data)) then () else $node
};

declare
    %templates:default("action", "search")
    %templates:default("where", "everywhere")
function app:action(
    $node as node(), $model as map(*),
    $action as xs:string,
    $module as xs:string?,
    $q as xs:string?, $where as xs:string
) as map(*) {
    switch ($action)
    case "browse" return app:browse($module)
    case "search" return
        switch ($where)
            case "description" return app:search-in-description($q)
            case "location" return app:search-in-module-location($q)
            case "signature" return app:search-in-signature($q)
            case "name" return app:search-in-module-name($q)
            case "everywhere" return app:search-everywhere($q)
            default return app:search-everywhere($q)
    default return map { "result": () }
};

declare %private
function app:browse($module as xs:string?) as map(*) {
    let $module := $app:data[xqdoc:module/xqdoc:uri = $module]
    return map { "result": $module//xqdoc:function }
};

declare %private
function app:search-in-module-location($q as xs:string?) as map(*) {
    map {
        "result": $app:data//(
            xqdoc:control[contains(xqdoc:location, $q)]/..//xqdoc:function
        )
    }
};

declare %private
function app:search-in-module-name($q as xs:string?) as map(*) {
    map {
        "result": $app:data//(
            xqdoc:module[contains(xqdoc:uri, $q)]/..//xqdoc:function
        )
    }
};

declare %private
function app:search-in-description($q as xs:string?) as map(*) {
    map {
        "result": $app:data//(
            xqdoc:function[ngram:contains(xqdoc:comment/xqdoc:description, $q)]
            |
            xqdoc:module[ngram:contains(xqdoc:comment/xqdoc:description, $q)]
        )
    }
};

declare %private
function app:search-in-signature($q as xs:string?) as map(*) {
    map {
        "result": $app:data//(
            xqdoc:function[ngram:contains(xqdoc:name, $q)]
            |
            xqdoc:function[ngram:contains(xqdoc:signature, $q)]
        )
    }
};

declare %private
function app:search-everywhere($q as xs:string?) as map(*) {
    map {
        "result": $app:data//(
            xqdoc:function[ngram:contains(xqdoc:name, $q)]
            |
            xqdoc:function[ngram:contains(xqdoc:signature, $q)]
            |
            xqdoc:function[ngram:contains(xqdoc:comment/xqdoc:description, $q)]
            |
            xqdoc:function[ngram:contains(xqdoc:comment/xqdoc:param, $q)]
            |
            xqdoc:function[ngram:contains(xqdoc:comment/xqdoc:return, $q)]
            |
            xqdoc:control[contains(xqdoc:location, $q)]/..//xqdoc:function
            |
            xqdoc:module[contains(xqdoc:uri, $q)]/..//xqdoc:function
            |
            xqdoc:module[ngram:contains(xqdoc:comment/xqdoc:description, $q)]
            |
            xqdoc:module[ngram:contains(xqdoc:name, $q)]/..//xqdoc:function
        )
    }
};

declare
    %templates:default("details", "false")
function app:module($node as node(), $model as map(*), $details as xs:boolean) {
    let $functions := $model("result")
    return
        for $module in $functions/ancestor::xqdoc:xqdoc
        let $uri := $module/xqdoc:module/xqdoc:uri/text()
        let $location := $module/xqdoc:control/xqdoc:location/text()
        let $order := (if ($location) then $location else " " || $uri)
        let $funcsInModule := $module//xqdoc:function intersect $functions

        order by $order
        return
            app:print-module($module, $funcsInModule, $details)
};

declare %private
function app:print-module(
    $module as element(xqdoc:xqdoc),
    $functions as element(xqdoc:function)*,
    $details as xs:boolean
) as element(div) {
    let $location := $module/xqdoc:control/xqdoc:location/text()
    let $uri := $module/xqdoc:module/xqdoc:uri/text()
    let $extDocs := app:get-extended-module-doc($module)[1]
    let $extended-view := $details and exists($extDocs)
    let $description := $module/xqdoc:module/xqdoc:comment/xqdoc:description/node()
    let $parsed :=
        if (contains($description, '&lt;') or contains($description, '&amp;')) then $description
        else parse-xml("<div>" || replace($description, "\n{2,}", "<br/>") || "</div>")/*/node()
    return
    <div class="module" data-xqdoc="{document-uri(root($module))}">
        <div class="module-head">
            <div class="module-head-inner row">
                <div class="col-md-1 hidden-xs">
                    <a href="view?uri={$uri}&amp;location={$location}&amp;details=true"
                        class="module-info-icon"><span class="glyphicon glyphicon-info-sign"/></a>
                </div>
                <div class="col-md-11 col-xs-12">
                    <h3><a href="view?uri={$uri}&amp;location={$location}&amp;details=true">{ $uri }</a></h3>
                    {
                        if (empty($location)) then (
                        ) else if (starts-with($location, '/db')) then (
                            <h4><a href="../eXide/index.html?open={$location}">{$location}</a></h4>
                        ) else (
                            <h4>{$location}</h4>
                        )
                    }
                    <p class="module-description">{ $parsed }</p>
                    {
                        let $metadata := $module/xqdoc:module/xqdoc:comment/(xqdoc:author|xqdoc:version|xqdoc:since)
                        return
                            if (empty($metadata)) then (
                            ) else (
                                <table>
                                {
                                    for $meta in $metadata
                                    return
                                        <tr>
                                            <td>{local-name($meta)}</td>
                                            <td>{$meta/string()}</td>
                                        </tr>
                                }
                                </table>
                            )
                    }
                </div>
            </div>
        </div>
        {
            if ($extended-view) then
                <div class="extended">
                    <h1>Overview</h1>
                    { app:include-markdown($extDocs) }
                </div>
            else
                ()
        }
        <div class="functions">
            {
                if ($extended-view) then
                    <h1>Functions</h1>
                else
                    ()
            }
            {
                for $function in $functions
                order by $function/xqdoc:name
                return
                    app:print-function($function, false())
            }
        </div>
    </div>
};

declare %private
function app:print-function(
    $function as element(xqdoc:function),
    $details as xs:boolean
) as element(div) {
    let $comment := $function/xqdoc:comment
    let $function-name := $function/xqdoc:name
    let $arity := xs:integer($function/xqdoc:arity)
    let $function-identifier :=
        (: If the name has no prefix, use the name as it is. :)
        if (contains($function-name, ':')) then (
            substring-after($function-name, ":") || "." || $arity
        ) else (
            $function-name || $arity
        )
    let $description := $comment/xqdoc:description/node()
    let $parsed :=
        if (contains($description, '&lt;') or contains($description, '&amp;')) then (
            $description
        ) else (
            let $constructed-xml := "<div>" || replace($description, "\n{2,}", "<br/>") || "</div>"
            return parse-xml($constructed-xml)/*/node()
        )
    let $extDocs := app:get-extended-doc($function)[1]
    return
        <div class="function" id="{$function-identifier}">
            { app:print-function-header($function)}
            <div class="function-detail">
                <p class="description">{ $parsed }</p>
                {
                    if (empty($extDocs) or $details) then (
                    ) else (
                        let $module := $function/ancestor::xqdoc:xqdoc
                        let $uri := $module/xqdoc:module/xqdoc:uri/text()
                        let $location := $module/xqdoc:control/xqdoc:location/text()
                        let $arity := count($function/xqdoc:comment/xqdoc:param)
                        let $query := "?" || "uri=" || $uri ||
                            "&amp;function=" || $function-name || "&amp;arity=" || $arity ||
                            (if ($location) then ("&amp;location=" || $location) else "#")
                        return
                            <a href="view{$query}" class="extended-docs btn btn-primary">
                                <span class="glyphicon glyphicon-info-sign"></span> Read more</a>
                    )
                }
                <dl class="parameters">
                {
                    if (empty($comment/xqdoc:param)) then (
                    ) else (
                        <dt>Parameters:</dt>,
                        <dd>{ app:print-parameters($comment/xqdoc:param) }</dd>
                    ),
                    if (empty($comment/xqdoc:return/node())) then (
                    ) else (
                        <dt>Returns:</dt>,
                        <dd>{ $comment/xqdoc:return/node() }</dd>
                    ),
                    if (empty($comment/xqdoc:deprecated)) then (
                    ) else (
                        <dt>Deprecated:</dt>,
                        <dd>{ $comment/xqdoc:deprecated/string() }</dd>
                    )
                }
                </dl>
                {
                    if (empty($extDocs) or not($details)) then (
                    ) else (
                        <div class="extended">
                            <h1>Detailed Description</h1>
                            { app:include-markdown($extDocs) }
                        </div>
                    )
                }
            </div>
        </div>
};

declare %private
function app:print-function-header($function as element(xqdoc:function)) as element(header) {
    <header class="function-head">
        <h4>{$function/xqdoc:name}#{$function/xqdoc:arity}</h4>
        <pre class="signature"><code class="language-xquery hljs" data-highlighted="yes">
            <span class="{app:html-class-for-function($function)}">{$function/xqdoc:name}</span>({
                let $ari := xs:integer($function/xqdoc:arity)
                return
                    for $para at $pos in $function//xqdoc:parameter
                    let $comma := if ($ari > 1 and $pos < $ari) then ", " else ()
                    return (
                        <span class="hljs-variable">{$para/xqdoc:name/string()}</span>,
                        " ",
                        <span class="hljs-keyword">as</span>,
                        " ",
                        <span class="hljs-type">{$para/xqdoc:type/string()}</span>,
                        $para/xqdoc:type/@occurrence/string() || $comma
                    )
            }) <span class="hljs-keyword">as</span>&#160;<span class="hljs-type">{$function/xqdoc:return/xqdoc:type/string()}</span>{$function/xqdoc:return/xqdoc:type/@occurrence/string()}
        </code></pre>
    </header>
};

declare %private
function app:html-class-for-function($function as element(xqdoc:function)) as xs:string {
    if (app:is-builtin-function($function)) then
        'hljs-built_in'
    else
        'hljs-title'
};

declare %private
function app:is-builtin-function($function as element(xqdoc:function)) as xs:boolean {
    not(contains($function/xqdoc:name, ':')) or
    starts-with($function/xqdoc:name, 'fn:') or
    starts-with($function/xqdoc:name, 'math:') or
    starts-with($function/xqdoc:name, 'map:') or
    starts-with($function/xqdoc:name, 'array:')
};

declare %private
function app:include-markdown ($path as xs:string) as element(zero-md) {
    <zero-md src="{ $path }">
        <template>
            <link rel="stylesheet" type="text/css" href="resources/css/fundocs.min.css" />
            <link rel="stylesheet" type="text/css" href="resources/css/atom-one-dark.min.css" />
        </template>
    </zero-md>
};

declare %private
function app:print-parameters($params as element(xqdoc:param)*) as element(table) {
    <table>
    {
        (: The data generated by xqdm:scan contains too much white space :)
        for $param in $params
        let $split := $param => normalize-space() => tokenize(" ")
        return
            <tr>
                <td class="parameter-name">{head($split)}</td>
                <td>{tail($split) => string-join(" ")}</td>
            </tr>
    }
    </table>
};

declare %private
function app:get-extended-doc($function as element(xqdoc:function)) as xs:string? {
    let $name := replace($function/xqdoc:name, "([^:]+:)?(.+)$", "$2")
    let $arity := count($function/xqdoc:comment/xqdoc:param)
    let $prefix := $function/ancestor::xqdoc:xqdoc/xqdoc:module/xqdoc:name
    let $prefix := if ($prefix/text()) then $prefix else "fn"
    let $paths := (
        (: Search for file with arity :)
        $config:ext-doc || "/" || $prefix || "/" || $name || "_" || $arity || ".md",
        (: General file without arity :)
        $config:ext-doc || "/" || $prefix || "/" || $name || ".md"
    )
    for $path in $paths
    return
        if (util:binary-doc-available($path)) then
            ('.' || substring-after($path, $config:app-root))
        else
            ()
};

declare %private
function app:get-extended-module-doc($module as element(xqdoc:xqdoc)) as xs:string? {
    let $prefix := $module/xqdoc:module/xqdoc:name
    let $prefix := if ($prefix/text()) then $prefix else "fn"
    let $paths := (
        (: Module description is either "_module.md" or prefix.md :)
        $config:ext-doc || "/" || $prefix || "/_module.md",
        $config:ext-doc || "/" || $prefix || "/" || $prefix || ".md"
    )
    for $path in $paths
    return
        if (util:binary-doc-available($path)) then
            $path
        else
            ()
};

declare
    %templates:default("w3c", "false")
    %templates:default("extensions", "false")
    %templates:default("appmodules", "false")
function app:showmodules(
    $node as node(), $model as map(*),
    $w3c as xs:boolean?, $extensions as xs:boolean?, $appmodules as xs:boolean?
) as element(tr)* {
    for $module in $app:data
    let $uri := $module/xqdoc:module/xqdoc:uri
    let $location := $module/xqdoc:control/xqdoc:location
    order by $uri
    return
        if (
            ($w3c and starts-with($uri, 'http://www.w3.org')) or
            ($appmodules and starts-with($location, '/db')) or
            ($extensions and app:is-extension($uri, $location))
        ) then (
            <tr>
                <td><a href="view?uri={$uri}&amp;location={$location}#">{$uri}</a></td>
                <td>{$location}</td>
            </tr>
        ) else ()
};

declare function app:is-extension($uri as xs:string, $location as xs:string?) as xs:boolean {
    (starts-with($uri, 'http://exist-db.org/') and (empty($location) or starts-with($location, 'java:'))) or
    (starts-with($uri, 'http://exist-db.org/xquery') and not(starts-with($location, '/db'))) or
    (starts-with($uri, 'http://expath.org/ns/')) or
    (starts-with($uri, 'http://exquery.org/ns/') and (empty($location) or starts-with($location, 'java:')))
};

declare
    %templates:default("uri", "http://www.w3.org/2005/xpath-functions")
    %templates:default("details", "false")
function app:view(
    $node as node(), $model as map(*),
    $uri as xs:string, $location as xs:string?, $function as xs:string?,
    $arity as xs:integer?, $details as xs:boolean
) {
    let $modules :=
        if ($location) then
            (: We need to re-read the collection here to avoid an NPE in exist-7.0.0-SNAPSHOT
              see https://github.com/eXist-db/exist/issues/5707 :)
            collection($config:app-data)/xqdoc:xqdoc
                [xqdoc:module/xqdoc:uri eq $uri]
                [xqdoc:control/xqdoc:location eq $location]
        else
            $app:data[xqdoc:module/xqdoc:uri eq $uri]

    return
        for $module in $modules
        return
            if (empty($function)) then (
                app:print-module($module, $module//xqdoc:function, $details cast as xs:boolean)
            ) else (
                let $functions :=
                    if (exists($arity)) then (
                        $module//xqdoc:function[xqdoc:name eq $function][count(xqdoc:comment/xqdoc:param) = $arity]
                    ) else (
                        $module//xqdoc:function[xqdoc:name eq $function]
                    )
                return for-each($functions, app:print-function(?, true()))
            )
};
