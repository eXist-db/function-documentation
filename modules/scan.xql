xquery version "3.0";

module namespace docs="http://exist-db.org/xquery/docs";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace xqdm="http://exist-db.org/xquery/xqdoc";

declare namespace xqdoc="http://www.xqdoc.org/1.0";
 
declare %private function docs:create-collection($parent as xs:string, $child as xs:string) as empty() {
    let $null := xdb:create-collection($parent, $child)
    return ()
};

declare %private function docs:load-external($uri as xs:string, $store as function(xs:string, element()) as empty()) {
    let $xml := xqdm:scan(xs:anyURI($uri))
    let $moduleURI := $xml//xqdoc:module/xqdoc:uri
    return
        $store($moduleURI, $xml)
};

declare %private function docs:load-external-modules($store as function(xs:string, element()) as empty()) {
    for $uri in util:mapped-modules()
    return
        docs:load-external($uri, $store)
};

declare %private function docs:load-internal-modules($store as function(xs:string, element()) as empty()) {
    for $moduleURI in util:registered-modules()
	let $moduleDocs := util:extract-docs($moduleURI)
	return 
	   if ($moduleDocs) then
           $store($moduleURI, $moduleDocs)
	   else
	      <li>No content for module {$moduleURI}</li>
};

declare function docs:load-fundocs($target as xs:string) {
    let $dataColl := xdb:create-collection($target, "data")
    let $store := function($moduleURI as xs:string, $data as element()) {
        let $name := util:hash($moduleURI, "md5") || ".xml"
        return
        (
            xdb:store($dataColl, $name, $data),
            sm:chmod(xs:anyURI($dataColl || "/" || $name), "rw-rw-r--")
        )[2]
    }
    return (
    	docs:load-internal-modules($store),
    	docs:load-external-modules($store)
    )
};
