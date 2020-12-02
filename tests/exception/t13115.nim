discard """
  exitcode: 1
  targets: "c"
  matrix: "-d:debug; -d:release"
  outputsub: ''' and works fine! [Exception]'''
"""

# bug #13115
# xxx bug: doesn't yet work for cpp

var msg = "This char is `" & '\0' & "` and works fine!"
raise newException(Exception, msg)
