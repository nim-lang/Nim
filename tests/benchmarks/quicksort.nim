import os
import strutils

# Generate some pseudo-random data
var seed: tuple[s1, s2, s3: int32] = (2'i32, 8'i32, 16'i32)

proc random(): int32 =
    seed = (((((((seed[0] and 0x0007_FFFF'i32) shl 13'i32) xor seed[0]) shr
               19'i32) and 0x0000_1FFF'i32) xor
             ((seed[0] and 0x000F_FFFE'i32) shl 12'i32)),

            ((((((seed[1] and 0x3FFF_FFFF'i32) shl  2'i32) xor seed[1]) shr
               25'i32) and 0x0000_007F'i32) xor
             ((seed[1] and 0x0FFF_FFF8'i32) shl  4'i32)),

            ((((((seed[2] and 0x1FFF_FFFF'i32) shl  3'i32) xor seed[2]) shr
               11'i32) and 0x001F_FFFF'i32) xor
             ((seed[2] and 0x0000_7FF0'i32) shl 17'i32)))
    return seed[0] xor seed[1] xor seed[2]

var n = 9999999

var data: seq[int32]
newSeq(data, n)
for i in 0 .. data.high():
    data[i] = random()


proc `$`(d: seq[int32]): string =
    result = "[ "
    for i in items(d):
        result.addSep(", ", 2)
        result.add($(i and 0xFFFF_FFFF'i64))
    result.add(" ]")

# Sort the data
proc sort(start, stop: int) =
    if stop <= start+1:
        return

    var j = start
    for i in start..stop-2:
        if data[i] <% data[stop-1]:
            swap(data[i], data[j])
            inc(j)
    swap(data[j], data[stop-1])

    sort(start, j)
    sort(j+1, stop)

sort(0, data.len)
echo(data[n div 2 - 1] and 0xFFFF_FFFF'i64, ", ",
     data[n div 2] and 0xFFFF_FFFF'i64, ", ",
     data[n div 2 + 1] and 0xFFFF_FFFF'i64)
