discard """
  file: "forward_declarations.nim"
"""
# This example shows that idetools returns an empty signature for a forward
# declared proc in proc/symproc runs, but correctly returns the full signature
# in caas mode.

proc echoHello(text: string)

proc testForward() =
  echo "T"
  echoHello("T")

proc echoHello(text: string) =
  echo "Hello Mr." & text

when isMainModule:
  testForward()
