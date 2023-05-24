import compiler/[idents,options]
import src/nimsuggest

when isMainModule:
  handleCmdLine(newIdentCache(), newConfigRef())
else:
  import src/testInterface
  export src/testInterface