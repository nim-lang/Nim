template deferScoped*(cleanup, body) =
  ## Similar to builtin `defer` statement, but operates on a scope `body`,
  ## whereas `defer` operates until end of block it's defined in.
  ## Implemented as: `try: body ... finally: cleanup`
  runnableExamples:
    from std/strutils import contains
    let a = open(currentSourcePath)
    deferScoped: close(a) # immediately follows code that needs cleanup
    do:
      doAssert "deferScoped" in readAll(a)
  try: body
  finally: cleanup
