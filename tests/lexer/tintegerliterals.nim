# test the valid literals
assert 0b10 == 2
assert 0B10 == 2
assert 0x10 == 16
assert 0X10 == 16
assert 0o10 == 8
# the following is deprecated:
assert 0c10 == 8
assert 0C10 == 8
