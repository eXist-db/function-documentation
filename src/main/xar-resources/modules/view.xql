xquery version "3.1";


import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace lib="http://exist-db.org/xquery/html-templating/lib";

(: The following modules provide functions which will be called by the templating :)
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace app="http://exist-db.org/xquery/app" at "app.xql";


declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html";
declare option output:html-version "5.0";
declare option output:media-type "text/html";

declare function local:lookup ($func as xs:string, $arity as xs:integer) as function(*)? {
    function-lookup(xs:QName($func), $arity)
};

declare variable $local:templating-configuration := map {
    $templates:CONFIG_APP_ROOT : $config:app-root,
    $templates:CONFIG_USE_CLASS_SYNTAX : false(),
    $templates:CONFIG_FILTER_ATTRIBUTES : true(),
    $templates:CONFIG_STOP_ON_ERROR : true()
};

templates:apply(
    request:get-data(),
    local:lookup#2,
    (),
    $local:templating-configuration
)
