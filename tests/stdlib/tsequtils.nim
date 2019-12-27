discard """
  output: "OK"
"""
import sequtils, sugar, math

template test() =
  block: # partition
    let numbers = @[1, 2, 3, 4, 5, 6, 7]
    assert numbers.partition(3) == @[@[1, 2, 3], @[4, 5, 6]]
    assert numbers.partition(10) == @[]

  block: # count & countIt
    let
      b = "abracadabra"
    doAssert count(b, func (c: char): bool = c in {'a', 'r'}) == 7
    doAssert countIt(b, it in {'a', 'r'}) == 7
    doAssert countIt(b, it == 'z') == 0

  block: # mapIndexed
    doAssert @["I", "II", "III"].mapIndexed(
              proc (i: int, x: string): string = $(i + 1) & ":" & x) == @["1:I", "2:II", "3:III"]

  block: # zipWith
    let
      s1 = @[1, 2, 3]
      s2 = @[4, 5, 6]
      s3 = @[5, 7, 9, 9]
      zip1 = zipWith(s1, s2, s3, func (x, y, z: int): bool = x + y == z)
      zip2 = zipWith(s1, s2, (x, y) => x + y)
    doAssert zip1 == @[true, true, true]
    doAssert zip2 == @[5, 7, 9]

  block: # zipThem
    let
      s1 = @[1, 2, 3]
      s2 = @[4, 5, 6]
      s3 = @[5, 7, 9, 9]
      zip1 = zipThem(s1, s2, s3, it + jt == kt)
      zip2 = zipThem(s1, s2, it + jt)
    doAssert zip1 == @[true, true, true]
    doAssert zip2 == @[5, 7, 9]
    doAssert zipThem(@[1, 2, 3], @["I", "II", "III", "IV"], $it & ":" & jt) == @["1:I", "2:II", "3:III"]

  block: # scan
    let s1 = @[1, 2, 3]
    var r: string
    s1.scan(proc (it: int) = r = r & $it)
    doAssert r == "123"

  block: # zippedScan
    let
      s1 = @[1, 2, 3]
      s2 = @[4, 5, 6]
      s3 = @[5, 7, 9, 9]
    var
      zip1: seq[bool] = @[]
      zip2: seq[int] = @[]
    zippedScan(s1, s2, s3, proc (x, y, z: int) = zip1.add(x + y == z))
    zippedScan(s1, s2, proc (x, y: int) = zip2.add(x + y))
    doAssert zip1 == @[true, true, true]
    doAssert zip2 == @[5, 7, 9]

  block: # scanIt
    let s1 = @[1, 2, 3]
    var r: seq[string] = @[]
    s1.scanIt(r.add($it))
    doAssert r == @["1", "2", "3"]

  block: # scanIndexed
    var r: seq[string]
    @["I", "II", "III"].scanIndexed(
              proc (i: int, x: string) = r.add($(i + 1) & ":" & x))          
    doAssert r == @["1:I", "2:II", "3:III"]

  block: # scanThem
    let
      s1 = @[1, 2, 3]
      s2 = @[4, 5, 6]
      s3 = @[5, 7, 9, 9]
    var r: seq[bool] = @[]
    var zip2: seq[int]
    scanThem(s1, s2, s3, r.add(it + jt == kt))
    scanThem(s1, s2, zip2.add(it + jt))
    doAssert r == @[true, true, true]
    doAssert zip2 == [5, 7, 9]

  block: # findFirst  
    let
      l = @[2, 4, 6, 7, 9]
      x = findFirst(l, pred = proc(x: int): bool = x mod 2 == 1)
    doAssert x == 7
    doAssert findItFirst(l, it mod 2 == 1) == 7
    doAssert findItFirst(l, it == 100) == default(int)

  block: # indexOf
    let
      l = @["one", "two", "three"]
    doAssert l.indexOf("one") == 0
    doAssert l.indexOf(proc (x: string): bool = x == "one") == 0
    doAssert l.indexOf("four") == -1
    doAssert l.indexOf(proc (x: string): bool = x == "four") == -1
    doAssert l.indexOfIt(it == "one") == 0
    doAssert l.indexOfIt(it == "four") == -1

  block: # nest
    doAssert nest(func (x: int): int = x * 2, 1, 3) == [1, 2, 4, 8]
    doAssert nest(func (x: int): int = x * 2, 1, 0) == [1]
  
    doAssert nestIt(it * 2, 1, 3) == [1, 2, 4, 8]
    doAssert nestIt(it * 2, 1, 0) == [1]
    doAssert nestIt("1" & it, "1", 4) == @["1", "11", "111", "1111", "11111"]
    
  block: # while
    doAssert lenWhile(@[1, 2, 3, 4, 5], func (x: int): bool = x < 4) == 3
    doAssert takeWhile(@[1, 2, 3, 4, 5], func (x: int): bool = x < 4) == @[1, 2, 3]
    doAssert dropWhile(@[1, 2, 3, 4, 5], func (x: int): bool = x < 4) == @[4, 5]
    
    doAssert lenWhile(@[1, 2, 3, 4, 5], func (x: int): bool = x > 10) == 0
    doAssert takeWhile(@[1, 2, 3, 4, 5], func (x: int): bool = x > 10) == @[]
    doAssert dropWhile(@[1, 2, 3, 4, 5], func (x: int): bool = x > 10) == @[1, 2, 3, 4, 5]

    doAssert lenWhile(@[1, 2, 3, 4, 5], func (x: int): bool = x < 10) == 5
    doAssert takeWhile(@[1, 2, 3, 4, 5], func (x: int): bool = x < 10) == @[1, 2, 3, 4, 5]
    doAssert dropWhile(@[1, 2, 3, 4, 5], func (x: int): bool = x < 10) == @[]

    let
      s: seq[int] = @[]
    doAssert lenWhile(s, func (x: int): bool = x < 10) == 0
    doAssert takeWhile(s, func (x: int): bool = x < 10) == @[]
    doAssert dropWhile(s, func (x: int): bool = x < 10) == @[]
  
  block: # whileIt
    doAssert lenWhileIt(@[1, 2, 3, 4, 5], it < 4) == 3
    doAssert takeItWhile(@[1, 2, 3, 4, 5], it < 4) == @[1, 2, 3]
    doAssert dropItWhile(@[1, 2, 3, 4, 5], it < 4) == @[4, 5]

    doAssert takeItWhile(@[1, 2, 3, 4, 5], it > 10) == @[]
    doAssert dropItWhile(@[1, 2, 3, 4, 5], it < 10) == @[]

    doAssert takeItWhile(@[1, 2, 3, 4, 5], it < 10) == @[1, 2, 3, 4, 5]
    doAssert dropItWhile(@[1, 2, 3, 4, 5], it > 10) == @[1, 2, 3, 4, 5]

    let
      s: seq[int] = @[]
    doAssert lenWhileIt(s, it < 10) == 0
    doAssert takeItWhile(s, it < 10) == @[]
    doAssert dropItWhile(s, it < 10) == @[]
  
static:
  test()

test()
echo "OK"