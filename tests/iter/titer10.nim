discard """
  output: '''3
2
5
1
@[@[0, 0], @[0, 1]]
@[@[0, 0], @[0, 1]]
@[@[2, 2], @[2, 3]]
@[@[2, 2], @[2, 3]]'''
"""

when true:
  # bug #2604

  import algorithm

  iterator byDistance*[int]( ints: openArray[int], base: int ): int =
      var sortable = @ints

      sortable.sort do (a, b: int) -> int:
          result = cmp( abs(base - a), abs(base - b) )

      for val in sortable:
          yield val

  when true:
    proc main =
      for val in byDistance([2, 3, 5, 1], 3):
          echo val
    main()

when true:
  # bug #1527

  import sequtils

  let thread = @[@[0, 0],
                 @[0, 1],
                 @[2, 2],
                 @[2, 3]]

  iterator threadUniqs(seq1: seq[seq[int]]): seq[seq[int]] =
    for i in 0 ..< seq1.len:
      block:
        let i = i
        yield seq1.filter do (x: seq[int]) -> bool: x[0] == seq1[i][0]
  proc main2 =
    for uniqs in thread.threadUniqs:
      echo uniqs

  main2()
