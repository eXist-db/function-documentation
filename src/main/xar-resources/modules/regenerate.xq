xquery version "3.1";

import module namespace sm="http://exist-db.org/xquery/securitymanager";
import module namespace generate="http://exist-db.org/apps/fundocs/generate" at "generate.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

try {
    let $user := sm:id()/sm:id/(sm:effective|sm:real)[1]/sm:username
    return if (sm:is-dba($user)) then (
        let $result := generate:fundocs()
        return
            <response status="ok">
                <message>Scan completed! {$result}</message>
            </response>
    ) else (
        response:set-status-code(403),
        <response status="failed">
            <message>You have to be a member of the dba group. Please log in using the dashboard and retry.</message>
        </response>
    )
} catch * {
    response:set-status-code(500),
    <response status="failed">
        <message>{$err:description}</message>
    </response>
}
