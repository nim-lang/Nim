import unittest, sequtils
import nre except toSeq
import optional_nonstrict
import times, strutils

suite "find":
  test "find text":
    check("3213a".find(re"[a-z]").match == "a")
    check(toSeq(findIter("1 2 3 4 5 6 7 8 ", re" ")).map(
      proc (a: RegexMatch): string = a.match
    ) == @[" ", " ", " ", " ", " ", " ", " ", " "])

  test "find bounds":
    check(toSeq(findIter("1 2 3 4 5 ", re" ")).map(
      proc (a: RegexMatch): Slice[int] = a.matchBounds
    ) == @[1..1, 3..3, 5..5, 7..7, 9..9])

  test "overlapping find":
    check("222".findAll(re"22") == @["22"])
    check("2222".findAll(re"22") == @["22", "22"])

  test "len 0 find":
    check("".findAll(re"\ ") == newSeq[string]())
    check("".findAll(re"") == @[""])
    check("abc".findAll(re"") == @["", "", "", ""])
    check("word word".findAll(re"\b") == @["", "", "", ""])
    check("word\r\lword".findAll(re"(*ANYCRLF)(?m)$") == @["", ""])
    check("слово слово".findAll(re"(*U)\b") == @["", "", "", ""])

  test "bail early":
    ## we expect nothing to be found and we should be bailing out early which means that
    ## the timing difference between searching in small and large data should be well
    ## within a tolerance area
    const tolerance = 0.0001
    var smallData = repeat("url.sequence = \"http://whatever.com/jwhrejrhrjrhrjhrrjhrjrhrjrh\"", 10)
    var largeData = repeat("url.sequence = \"http://whatever.com/jwhrejrhrjrhrjhrrjhrjrhrjrh\"", 1000000)
    var start = cpuTime()
    check(largeData.findAll(re"url.*? = &#39;(.*?)&#39;") == newSeq[string]())
    var stop = cpuTime()
    var elapsedLarge = stop - start
    start = cpuTime()
    check(smallData.findAll(re"url.*? = &#39;(.*?)&#39;") == newSeq[string]())
    stop = cpuTime()
    var elapsedSmall = stop - start
    var difference =  elapsedLarge - elapsedSmall
    check(difference < tolerance)
