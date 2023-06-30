discard """
  timeout: 10
  joinable: false
  output: "fine"
"""

func addString(): string =
  let x = newString(1000000)
  for i in 0..<1000000:
    discard x[i]

const translationTable = addString()
echo "fine"
