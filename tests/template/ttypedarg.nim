block: # issue #18667
  template fn(b: seq[string]) =
    let d = $(b, )
  fn(@[])

block: # issue #18667
  template fn(b: seq[string]) =
    let d = $b
  fn(@[])
