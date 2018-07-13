# A Fuzzy Match implementation inspired by the sublime text fuzzy match algorithm
# as described here: https://blog.forrestthewoods.com/reverse-engineering-sublime-text-s-fuzzy-match-4cffeed33fdb
# Heavily modified to provide more subjectively useful results
# for on the Nim manual.
#

import strutils
import math
import macros

type
  FuzzyMatchResult* = object
    ismatch*: bool
    score*: int 


# Fuzzy match score.
#  A positive number is a bonus
#  A negative number is a penalty
type ScoreCard {.pure.} = enum 
  Start = -100, # this acts as a state machine. So we need nil start and end states.
  UnmatchedLeadingChar = -3, # for each unmatched character from the start of the string
  UnmatchedChar = -1, # for each single letter does not match
  MatchedChar = 0, # for each single letter matches
  ConsecutiveMatch = 5, # every consecutive letter that matches after the first
  LeadingCharMatch = 10, # The character matches the begining of the string 
                         # or the first character of a word boundry (a space)
                         # or a camel case boundry: 
                         #    An upper case letter that is preceded by a lower case letter.
                         # This bonus is only applied if a consecutive match is also found.
                         # This is because it gives too much bias
                         # to single char matches at word boundries.
  WordBoundryMatch = 20

const
  MaxUnmatchedLeadingChar = 3
  # max number of times we will apply the penalty for unmatched leading chars.

  HeadingScaleFactor = 0.5
  # The score from before the colon Char is multiplied by this.
  # This is to weight function signatures and descriptions over module titles.

template stateTransition(currentState, nextState: ScoreCard, score: int): untyped =
  currentState = nextState
  score += ord(nextState)

proc fuzzymatch* (pattern, str: cstring) : FuzzyMatchResult =
  var
    scoreState = ScoreCard.Start
    headerMatched = false
    unmatchedLeadingCharCount = 0
    consecutiveMatchCount = 0
    strIndex = 0
    patIndex = 0
    curScore = 0
    normalizedStrChar : char
    normalizedPatternChar : char

  while (strIndex < str.len) and (patIndex < pattern.len):
    # normalize from strutils doesn't work on cstrings :-(
    # I am doing an inline emulation of it here.
    # lowercase everything and ignore underscores.
    normalizedPatternChar = pattern[patIndex].toLowerAscii
    normalizedStrChar = str[strIndex].toLowerAscii
    #ignore certain chars
    if
      normalizedStrChar == '_' or
      normalizedStrChar == ' ' or
      normalizedStrChar == '.':
      strIndex += 1
      continue
    if 
      normalizedPatternChar == '_' or
      normalizedPatternChar == ' ' or
      normalizedPatternChar == '.':
      patIndex += 1
      continue
    
    if not headerMatched and normalizedStrChar == ':':
      # We matched the header. Apply the scale factor and reset the search pattern.
      headerMatched = true
      curScore = toInt(floor(HeadingScaleFactor * toFloat(curScore)))
      patIndex = 0
      scoreState = ScoreCard.Start
      strIndex += 1
      continue

    if normalizedStrChar == normalizedPatternChar:
      case scoreState 
      of ScoreCard.Start:
        scoreState = ScoreCard.LeadingCharMatch
        # Transition the state, but don't give the bonus yet; wait until we verify a consecutive match.
      of ScoreCard.MatchedChar:
        scoreState.stateTransition(ScoreCard.ConsecutiveMatch, curScore)
      of ScoreCard.LeadingCharMatch:
        # Do the normal state transition. But then give the Leading Char bonus.
        # We only want to give the leading char bonus if it also has a consectutive match.
        # Giving a huge bonus to a single char match throws off the results too much.
        scoreState = ScoreCard.ConsecutiveMatch
        consecutiveMatchCount += 1
        curScore += ord(ScoreCard.ConsecutiveMatch) * consecutiveMatchCount
        curScore += ord(ScoreCard.LeadingCharMatch)
        if (patIndex == pattern.len - 1) or
           (
              (strIndex < str.len - 1) and
              (
                (str[strIndex + 1].toLowerAscii != pattern[patIndex + 1].toLowerAscii) and
                (not str[strIndex + 1].isLowerAscii) 
              )
            ):
          scoreState.stateTransition(ScoreCard.WordBoundryMatch, curScore)
      of ScoreCard.ConsecutiveMatch:
        scoreState = ScoreCard.ConsecutiveMatch
        consecutiveMatchCount += 1
        curScore += ord(ScoreCard.ConsecutiveMatch) * consecutiveMatchCount
        if (patIndex == pattern.len - 1) or
           (
              (strIndex < str.len - 1) and
              (
                (str[strIndex + 1].toLowerAscii != pattern[patIndex + 1].toLowerAscii) and
                (not str[strIndex + 1].isLowerAscii) 
              )
            ):
          scoreState.stateTransition(ScoreCard.WordBoundryMatch, curScore)
      of ScoreCard.WordBoundryMatch:
        scoreState = ScoreCard.LeadingCharMatch
      of ScoreCard.UnmatchedChar:
        if
          not str[strIndex - 1].isAlphaAScii or
          (str[strIndex - 1].isLowerAscii and
          str[strIndex].isUpperAscii):
          #a non alpha or a camel case transiton counts as a leading char.
          scoreState = ScoreCard.LeadingCharMatch
          # Transition the state, but don't give the bonus yet; wait until we verify a consecutive match.
        else:
          scoreState.stateTransition(ScoreCard.MatchedChar, curScore)
      of ScoreCard.UnmatchedLeadingChar:
        if
          not str[strIndex - 1].isAlphaAScii or
          (str[strIndex - 1].isLowerAscii and
          str[strIndex].isUpperAscii):
          #a non alpha or a camel case transiton counts as a leading char.
          scoreState = ScoreCard.LeadingCharMatch
          # Transition the state, but don't give the bonus yet; wait until we verify a consecutive match.
        else:
          scoreState.stateTransition(ScoreCard.MatchedChar, curScore)
      patIndex += 1
    else:
      case scoreState 
      of ScoreCard.Start:
        scoreState.stateTransition(ScoreCard.UnmatchedLeadingChar, curScore)
      of ScoreCard.UnmatchedChar:
        scoreState.stateTransition(ScoreCard.UnmatchedChar, curScore)
      of ScoreCard.MatchedChar:
        scoreState.stateTransition(ScoreCard.UnmatchedChar, curScore)
      of ScoreCard.LeadingCharMatch:
        scoreState.stateTransition(ScoreCard.UnmatchedChar, curScore)
      of ScoreCard.WordBoundryMatch:
        scoreState.stateTransition(ScoreCard.UnmatchedChar, curScore)
      of ScoreCard.ConsecutiveMatch:
        scoreState.stateTransition(ScoreCard.UnmatchedChar, curScore)
        consecutiveMatchCount = 0
      of ScoreCard.UnmatchedLeadingChar:
        if (unmatchedLeadingCharCount < MaxUnmatchedLeadingChar):
          # Stop penalizing after so many unmatched leading characters.
          scoreState.stateTransition(ScoreCard.UnmatchedLeadingChar, curScore)
        unmatchedLeadingCharCount += 1
    
    strIndex += 1

  result = FuzzyMatchResult(ismatch: (curScore > 0), score: max(0, curScore))

