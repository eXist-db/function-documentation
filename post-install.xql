xquery version "1.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace xqdm="http://exist-db.org/xquery/xqdoc";

declare namespace docs="http://exist-db.org/xquery/docs";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

declare variable $target external;
 
declare function docs:create-collection($parent as xs:string, $child as xs:string) as empty() {
    let $null := xdb:create-collection($parent, $child)
    return ()
};

declare function docs:load-external($uri as xs:string) {
    let $dataColl := concat($target, "/data")
    let $xml := xqdm:scan(xs:anyURI($uri))
    let $moduleURI := $xml//xqdoc:module/xqdoc:uri
    let $docName := concat(util:hash($moduleURI, "MD5"), ".xml")
    let $null := (
		xdb:store($dataColl, $docName, $xml),
		xdb:chmod-resource($dataColl, $docName, 508)
	)
	return
	   <li>Extracted docs from external module {$moduleURI}</li>
};

declare function docs:load-external-modules() {
    for $uri in util:mapped-modules()
    return
        docs:load-external($uri)
};

declare function docs:load-internal-modules() {
    let $dataColl := concat($target, "/data")
    for $moduleURI in util:registered-modules()
	let $moduleDocs := util:extract-docs($moduleURI)
	let $docName := concat(util:hash($moduleURI, "MD5"), ".xml")
	return 
	   if ($moduleDocs) then 
            let $null := (
    		  xdb:store($dataColl, $docName, $moduleDocs),
    		  xdb:chmod-resource($dataColl, $docName, 508)
            )
            return
                <li>Extracted docs from builtin module {$moduleURI}</li>
	   else
	      <li>No content for module {$moduleURI}</li>
};

declare function docs:load-fundocs() {
	xdb:create-collection($target, "data"),
	docs:load-internal-modules(),
	docs:load-external-modules()
};

docs:load-fundocs()
