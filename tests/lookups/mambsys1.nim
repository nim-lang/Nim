import mambsys2 # import TExport

type
  TExport* = enum x, y, z

proc foo*(x: int) =
  discard
