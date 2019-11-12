discard """
  output: "OK"
"""
import base64

proc main() =
  doAssert encode("Hello World") == "SGVsbG8gV29ybGQ="
  doAssert encode("leasure.") == "bGVhc3VyZS4="
  doAssert encode("easure.") == "ZWFzdXJlLg=="
  doAssert encode("asure.") == "YXN1cmUu"
  doAssert encode("sure.") == "c3VyZS4="
  doAssert encode([1,2,3]) == "AQID"
  doAssert encode(['h','e','y']) == "aGV5"

  doAssert encode("") == ""
  doAssert decode("") == ""

  const testInputExpandsTo76 = "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  const testInputExpands = "++++++++++++++++++++++++++++++"
  const longText = """Man is distinguished, not only by his reason, but by this
    singular passion from other animals, which is a lust of the mind,
    that by a perseverance of delight in the continued and indefatigable
    generation of knowledge, exceeds the short vehemence of any carnal
    pleasure."""
  const tests = ["", "abc", "xyz", "man", "leasure.", "sure.", "easure.",
                 "asure.", longText, testInputExpandsTo76, testInputExpands]

  doAssert encodeMIME("foobarbaz", lineLen=4) == "Zm9v\r\nYmFy\r\nYmF6"
  doAssert decode("Zm9v\r\nYmFy\r\nYmF6") == "foobarbaz"

  for t in items(tests):
    doAssert decode(encode(t)) == t
    doAssert decode(encodeMIME(t, lineLen=40)) == t
    doAssert decode(encodeMIME(t, lineLen=76)) == t

  const invalid = "SGVsbG\x008gV29ybGQ="
  try:
    doAssert decode(invalid) == "will throw error"
  except ValueError:
    discard

  echo "OK"

main()
