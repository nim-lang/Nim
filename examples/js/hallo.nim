import esmodule, jsffi

# Hello world program

esImport("x", "./x")

var
  x*{.importjs.}: cint

echo "Hello World" & $x
