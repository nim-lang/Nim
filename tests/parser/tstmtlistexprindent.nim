type E = enum A, B, C
proc junk(e: E) =
  case e
  of A: (echo "a";
         discard; discard;
  discard)
  else: discard
