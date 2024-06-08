template detect(v: untyped) =
  doAssert typeof(v) is int

detect:
  try:
    raise (ref ValueError)()
  except ValueError:
    42