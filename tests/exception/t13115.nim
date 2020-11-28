discard """
  exitcode: 1
  targets: "c js cpp"
  matrix: "-d:debug; -d:release"
  outputsub: ''' and works fine! [Exception]'''
  disabled: openbsd
"""
#[
disabled: openbsd: just for js
]#

# bug #13115

template fn =
  var msg = "This char is `" & '\0' & "` and works fine!"
  raise newException(Exception, msg)
# static: fn() # would also work
fn()
