import a, b
discard A(1f, 1f) # works
proc x(b = A(1f, 1f)) = discard # doesn't work