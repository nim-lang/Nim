discard """
  output: '''ok'''
"""

# Classic codegen never visits this private routine because it is unused. IC's
# per-module backend must preserve that laziness instead of rejecting its body
# while preparing every routine in the module for lowering.
proc unusedResultCapture(): int =
  result = 0
  proc increment() =
    inc result
  increment()

echo "ok"
