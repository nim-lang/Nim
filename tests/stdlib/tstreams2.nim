discard """
  file: "tstreams2.nim"
  output: '''[Suite] streams
fs is: nil


[Suite] unpackInt

'''
"""
import streams, unittest

suite "streams":

  test "missingfile":

    var
      fs = newFileStream("amissingfile.txt")
      line = ""
    echo "fs is: ",repr(fs)
    if not isNil(fs):
      while fs.readLine(line):
        echo line
      fs.close()

# copyMem is not available for js #5667
when not defined(js):

  proc unpackInt(s, format: string): int =
    let st = newStringStream(s)
    return unpackInt(st, format)

  suite "unpackInt":

    test "unpackInt b":
      check "\xa0".unpackInt("b") == -96

    test "unpackInt B":
      check "\xa0".unpackInt("B") == 160

    test "unpackInt =h":
      check unpackInt("\xf0\xa0", "<h") == -24336
    test "unpackInt =H":
      check unpackInt("\xf0\xa0", "<H") == 41200
    test "unpackInt =i":
      check unpackInt("\x00\xa0\xff\xff", "<i") == -24576
    test "unpackInt =I":
      check unpackInt("\x00\xa0\xff\xff", "<I") == 4294942720

    test "unpackInt <h":
      check unpackInt("\xf0\xa0", "<h") == -24336
    test "unpackInt <H":
      check unpackInt("\xf0\xa0", "<H") == 41200

    test "unpackInt >h":
      check unpackInt("\xf0\xa0", ">h") == -3936
      check unpackInt("\x80\x00", ">h") == -32768
      check unpackInt("\x7f\xff", ">h") == 32767
    test "unpackInt !h":
      check unpackInt("\xf0\xa0", "!h") == -3936
    test "unpackInt >H":
      check unpackInt("\xf0\xa0", ">H") == 61600
    test "unpackInt !H":
      check unpackInt("\xf0\xa0", "!H") == 61600

    test "unpackInt <i":
      check unpackInt("\x00\xa0\xff\xff", "<i") == -24576
    test "unpackInt <I":
      check unpackInt("\x00\xa0\xff\xff", "<I") == 4294942720

    test "unpackInt >i":
      check unpackInt("\xf0\xa0\xf0\x10", ">i") == -257888240
    test "unpackInt >I":
      check unpackInt("\xf0\xa0\xf0\x10", ">I") == 4037079056

