xquery version "3.0";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace app="http://exist-db.org/xquery/app" at "app.xql";

declare option exist:serialize "method=html5 media-type=text/html";

let $resolve := function($func as xs:string, $arity as xs:int) {
    try {
        function-lookup(xs:QName($func), $arity)
    } catch * {
        ()
    }
}
let $content := request:get-data()
return
    templates:apply($content, $resolve, (), map { $templates:CONFIG_STOP_ON_ERROR := false() })