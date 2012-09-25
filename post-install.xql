xquery version "1.0";

import module namespace scan="http://exist-db.org/xquery/docs" at "modules/scan.xql";

declare variable $target external;

scan:load-fundocs($target)
