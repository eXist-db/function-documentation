xquery version "3.1";

import module namespace app="http://exist-db.org/xquery/app" at "app.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace lib="http://exist-db.org/xquery/html-templating/lib";

declare option exist:serialize "method=html5 media-type=text/html";

let $config := map {
    $templates:CONFIG_APP_ROOT : $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR : true()
}
let $resolve := function($func as xs:string, $arity as xs:integer) {
    try {
        function-lookup(xs:QName($func), $arity)
    } catch * {
        ()
    }
}
let $content := request:get-data()
return
    templates:apply($content, $resolve, (), $config)