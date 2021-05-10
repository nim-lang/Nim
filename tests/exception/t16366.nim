discard """
  action: run
  exitcode: 0
  targets: "c cpp"
  disabled: openbsd
  joinable: false
"""

echo "foo1"
close stdout
doAssertRaises(IOError):
  echo "foo"
