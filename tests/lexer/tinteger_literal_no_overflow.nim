# Test that valid-sized literals don't trigger warnings

# Exactly 16 hex digits - should be fine
discard 0xFFFFFFFFFFFFFFFF

# Exactly 64 binary digits - should be fine
discard 0b1111111111111111111111111111111111111111111111111111111111111111

# Exactly 22 octal digits - should be fine
discard 0o1777777777777777777777

# 15 hex digits - should be fine
discard 0xFFFFFFFFFFFFFFF

# Test that explicitly typed literals with overflow don't trigger the warning
# (these should use the existing bounds checking for typed literals)
discard 0xFF'i8  # This is allowed per the manual, equals -1
discard 0x80'i8  # This is allowed per the manual, equals -128

echo "All tests passed"
