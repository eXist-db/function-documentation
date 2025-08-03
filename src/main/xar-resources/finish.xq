import module namespace generate = "http://exist-db.org/apps/fundocs/generate" at "modules/generate.xqm";

generate:fundocs(),
util:log("info", "Finished generating function documentation for fundocs")