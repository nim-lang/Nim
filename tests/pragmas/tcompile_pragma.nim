discard """
  output: '''34'''
"""

{.compile("cfunction.c", "-DNUMBER_HERE=34").}

proc cfunction(): cint {.importc.}

echo cfunction()
