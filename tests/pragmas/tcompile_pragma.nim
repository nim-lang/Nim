discard """
  output: '''34'''
  joinable: false
"""

{.compile("cfunction.c", "-DNUMBER_HERE=34").}

proc cfunction(): cint {.importc.}

echo cfunction()
