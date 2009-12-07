type
  TCardPts = enum
    North, West, South, East

  TCardPts2 = enum of TCardPts
    N, W, S, E

# If I do:
var y = W
echo($y & "=" & $ord(y)) #OUT W=5
