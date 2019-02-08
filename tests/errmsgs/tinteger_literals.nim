discard """
cmd: "nim check $file"
errormsg: "number out of range: '300'u8'"
nimout: '''
tinteger_literals.nim(12, 9) Error: number out of range: '18446744073709551616'u64'
tinteger_literals.nim(13, 9) Error: number out of range: '9223372036854775808'i64'
tinteger_literals.nim(14, 9) Error: number out of range: '9223372036854775808'
tinteger_literals.nim(15, 9) Error: number out of range: '300'u8'
'''
"""

discard 18446744073709551616'u64 # high(uint64) + 1
discard 9223372036854775808'i64  # high(int64) + 1
discard 9223372036854775808      # high(int64) + 1
discard 300'u8