xquery version "3.0";

module namespace app="http://exist-db.org/xquery/app";

declare namespace xqdoc="http://www.xqdoc.org/1.0";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare function app:modules-select($node as node(), $model as map(*), $module as xs:string?) {
    <select name="module">
        <option value="AllFunctions">All Functions</option>
        <option value="AllCoreFunctions">All Core Functions</option>
        <option value="AllAppFunctions">All App Functions</option>
        <option value="All">---</option>
        {
            let $functions := collection($config:app-data)//xqdoc:xqdoc
            for $function in $functions[xqdoc:module[xqdoc:uri/text()]]
            let $uri := $function/xqdoc:module/xqdoc:uri/text()
            let $location := $function/xqdoc:control/xqdoc:location/text()
            let $option := concat($uri, if ($location) then ' @ ' else '', $location)
            let $order := (if ($location) then $location else " " || $uri)
            order by $uri, $order
            
            return
                <option value="{$option}">
                { if ($option eq $module) then attribute selected { "true" } else () }
                { $option }
                </option>
        }
    </select>
};

declare 
    %templates:default("action", "search")
    %templates:default("type", "name")
function app:action($node as node(), $model as map(*), $action as xs:string, $module as xs:string?, 
    $q as xs:string?, $type as xs:string) {
    switch ($action)
        case "browse" return
            app:browse($node, $module)
        case "search" return
            app:search($node, (), $q, $type)
        default return
            ()
};

declare %private function app:browse($node as node(), $module as xs:string?) {
    let $location := if (contains($module, '@')) then substring-after($module, ' @ ') else ''
    let $module := if (contains($module, '@')) then substring-before($module, ' @ ') else $module
    
    let $functions := switch ($module)
        case "AllFunctions" 
        case "All" 
            return collection($config:app-data)/xqdoc:xqdoc//xqdoc:function
        case "AllCoreFunctions" 
            return collection($config:app-data)/xqdoc:xqdoc[starts-with(xqdoc:control/xqdoc:location, "java:")]//xqdoc:function
        case "AllAppFunctions"
            return collection($config:app-data)/xqdoc:xqdoc[xqdoc:control/xqdoc:location/text()]//xqdoc:function
        default
            return
                if ($location)
                then 
                    collection($config:app-data)/xqdoc:xqdoc[xqdoc:module/xqdoc:uri = $module][xqdoc:control/xqdoc:location = $location]//xqdoc:function
                else 
                    collection($config:app-data)/xqdoc:xqdoc[xqdoc:module/xqdoc:uri = $module]//xqdoc:function
    return
        map { "result" := $functions }
};

declare %private function app:search($node as node(), $module as xs:string?, 
    $q as xs:string?, $type as xs:string) {
    let $functions :=
        switch( $type )
            case "name" return
            collection($config:app-data)/xqdoc:xqdoc//xqdoc:function[ngram:contains(xqdoc:signature, $q)]
        case "desc" return
            collection($config:app-data)/xqdoc:xqdoc//xqdoc:function[ngram:contains(xqdoc:comment/xqdoc:description, $q)]
        default return ()
        order by $module/xqdoc:xqdoc/xqdoc:control/xqdoc:location/text(), $module/xqdoc:xqdoc/xqdoc:module/xqdoc:name/text()
    return
        map { "result" := $functions }
};

declare function app:module($node as node(), $model as map(*)) {
    let $functions := $model("result")
    for $module in $functions/ancestor::xqdoc:xqdoc
    
    let $uri := $module/xqdoc:module/xqdoc:uri/text()
    let $location := $module/xqdoc:control/xqdoc:location/text()
    let $order := (if ($location) then $location else " " || $uri)
    let $funcsInModule := $module//xqdoc:function intersect $functions
    
    order by $order
    return
        app:print-module($module, $funcsInModule)
};

declare %private function app:print-module($module as element(xqdoc:xqdoc), $functions as element(xqdoc:function)*) {
    <div class="module">
        <div class="module-head">
            <div class="module-head-inner">
                <h3>{ $module/xqdoc:module/xqdoc:uri/text() }</h3>
                {
                    let $location := $module/xqdoc:control/xqdoc:location/text()
                    return
                        if ($location) then
                            <h4><a href="../eXide/index.html?open={$location}">{$location}</a></h4>
                        else
                            ()
                }
                <p class="module-description">{ $module/xqdoc:module/xqdoc:comment/xqdoc:description/node() }</p>
                {
                    let $metadata := $module/xqdoc:module/xqdoc:comment/(xqdoc:author|xqdoc:version|xqdoc:since)
                    return
                        if (exists($metadata)) then
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
                        else
                            ()
                }
            </div>
        </div>
        <div class="functions">
            {
                for $function in $functions
                order by $function/xqdoc:name
                return
                    app:print-function($function)
            }
        </div>
    </div>
};

declare %private function app:print-function($function as element(xqdoc:function)) {
    let $comment := $function/xqdoc:comment
    return
        <div class="function">
            <div class="function-head">
                <h4>{ $function/xqdoc:name/node() }</h4>
                <div class="signature" data-language="xquery">{ $function/xqdoc:signature/node() }</div>
            </div>
            <div class="function-detail">
                <p class="description">{ $comment/xqdoc:description/node() }</p>
                
                <dl class="parameters">
                    <dt>Parameters:</dt>
                    <dd>
                    {
                        app:print-parameters($comment/xqdoc:param)
                    }
                    </dd>
                    <dt>Returns:</dt>
                    <dd>
                    {
                        let $returnValue := $comment/xqdoc:return/node()
                        return
                            <p>{ if( $returnValue ) then $returnValue else "empty()" }</p>
                    }
                    </dd>
                </dl>
            </div>
        </div>
};

declare %private function app:print-parameters($params as element(xqdoc:param)*) {
    <table>
    {
        $params !
            <tr>
                <td class="parameter-name">{replace(., "^([^\s]+)\s.*$", "$1")}</td>
                <td>{replace(., "^[^\s]+\s(.*)$", "$1")}</td>
            </tr>
    }
    </table>
};

(: ~
 : If eXide is installed, we can load ace locally. If not, download ace
 : from cloudfront.
 :)
declare function app:import-ace($node as node(), $model as map(*)) {
    let $eXideInstalled := doc-available("/db/eXide/repo.xml")
    let $path :=
        if ($eXideInstalled) then
            "../eXide/resources/scripts/ace/"
        else
            "//d1n0x3qji82z53.cloudfront.net/src-min-noconflict/"
    for $script in $node/script
    return
        <script>
        {
            $script/@* except $script/@src,
            attribute src { $path || $script/@src }
        }
        </script>
};