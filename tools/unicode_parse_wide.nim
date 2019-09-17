import strutils, sequtils

let
  # this file was obtained from:
  # https://www.unicode.org/Public/UCD/latest/ucd/EastAsianWidth.txt
  wideFilename = "tools/UnicodeEastAsianWidth.txt"
  wideData = readFile(wideFilename).strip.splitLines()

type
  Ranges = tuple[start, stop: int]
  Singlets = int

var
  wideSinglets = newSeq[Singlets]()
  wideRanges = newSeq[Ranges]()

proc parseData(data: seq[string]) =
  for line in data:
    let fields = line.split(';')
    if fields[1].startsWith('W') or fields[1].startsWith('F'):
      let nrs = fields[0].split("..").map(parseHexInt)
      if len(nrs) == 2:
        wideRanges.add (nrs[0], nrs[1])
      else:
        wideSinglets.add nrs[0]

parseData(wideData)


var output: string

proc createHeader(output: var string) =
  output.add "# This file was created from a script.\n\n"
  output.add "const\n"

proc `$`(r: Ranges): string =
  let
    start = "0x" & toHex(r.start, 5)
    stop = "0x" & toHex(r.stop, 5)
  result = "$#, $#,\n" % [start, stop]

proc `$`(r: Singlets): string =
  let code = "0x" & toHex(r, 5)
  result = "$#,\n" % [code]

proc outputSeq(s: seq[Ranges|Singlets], name: string, output: var string) =
  output.add "  $# = [\n" % name
  for r in s:
    output.add "    " & $r
  output.add "  ]\n\n"


output.createHeader()
outputSeq(wideSinglets, "wideSinglets", output)
outputSeq(wideRanges, "wideRanges", output)

# manually add combining characters with the width of zero:
output.add("""
  combiningChars = [0x00300, 0x0036F]
""")


let outfile = "lib/pure/includes/unicode_wide.nim"
outfile.writeFile(output)
