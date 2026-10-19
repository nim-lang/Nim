discard """
  output: "INFO logged through std/logging"
"""

# std/logging needs both what other modules reach through the HCR runtime:
# `log` is a method, and the log level and the handlers are threadvars read
# by the templates expanded here.

import std/logging

addHandler(newConsoleLogger(fmtStr = "$levelname "))
info("logged through std/logging")
