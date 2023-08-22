import os

when isMainModule:
  echo("Testing `nimble run`: ", commandLineParams())
  when defined(sayWhee):
    echo "Whee!"