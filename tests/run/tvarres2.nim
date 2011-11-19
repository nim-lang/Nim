discard """
  output: "45 hallo"
"""

type
  TKachel = tuple[i: int, s: string]
  TSpielwiese = object
    k: seq[TKachel]

var
  spielwiese: TSpielwiese
newSeq(spielwiese.k, 64)

proc at*(s: var TSpielwiese, x, y: int): var TKachel =
  result = s.k[y * 8 + x]

spielwiese.at(3, 4) = (45, "hallo")

echo spielwiese.at(3,4)[0], " ", spielwiese.at(3,4)[1]

