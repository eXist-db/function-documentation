The implementation of `fn:xml-to-json()` handles most valid input according to the ([specification](https://www.w3.org/TR/xpath-functions-31/#func-xml-to-json")). Notable exceptions follow.

All output is generated by the `jackson` library and should be proper JSON. All (un-) escaping is delegated to `com.fasterxml.jackson`. 
and should be proper JSON.

`fn:xml-to-json()` does not replace codepoints in the range `1-31` or `127-159` in any string or map key.

`fn:xml-to-json()` unescapes and reescapes any string and map key marked as being escaped.
It does not do additional special character replacements mentioned in the spec.
It does not do an otherwise verbatim copy.

# Examples

## 1)

```xquery
let $node := <string>&#127;</string>
return fn:xml-to-json($node)
```
does return `""` and not `"\u007F"`.

## 2)

```xquery
let $node := <string escaped="true">\/</string>
return fn:xml-to-json($node)
```
does return `"/"` and not `"\/"`.

## 3)

```xquery
let $node := <string escaped="true">&#127;</string>
return fn:xml-to-json($node)
```
does return `""` and not `"\u007F"`.

## 4)
```xquery
let $node := <string escaped="true">""</string>
return fn:xml-to-json($node)
```
does return `""` and not `"\"\""`.
