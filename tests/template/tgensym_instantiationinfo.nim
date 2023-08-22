discard """
  action: "compile"
"""

# bug #7937

template printError(error: typed) =
  # Error: inconsistent typing for reintroduced symbol 'instInfo': previous type was: tuple[filename: string, line: int, column: int]; new type is: (string, int, int)
  let instInfo {.gensym.} = instantiationInfo()
  echo "Error at ", instInfo.filename, ':', instInfo.line, ": ", error

# Removing this overload fixes the error
template someTemplate(someBool: bool, body) =
  discard

template someTemplate(body) =
  body

proc main() =
  someTemplate:
    printError("ERROR 1")
    printError("ERROR 2")

main()
