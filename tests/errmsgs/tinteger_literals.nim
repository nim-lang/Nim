discard """
  cmd: "nim check $file"
"""
# high(uint64) + 1
discard 18446744073709551616'u64 #[tt.Error
        ^ number out of range: '18446744073709551616'u64' ]#
# high(int64) + 1
discard 9223372036854775808'i64 #[tt.Error
        ^ number out of range: '9223372036854775808'i64' ]#
# high(int64) + 1
discard 9223372036854775808 #[tt.Error
        ^ number out of range: '9223372036854775808' ]#
discard 300'u8 #[tt.Error
        ^ number out of range: '300'u8' ]#
