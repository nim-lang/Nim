discard """
  targets: "c cpp"
  matrix: "--mm:refc; --mm:arc"
"""

type Future = ref object

iterator paths: string = 
  # without "when nimvm" everything works
  when nimvm:
    yield "test.md"
  else:
    yield "test.md"

template await(f: Future): string =
  # need this yield, also the template has to return something
  yield f
  "hello world"

proc generatePostContextsAsync() =
  iterator generatePostContextsAsyncIter(): Future {.closure.} =
    for filePath in paths():
      var temp = await Future()

  # need this line
  var nameIterVar = generatePostContextsAsyncIter

generatePostContextsAsync()