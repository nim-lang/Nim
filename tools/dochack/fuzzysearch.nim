# A Fuzzy Match implementation inspired by the sublime text fuzzy match algorithm
# as described here: https://blog.forrestthewoods.com/reverse-engineering-sublime-text-s-fuzzy-match-4cffeed33fdb
# Heavily modified to provide more subjectively useful results
# for on the Nim manual.
#
import strutils
import math


const
  MaxUnmatchedLeadingChar = 3
  ## Maximum number of times the penalty for unmatched leading chars is applied.

  HeadingScaleFactor = 0.5
  ## The score from before the colon Char is multiplied by this.
  ## This is to weight function signatures and descriptions over module titles.


type
  ScoreCard = enum
    StartMatch           = -100 ## Start matching.
    LeadingCharDiff      = -3   ## An unmatched, leading character was found.
    CharDiff             = -1   ## An unmatched character was found.
    CharMatch            = 0    ## A matched character was found.
    ConsecutiveMatch     = 5    ## A consecutive match was found.
    LeadingCharMatch     = 10   ## The character matches the beginning of the
                                ## string or the first character of a word
                                ## or camel case boundary.
    WordBoundryMatch     = 20   ## The last ConsecutiveCharMatch that
                                ## immediately precedes the end of the string,
                                ## end of the pattern, or a LeadingCharMatch.


proc fuzzyMatch*(pattern, str: cstring) : tuple[score: int, matched: bool] =
  var
    scoreState = StartMatch
    headerMatched = false
    unmatchedLeadingCharCount = 0
    consecutiveMatchCount = 0
    strIndex = 0
    patIndex = 0
    score = 0

  template transition(nextState) =
    scoreState = nextState
    score += ord(scoreState)

  while (strIndex < str.len) and (patIndex < pattern.len):
    var
      patternChar = pattern[patIndex].toLowerAscii
      strChar     = str[strIndex].toLowerAscii

    # Ignore certain characters
    if patternChar in {'_', ' ', '.'}:
      patIndex += 1
      continue
    if strChar in {'_', ' ', '.'}:
      strIndex += 1
      continue

    # Since this algorithm will be used to search against Nim documentation,
    # the below logic prioritizes headers.
    if not headerMatched and strChar == ':':
      headerMatched = true
      scoreState = StartMatch
      score = int(floor(HeadingScaleFactor * float(score)))
      patIndex = 0
      strIndex += 1
      continue

    if strChar == patternChar:
      case scoreState
      of StartMatch, WordBoundryMatch:
        scoreState = LeadingCharMatch

      of CharMatch:
        transition(ConsecutiveMatch)

      of LeadingCharMatch, ConsecutiveMatch:
        consecutiveMatchCount += 1
        scoreState = ConsecutiveMatch
        score += ord(ConsecutiveMatch) * consecutiveMatchCount

        if scoreState == LeadingCharMatch:
          score += ord(LeadingCharMatch)

        var onBoundary = (patIndex == high(pattern))
        if not onBoundary and strIndex < high(str):
          let
            nextPatternChar = toLowerAscii(pattern[patIndex + 1])
            nextStrChar     = toLowerAscii(str[strIndex + 1])

          onBoundary = (
            nextStrChar notin {'a'..'z'} and
            nextStrChar != nextPatternChar
          )

        if onBoundary:
          transition(WordBoundryMatch)

      of CharDiff, LeadingCharDiff:
        var isLeadingChar = (
          str[strIndex - 1] notin Letters or
          str[strIndex - 1] in {'a'..'z'} and
          str[strIndex] in {'A'..'Z'}
        )

        if isLeadingChar:
          scoreState = LeadingCharMatch
          #a non alpha or a camel case transition counts as a leading char.
          # Transition the state, but don't give the bonus yet; wait until we verify a consecutive match.
        else:
          transition(CharMatch)
      patIndex += 1

    else:
      case scoreState
      of StartMatch:
        transition(LeadingCharDiff)

      of ConsecutiveMatch:
        transition(CharDiff)
        consecutiveMatchCount = 0

      of LeadingCharDiff:
        if unmatchedLeadingCharCount < MaxUnmatchedLeadingChar:
          transition(LeadingCharDiff)
        unmatchedLeadingCharCount += 1

      else:
        transition(CharDiff)

    strIndex += 1

  if patIndex == pattern.len and (strIndex == str.len or str[strIndex] notin Letters):
    score += 10

  result = (
    score:   max(0, score),
    matched: (score > 0),
  )
