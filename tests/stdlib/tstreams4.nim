import streams

let
  input = @[15.byte, 16, 27, 100, 42, 67]
  output = @[15.byte, 16, 27, 100, 42, 67,
    'h'.byte, 'e'.byte, 'l'.byte, 'l'.byte, 'o'.byte]

var bs = newByteStream(input)
bs.setPosition(input.len)
bs.write("hello")
bs.setPosition(0)
for b in output:
  echo bs.peek(uint8)
  assert(bs.read(uint8) == b.uint8, "Data out not as expected!")



