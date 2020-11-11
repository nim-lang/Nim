discard """
  targets: "c cpp js"
  ccodecheck: "'HELLO'"
  action: compile
"""

when defined(js):
  var foo = proc(): void{.codegenDecl: "/*HELLO*/function $2($3)".} =
    echo "baa"
else:
  var foo = proc(): void{.codegenDecl: "/*HELLO*/$1 $2 $3".} =
    echo "baa"

foo()
