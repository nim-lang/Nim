
## This Class implements the Difference Algorithm published in
## "An O(ND) Difference Algorithm and its Variations" by Eugene Myers
## Algorithmica Vol. 1 No. 2, 1986, p 251.
##
## There are many C, Java, Lisp implementations public available but they all seem to come
## from the same source (diffutils) that is under the (unfree) GNU public License
## and cannot be reused as a sourcecode for a commercial application.
## There are very old C implementations that use other (worse) algorithms.
## Microsoft also published sourcecode of a diff-tool (windiff) that uses some tree data.
## Also, a direct transfer from a C source to C# is not easy because there is a lot of pointer
## arithmetic in the typical C solutions and i need a managed solution.
## These are the reasons why I implemented the original published algorithm from the scratch and
## make it avaliable without the GNU license limitations.
## I do not need a high performance diff tool because it is used only sometimes.
## I will do some performace tweaking when needed.
##
## The algorithm itself is comparing 2 arrays of numbers so when comparing 2 text documents
## each line is converted into a (hash) number. See diffText().
##
## Some chages to the original algorithm:
## The original algorithm was described using a recursive approach and comparing zero indexed arrays.
## Extracting sub-arrays and rejoining them is very performance and memory intensive so the same
## (readonly) data arrays are passed arround together with their lower and upper bounds.
## This circumstance makes the lcs and sms functions more complicate.
## I added some code to the lcs function to get a fast response on sub-arrays that are identical,
## completely deleted or inserted.
##
## The result from a comparisation is stored in 2 arrays that flag for modified (deleted or inserted)
## lines in the 2 data arrays. These bits are then analysed to produce a array of Item objects.
##
## Further possible optimizations:
## (first rule: don't do it; second: don't do it yet)
## The arrays dataA and dataB are passed as parameters, but are never changed after the creation
## so they can be members of the class to avoid the paramter overhead.
## In sms is a lot of boundary arithmetic in the for-D and for-k loops that can be done by increment
## and decrement of local variables.
## The downVector and upVector arrays are alywas created and destroyed each time the sms gets called.
## It is possible to reuse tehm when transfering them to members of the class.
## See TODO: hints.
##
## diff.cs: A port of the algorythm to C#
## Copyright (c) by Matthias Hertel, http://www.mathertel.de
## This work is licensed under a BSD style license. See http://www.mathertel.de/License.aspx
##
## Changes:
## 2002.09.20 There was a "hang" in some situations.
## Now I undestand a little bit more of the sms algorithm.
## There have been overlapping boxes; that where analyzed partial differently.
## One return-point is enough.
## A assertion was added in createDiffs when in debug-mode, that counts the number of equal (no modified) lines in both arrays.
## They must be identical.
##
## 2003.02.07 Out of bounds error in the Up/Down vector arrays in some situations.
## The two vetors are now accessed using different offsets that are adjusted using the start k-Line.
## A test case is added.
##
## 2006.03.05 Some documentation and a direct Diff entry point.
##
## 2006.03.08 Refactored the API to static methods on the Diff class to make usage simpler.
## 2006.03.10 using the standard Debug class for self-test now.
##            compile with: csc /target:exe /out:diffTest.exe /d:DEBUG /d:TRACE /d:SELFTEST Diff.cs
## 2007.01.06 license agreement changed to a BSD style license.
## 2007.06.03 added the optimize method.
## 2007.09.23 upVector and downVector optimization by Jan Stoklasa ().
## 2008.05.31 Adjusted the testing code that failed because of the optimize method (not a bug in the diff algorithm).
## 2008.10.08 Fixing a test case and adding a new test case.
## 2018.12.07 Port to Nim.

import tables, strutils

type
  Item* = object
    startA*: int    ## Start Line number in Data A.
    startB*: int    ## Start Line number in Data B.
    deletedA*: int  ## Number of changes in Data A.
    insertedB*: int ## Number of changes in Data B.

  DiffData = object
    ## Data on one input file being compared.
    len: int ## Number of elements (lines).
    data: seq[int] ## Buffer of numbers that will be compared.
    modified: seq[bool] ## Array of booleans that flag for modified
                        ## data.  This is the result of the diff.
                        ## This means deletedA in the first Data or
                        ## inserted in the second Data.

  SMSRD = object
    x,y: int

proc newDiffData(initData: seq[int]): DiffData =
  ## Initialize the Diff-Data buffer.
  result.len = initData.len
  result.data = initData
  result.modified = newSeq[bool](result.len + 2)

proc diffCodes(aText: string; h: var Table[string,int]): seq[int] =
  ## This function converts all textlines of the text into unique numbers for every unique textline
  ## so further work can work only with simple numbers.
  ## ``aText`` the input text
  ## ``h`` This extern initialized hashtable is used for storing all ever used textlines.
  ## ``trimSpace`` ignore leading and trailing space characters
  ## Returns a array of integers.

  # get all codes of the text
  var lastUsedCode = h.len
  var codes = newSeq[int]()
  for s in aText.splitLines:
    if h.contains s:
      codes.add h[s]
    else:
      inc lastUsedCode
      h[s] = lastUsedCode
      codes.add lastUsedCode

  return codes

proc optimize(data: var DiffData): void =
  ## If a sequence of modified lines starts with a line that contains the same content
  ## as the line that appends the changes, the difference sequence is modified so that the
  ## appended line and not the starting line is marked as modified.
  ## This leads to more readable diff sequences when comparing text files.
  ## ``data`` A Diff data buffer containing the identified changes.

  var startPos, endPos: int
  startPos = 0

  while startPos < data.len:
    while (startPos < data.len) and (data.modified[startPos] == false):
      inc startPos
    endPos = startPos
    while (endPos < data.len) and (data.modified[endPos] == true):
      inc endPos

    if (endPos < data.len) and (data.data[startPos] == data.data[endPos]):
      data.modified[startPos] = false
      data.modified[endPos] = true
    else:
      startPos = endPos

proc sms(dataA: var DiffData; lowerA, upperA: int; dataB: DiffData; lowerB, upperB: int;
  downVector, upVector: var openArray[int]): SMSRD =
  ## This is the algorithm to find the Shortest Middle Snake (sms).
  ## ``dataA`` sequence A
  ## ``lowerA`` lower bound of the actual range in dataA
  ## ``upperA`` upper bound of the actual range in dataA (exclusive)
  ## ``dataB`` sequence B
  ## ``lowerB`` lower bound of the actual range in dataB
  ## ``upperB`` upper bound of the actual range in dataB (exclusive)
  ## ``downVector`` a vector for the (0,0) to (x,y) search. Passed as a parameter for speed reasons.
  ## ``upVector`` a vector for the (u,v) to (N,M) search. Passed as a parameter for speed reasons.
  ## Returns a MiddleSnakeData record containing x,y and u,v.

  let max: int = dataA.len + dataB.len + 1

  let downK = lowerA - lowerB; # the k-line to start the forward search
  let upK = upperA - upperB; # the k-line to start the reverse search

  let delta = (upperA - lowerA) - (upperB - lowerB)
  let oddDelta = (delta and 1) != 0

  # The vectors in the publication accepts negative indexes. the vectors implemented here are 0-based
  # and are access using a specific offset: upOffset upVector and downOffset for downVector
  let downOffset = max - downK
  let upOffset = max - upK

  let maxD = ((upperA - lowerA + upperB - lowerB) div 2) + 1

  # Debug.Write(2, "sms", String.Format("Search the box: A[{0}-{1}] to B[{2}-{3}]", lowerA, upperA, lowerB, upperB))

  # init vectors
  downVector[downOffset + downK + 1] = lowerA
  upVector[upOffset + upK - 1] = upperA

  for D in 0 .. maxD:

    # Extend the forward path.

    for k in countUp(downK - D, downK + D, 2):
      # Debug.Write(0, "sms", "extend forward path " + k.ToString())

      # find the only or better starting point
      var x, y: int
      if k == downK - D:
        x = downVector[downOffset + k + 1]; # down
      else:
        x = downVector[downOffset + k - 1] + 1; # a step to the right
        if (k < downK + D) and (downVector[downOffset + k + 1] >= x):
          x = downVector[downOffset + k + 1]; # down

      y = x - k

      # find the end of the furthest reaching forward D-path in diagonal k.
      while (x < upperA) and (y < upperB) and (dataA.data[x] == dataB.data[y]):
        inc x
        inc y

      downVector[downOffset + k] = x

      # overlap ?
      if oddDelta and (upK - D < k) and (k < upK + D):
        if upVector[upOffset + k] <= downVector[downOffset + k]:
          result.x = downVector[downOffset + k]
          result.y = downVector[downOffset + k] - k
          return

    # Extend the reverse path.
    for k in countUp(upK - D, upK + D, 2):
      # Debug.Write(0, "sms", "extend reverse path " + k.ToString())

      # find the only or better starting point
      var x, y: int
      if k == upK + D:
        x = upVector[upOffset + k - 1]; # up
      else:
        x = upVector[upOffset + k + 1] - 1; # left
        if (k > upK - D) and (upVector[upOffset + k - 1] < x):
          x = upVector[upOffset + k - 1]; # up
      # if
      y = x - k

      while (x > lowerA) and (y > lowerB) and (dataA.data[x - 1] == dataB.data[y - 1]):
        dec x
        dec y

      upVector[upOffset + k] = x

      # overlap ?
      if (not oddDelta) and (downK - D <= k) and (k <= downK + D):
        if upVector[upOffset + k] <= downVector[downOffset + k]:
          result.x = downVector[downOffset + k]
          result.y = downVector[downOffset + k] - k
          return

  assert false, "the algorithm should never come here."

proc lcs(dataA: var DiffData; lowerA, upperA: int; dataB: var DiffData; lowerB, upperB: int; downVector, upVector: var openArray[int]): void =
  ## This is the divide-and-conquer implementation of the longes common-subsequence (lcs)
  ## algorithm.
  ## The published algorithm passes recursively parts of the A and B sequences.
  ## To avoid copying these arrays the lower and upper bounds are passed while the sequences stay constant.
  ## ``dataA`` sequence A
  ## ``lowerA`` lower bound of the actual range in dataA
  ## ``upperA`` upper bound of the actual range in dataA (exclusive)
  ## ``dataB`` sequence B
  ## ``lowerB`` lower bound of the actual range in dataB
  ## ``upperB`` upper bound of the actual range in dataB (exclusive)
  ## ``downVector`` a vector for the (0,0) to (x,y) search. Passed as a parameter for speed reasons.
  ## ``upVector`` a vector for the (u,v) to (N,M) search. Passed as a parameter for speed reasons.
  # make mutable copy
  var lowerA = lowerA
  var lowerB = lowerB
  var upperA = upperA
  var upperB = upperB

  # Debug.Write(2, "lcs", String.Format("Analyse the box: A[{0}-{1}] to B[{2}-{3}]", lowerA, upperA, lowerB, upperB))

  # Fast walkthrough equal lines at the start
  while lowerA < upperA and lowerB < upperB and dataA.data[lowerA] == dataB.data[lowerB]:
    inc lowerA
    inc lowerB

  # Fast walkthrough equal lines at the end
  while lowerA < upperA and lowerB < upperB and dataA.data[upperA - 1] == dataB.data[upperB - 1]:
    dec upperA
    dec upperB

  if lowerA == upperA:
    # mark as inserted lines.
    while lowerB < upperB:
      dataB.modified[lowerB] = true
      inc lowerB

  elif lowerB == upperB:
    # mark as deleted lines.
    while lowerA < upperA:
      dataA.modified[lowerA] = true
      inc lowerA

  else:
    # Find the middle snakea and length of an optimal path for A and B
    let smsrd = sms(dataA, lowerA, upperA, dataB, lowerB, upperB, downVector, upVector)
    # Debug.Write(2, "MiddleSnakeData", String.Format("{0},{1}", smsrd.x, smsrd.y))

    # The path is from LowerX to (x,y) and (x,y) to UpperX
    lcs(dataA, lowerA, smsrd.x, dataB, lowerB, smsrd.y, downVector, upVector)
    lcs(dataA, smsrd.x, upperA, dataB, smsrd.y, upperB, downVector, upVector)  # 2002.09.20: no need for 2 points

# lcs()

proc createDiffs(dataA, dataB: DiffData): seq[Item] =
  ## Scan the tables of which lines are inserted and deleted,
  ## producing an edit script in forward order.

  var startA: int
  var startB: int
  var lineA: int
  var lineB: int

  while lineA < dataA.len or lineB < dataB.len:
    if (lineA < dataA.len) and (not dataA.modified[lineA]) and
       (lineB < dataB.len) and (not dataB.modified[lineB]):
      # equal lines
      inc lineA
      inc lineB
    else:
      # maybe deleted and/or inserted lines
      startA = lineA
      startB = lineB

      while lineA < dataA.len and (lineB >= dataB.len or dataA.modified[lineA]):
        # while (lineA < dataA.len and dataA.modified[lineA])
        inc lineA

      while lineB < dataB.len and (lineA >= dataA.len or dataB.modified[lineB]):
        # while (lineB < dataB.len and dataB.modified[lineB])
        inc lineB

      if (startA < lineA) or (startB < lineB):
        # store a new difference-item
        var aItem: Item
        aItem.startA = startA
        aItem.startB = startB
        aItem.deletedA = lineA - startA
        aItem.insertedB = lineB - startB
        result.add aItem


proc diffInt*(arrayA, arrayB: openArray[int]): seq[Item] =
  ## Find the difference in 2 arrays of integers.
  ## ``arrayA`` A-version of the numbers (usualy the old one)
  ## ``arrayB`` B-version of the numbers (usualy the new one)
  ## Returns a array of Items that describe the differences.

  # The A-Version of the data (original data) to be compared.
  var dataA = newDiffData(@arrayA)

  # The B-Version of the data (modified data) to be compared.
  var dataB = newDiffData(@arrayB)

  let max = dataA.len + dataB.len + 1
  ## vector for the (0,0) to (x,y) search
  var downVector = newSeq[int](2 * max + 2)
  ## vector for the (u,v) to (N,M) search
  var upVector = newSeq[int](2 * max + 2)

  lcs(dataA, 0, dataA.len, dataB, 0, dataB.len, downVector, upVector)
  return createDiffs(dataA, dataB)

proc diffText*(textA,textB: string): seq[Item] =
  ## Find the difference in 2 text documents, comparing by textlines.
  ## The algorithm itself is comparing 2 arrays of numbers so when comparing 2 text documents
  ## each line is converted into a (hash) number. This hash-value is computed by storing all
  ## textlines into a common hashtable so i can find dublicates in there, and generating a
  ## new number each time a new textline is inserted.
  ## ``TextA`` A-version of the text (usualy the old one)
  ## ``TextB`` B-version of the text (usualy the new one)
  ## ``trimSpace`` When set to true, all leading and trailing whitespace characters are stripped out before the comparation is done.
  ## ``ignoreSpace`` When set to true, all whitespace characters are converted to a single space character before the comparation is done.
  ## ``ignoreCase`` When set to true, all characters are converted to their lowercase equivivalence before the comparation is done.
  ## Returns a seq of Items that describe the differences.

  # prepare the input-text and convert to comparable numbers.
  var h = initTable[string,int]()  # TextA.len + TextB.len  <- probably wrong initial size
  # The A-Version of the data (original data) to be compared.
  var dataA = newDiffData(diffCodes(textA, h))

  # The B-Version of the data (modified data) to be compared.
  var dataB = newDiffData(diffCodes(textB, h))

  h.clear # free up hashtable memory (maybe)

  let max = dataA.len + dataB.len + 1
  ## vector for the (0,0) to (x,y) search
  var downVector = newSeq[int](2 * max + 2)
  ## vector for the (u,v) to (N,M) search
  var upVector = newSeq[int](2 * max + 2)

  lcs(dataA, 0, dataA.len, dataB, 0, dataB.len, downVector, upVector)

  optimize(dataA)
  optimize(dataB)
  return createDiffs(dataA, dataB)

when isMainModule:

  proc testHelper(f: seq[Item]): string =
    for it in f:
      result.add(
        $it.deletedA & "." & $it.insertedB & "." & $it.startA & "." & $it.startB & "*"
      )

  proc main(): void =
    var a, b: string

    stdout.writeLine("Diff Self Test...")

    # test all changes
    a = "a,b,c,d,e,f,g,h,i,j,k,l".replace(',', '\n')
    b = "0,1,2,3,4,5,6,7,8,9".replace(',', '\n')
    assert(testHelper(diffText(a, b)) ==
      "12.10.0.0*",
      "all-changes test failed.")
    stdout.writeLine("all-changes test passed.")
    # test all same
    a = "a,b,c,d,e,f,g,h,i,j,k,l".replace(',', '\n')
    b = a
    assert(testHelper(diffText(a, b)) ==
      "",
      "all-same test failed.")
    stdout.writeLine("all-same test passed.")

    # test snake
    a = "a,b,c,d,e,f".replace(',', '\n')
    b = "b,c,d,e,f,x".replace(',', '\n')
    assert(testHelper(diffText(a, b)) ==
      "1.0.0.0*0.1.6.5*",
      "snake test failed.")
    stdout.writeLine("snake test passed.")

    # 2002.09.20 - repro
    a = "c1,a,c2,b,c,d,e,g,h,i,j,c3,k,l".replace(',', '\n')
    b = "C1,a,C2,b,c,d,e,I1,e,g,h,i,j,C3,k,I2,l".replace(',', '\n')
    assert(testHelper(diffText(a, b)) ==
      "1.1.0.0*1.1.2.2*0.2.7.7*1.1.11.13*0.1.13.15*",
      "repro20020920 test failed.")
    stdout.writeLine("repro20020920 test passed.")

    # 2003.02.07 - repro
    a = "F".replace(',', '\n')
    b = "0,F,1,2,3,4,5,6,7".replace(',', '\n')
    assert(testHelper(diffText(a, b)) ==
      "0.1.0.0*0.7.1.2*",
      "repro20030207 test failed.")
    stdout.writeLine("repro20030207 test passed.")

    # Muegel - repro
    a = "HELLO\nWORLD"
    b = "\n\nhello\n\n\n\nworld\n"
    assert(testHelper(diffText(a, b)) ==
      "2.8.0.0*",
      "repro20030409 test failed.")
    stdout.writeLine("repro20030409 test passed.")

    # test some differences
    a = "a,b,-,c,d,e,f,f".replace(',', '\n')
    b = "a,b,x,c,e,f".replace(',', '\n')
    assert(testHelper(diffText(a, b)) ==
      "1.1.2.2*1.0.4.4*1.0.7.6*",
      "some-changes test failed.")
    stdout.writeLine("some-changes test passed.")

    # test one change within long chain of repeats
    a = "a,a,a,a,a,a,a,a,a,a".replace(',', '\n')
    b = "a,a,a,a,-,a,a,a,a,a".replace(',', '\n')
    assert(testHelper(diffText(a, b)) ==
      "0.1.4.4*1.0.9.10*",
      "long chain of repeats test failed.")

    stdout.writeLine("End.")
    stdout.flushFile

  main()
