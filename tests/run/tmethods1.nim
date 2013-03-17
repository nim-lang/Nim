discard """
  output: "do nothing"
"""

method somethin(obj: TObject) =
  echo "do nothing"

var o: TObject
o.somethin()

