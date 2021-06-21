discard """
  action: run
  exitcode: 0
  targets: "c cpp"
  disabled: openbsd
"""

echo "foo1"
close stdout
doAssertRaises(IOError):
  echo "foo"
