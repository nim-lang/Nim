discard """
  output: "5"
  cmd: r"nim c --hints:on $options -d:release $file"
  ccodecheck: "'/*PROGMEM*/ myLetVariable = {'"
  targets: "c"
"""

var myLetVariable {.exportc, codegenDecl: "$# /*PROGMEM*/ $#".} = [1, 2, 3]

myLetVariable[0] = 5
echo myLetVariable[0]
