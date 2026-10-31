# Helper for tinlineiternestedclosure.nim: an exported inline iterator whose
# body creates a nested closure capturing a local. The iterator itself has no
# runtime body; it is expanded into each importer's `for` loop.

iterator it*(): int =
  var x = 1
  let f = proc(): int = x
  yield f()
