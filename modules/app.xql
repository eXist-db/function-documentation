xquery version "3.0";

module namespace app="http://exist-db.org/xquery/app";

declare namespace xqdoc="http://www.xqdoc.org/1.0";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare function app:modules-select($node as node(), $params as element(parameters)?, $model as item()*) {
    <select name="module">
        <option value="All">All</option>
        {
            let $module := request:get-parameter("module", ())
            for $mod in collection("/db")//xqdoc:module
            let $uri := $mod/xqdoc:uri/text()
            order by $uri
            return
                <option value="{$uri}">
                { if ($uri eq $module) then attribute selected { "true" } else () }
                { $uri }
                </option>
        }
    </select>
};

declare function app:action($node as node(), $params as element(parameters)?, $model as item()*) {
    let $action := request:get-parameter("action", "Search")
    return
        switch ($action)
            case "Browse" return
                <div class="result">{app:browse($node)}</div>
            case "Search" return
                <div class="result">{app:search($node)}</div>
            default return
                <div class="result">ABC</div>
};

declare function app:browse($node as node()) {
    let $module := request:get-parameter("module", ())
    let $functions :=
        if( $module eq "All" ) then
            collection($config:app-data)/xqdoc:xqdoc//xqdoc:function
        else
            collection($config:app-data)/xqdoc:xqdoc[xqdoc:module/xqdoc:uri = $module]//xqdoc:function
    return
        templates:process($node/node(), $functions)
};

declare function app:search($node as node()) {
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
        
    let $filteredFuncs := 
        if( $module eq "All" ) then $functions
        else $functions[ancestor::xqdoc:xqdoc/xqdoc:module/xqdoc:uri = $module]
    
    return
        templates:process($node/node(), $filteredFuncs)
};

declare function app:module($node as node(), $params as element(parameters)?, $functions as item()*) {
    for $module in $functions/ancestor::xqdoc:xqdoc
    let $funcsInModule := $module//xqdoc:function intersect $functions
    return
        app:print-module($module, $funcsInModule)
};

declare function app:print-module($module as element(xqdoc:xqdoc), $functions as element(xqdoc:function)) {
    <div class="module">
        <div class="module-head">
            <h3>{ $module/xqdoc:module/xqdoc:uri/text() }</h3>
            <p class="module-description">{ $module/xqdoc:module/xqdoc:comment/xqdoc:description/node() }</p>
        </div>
        <div class="functions">
            {
                for $function in $functions
                return
                    app:print-function($function)
            }
        </div>
    </div>
};

declare function app:print-function($function as element(xqdoc:function)) {
    <div class="function">
        <div class="function-head">
            <h4>{ $function/xqdoc:name/node() }</h4>
            <p class="signature">{ $function/xqdoc:signature/node() }</p>
        </div>
        <div class="function-detail">
            <p class="description">{ $function/xqdoc:comment/xqdoc:description/node() }</p>
            
            <div class="parameters">
                <p>Parameters:</p>
                <ul>
                {
                    for $param in $function/xqdoc:comment/xqdoc:param
                    return
                        <li>{ $param/node() }</li>
                }
                </ul>
            </div>
            
            {
                let $returnValue := $function/xqdoc:comment/xqdoc:return/node()
                return
                
                <p><strong>Returns: </strong>{ if( $returnValue ) then $returnValue else "empty()" }</p>
            }
        </div>
    </div>
};