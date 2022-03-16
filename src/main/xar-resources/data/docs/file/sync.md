`file:sync#3` will write the contents of the target collection to the target directory on the file system. 
This will include the entire tree (subcollections and their contents).

Since eXist-DB 5.4.0 the third parameter can now be of type xs:dateTime (kept for backwards compatibility)
or a map of options.

## Options Map

Serialization options (only applies to XML files at the moment) lets you
override some defaults that are set in `file:serialize` for backwards
compatibility.

- `indent`: xs:boolean default `true()`
  Wether to remove line-endings and extra whitespace from XML-files with
  the exception of those in mixed content nodes.
- `omit-xml-declaration`: xs:boolean default `true()`
  Set this to `false()` if you wish to have the XML declaration at the
  beginning of each XML file.
- `exist:expand-x-includes`: xs:boolean default `false()`
  Setting this to `true()` will expand X-includes in files where
  they are present.

There are additional serialization options that apply to XML-files and can now be set in the options map. Most notably:

- `exist:insert-final-newline`: xs:boolean default `false()`
  With this option set to `true()` a newline character will be added 
  to the very end of the document. Useful when syncing data to a git
  repository.

A list of all serialization options can be found in [the exist-db documentation on XQuery serialization](http://exist-db.org/exist/apps/doc/xquery.xml?field=all&id=D3.3.6.2#serialization)

In addition to all serialization settings, the map lets you specify
three additional options:

- `after`: xs:dateTime? default `()`
    - synchronise only files newer than the dateTime provided
    - this behaves exactly as providing the xs:dateTime before
    - not setting this option will synchronize all files and collections
- `prune`: xs:boolean default `()`
    - flag to control if surplus files on the filesystem should be removed
- `exclude`: xs:string* default `()`
    - a sequence of glob patterns 
    - patterns support globs like `*`, `?` and `**` placeholders
    - files that match any of the patterns will __not__ be removed from disk

Whenever file:sync selects a file or folder for deletion it will report this in the returned file:sync element.

__NOTE:__ This function returns a `document-node()`.

## Examples Using Options Map

### Sync to a git repository

Say, you want to synchronize the state of a collection to the a working directory of a git-repository.
While it is useful to also remove files that are not in the database collection of you application you 
still will want to preserve `.git`, `.gitignore` and maybe other dotfiles like `.env`. The following
example shows how to do that.

```xquery
file:sync("/db/apps/my-app", "/Users/me/projects/my-app", map {
  "prune": true(), (: remove anything not in the database :)
  "excludes": (".*") (: do not remove dotfiles, this will leave .git folder and .gitignore untouched  :)
})
```

Before v5.4.0 the above required multiple calls to `process:execute#2` and some command line trickery.

### Example report with deletions

```xml
<file:sync xmlns:file="http://exist-db.org/xquery/file" collection="/db/apps/my-app" dir="/Users/me/projects/my-app">
    <file:delete file="/Users/me/projects/my-app/extra.file" name="extra.file"/>
</file:sync>
```

## Synchronize changes made in the last day

### Example Using Options Map

```xquery
file:sync("/db/apps/my-app", "/Users/me/projects/my-app", map {
  "after": current-dateTime() - xs:dayTimeDuration("PT1D"), (: changes in the last day :)
})
```

### Example Using Deprecated xs:dateTime

```xquery
file:sync("/db/apps/my-app", "/Users/me/projects/my-app", 
  current-dateTime() - xs:dayTimeDuration("PT1D") (: changes in the last day :)
)
```
