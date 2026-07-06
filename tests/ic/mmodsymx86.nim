# Live on every real host: provides `foo` so the template's taken branch resolves.
when not defined(mmodSymFakeArch):
  func foo*(a, b: uint64): uint64 = a + b
