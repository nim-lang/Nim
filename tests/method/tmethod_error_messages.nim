discard """
  errormsg: "'method' needs a parameter that has an object type; methods use dynamic dispatch and must have at least one parameter of an object type to dispatch on. If you want static dispatch, use 'proc' instead of 'method'."
  file: "tmethod_error_messages.nim"
  line: 7
"""

method doSomething(x: int): int =
  return x * 2
