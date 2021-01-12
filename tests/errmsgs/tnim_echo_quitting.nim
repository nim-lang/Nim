discard """
  cmd: "nim check -d:nimEchoQuitting $file"
  action: "reject"
  nimout: "nim quitting"
"""
static: echo "ok1"
static: echo "ok2"
nonexistant
