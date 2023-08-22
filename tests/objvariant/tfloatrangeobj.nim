discard """
  output: '''(kind: 2.0, twoStr: "TWO STR")
(kind: 1.0)
'''
disabled: "true"
"""
type
  FloatRange = range[1.0..3.0]
  VariantObj = object
    case kind: FloatRange
    of 2.0: twoStr: string

echo VariantObj(kind: 2.0, twoStr: "TWO STR")
echo VariantObj(kind: 1.0)
