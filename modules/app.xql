xquery version "3.0";

(:~
 :  Templating functions for the XQuery function documentation search app.
 :)
module namespace app="http://exist-db.org/xquery/app";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace xqdoc="http://www.xqdoc.org/1.0" at "xqdoc.xql";

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
                <div class="result">{xqdoc:browse($node)}</div>
            case "Search" return
                <div class="result">{xqdoc:search($node)}</div>
            default return
                <div class="result">Unknown Action: {$action}</div>
};

declare function app:module($node as node(), $params as element(parameters)?, $functions as item()*) {
    for $module in $functions/ancestor::xqdoc:xqdoc
    let $funcsInModule := $module//xqdoc:function intersect $functions
    order by xqdoc:module-order($module)
    return
        xqdoc:print-module($module, $funcsInModule)
};