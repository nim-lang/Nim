discard """
  action: run
  exitcode: 1
  targets: "c cpp"
"""

echo "foo1"
close stdout
doAssertRaises(IOError):
  echo "foo"
