discard """
  output: "ok1"
"""

# bug #9884: an exportc type that is only used by `emit` is generated
type Data {.exportc: "DataAux".} = object
  flag: cint

proc foo*(data: ptr Data): void {.noconv, importc: "timn_$1".}

{.emit: """
void timn_foo(DataAux* data){}
""".}

echo "ok1"
