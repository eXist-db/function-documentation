xquery version "3.1";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";

declare namespace json="http://www.json.org";

declare variable $exist:prefix external;
declare variable $exist:controller external;
declare variable $exist:path external;
declare variable $exist:resource external;

declare variable $local:method := lower-case(request:get-method());
declare variable $local:is-get := $local:method eq 'get';
declare variable $local:user := login:set-user("org.exist.login", (), false());

declare variable $local:type-to-where :=
    map {
        "name": "everywhere",
        "signature": "signature",
        "desc": "description"
    };

declare function local:map-type-to-where ($type as xs:string?) as xs:string {
    head((
        $local:type-to-where?($type),
            'everywhere'
    ))
};

declare function local:render-view($view as xs:string) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="templates/pages/{$view}.html"/>
        <view>
            <forward url="{$exist:controller}/modules/view.xq">
                <set-attribute name="$exist:prefix" value="{$exist:prefix}"/>
                <set-attribute name="$exist:controller" value="{$exist:controller}"/>
            </forward>
        </view>
    </dispatch>
};

declare function local:render-parameters ($parameters as map(*)) {
    map:for-each($parameters, function ($k, $v) {
        if (empty($v)) then () else (
            $k || '=' || escape-uri($v, true())
        )
    })
    => string-join('&amp;')
};

(: redirects :)
if ($local:is-get and $exist:path eq '') then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat(request:get-uri(), '/')}"/>
    </dispatch>
) else if ($local:is-get and $exist:path eq '/index.html') then (
    let $url := substring-before(request:get-uri(), 'index.html')

    let $parameters := map{
        'q': request:get-parameter('q', ()),
        'action': 'search',
        'where': local:map-type-to-where(request:get-parameter('type', ()))
    }

    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="{$url}?{local:render-parameters($parameters)}" />
        </dispatch>
) else if ($local:is-get and $exist:path eq '/view.html') then (
    let $url := substring-before(request:get-uri(), '.html')
    let $parameters := map{
        'location': request:get-parameter('location', ()),
        'uri': request:get-parameter('uri', ()),
        'function': request:get-parameter('function', ())
    }

    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="{$url}?{local:render-parameters($parameters)}" />
        </dispatch>

) else if ($local:is-get and $exist:path eq '/browse.html') then (
    let $url := substring-before(request:get-uri(), '.html')
    let $parameters := map{
        'w3c': request:get-parameter('w3c', ()),
        'extensions': request:get-parameter('extensions', ()),
        'appmodules': request:get-parameter('appmodules', ())
    }

    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="{$url}?{local:render-parameters($parameters)}" />
        </dispatch>
) else if ($local:is-get and $exist:path eq "/") then (
    local:render-view('index')
) else if ($local:is-get and $exist:path eq "/view") then (
    local:render-view('view')
) else if ($local:is-get and $exist:path eq "/browse") then (
    local:render-view('browse')
) else if ($local:method eq 'post' and $exist:path eq "/query") then (
    local:render-view('query')
) else if ($local:is-get and $exist:path eq "/login") then (
    try {
        util:declare-option("exist:serialize", "method=json"),
        <status>
            <user>{request:get-attribute("org.exist.login.user")}</user>
            <isAdmin json:literal="true">{ sm:is-dba(request:get-attribute("org.exist.login.user")) }</isAdmin>
        </status>
    } catch * {
        response:set-status-code(401),
        <status>{$err:description}</status>
    }
) else if ($local:is-get and matches($exist:path, ".+\.md$")) then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}{$exist:path}">
            <set-header name="Cache-Control" value="max-age=73600; must-revalidate;"/>
        </forward>
    </dispatch>
) else if ($local:is-get and matches($exist:path, "/resources/(css|fonts|images|scripts|svg|css)/.+")) then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}{$exist:path}">
            <set-header name="Cache-Control" value="max-age=73600; must-revalidate;"/>
        </forward>
    </dispatch>
) else if ($local:is-get and $exist:path = "/regenerate") then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/regenerate.xq" />
    </dispatch>
) else (
    response:set-status-code(404),
    <data>Not Found</data>
)
