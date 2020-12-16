discard """
  action: run
  exitcode: 0
  targets: "c cpp"
"""

echo "foo1"
close stdout
doAssertRaises(IOError):
  echo "foo"
