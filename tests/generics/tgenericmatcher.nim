discard """
  output: '''
'''
"""


block tmatcher1:
  type
    TMatcherKind = enum
      mkTerminal, mkSequence, mkAlternation, mkRepeat
    TMatcher[T] = object
      case kind: TMatcherKind
      of mkTerminal:
        value: T
      of mkSequence, mkAlternation:
        matchers: seq[TMatcher[T]]
      of mkRepeat:
        matcher: PMatcher[T]
        min, max: int
    PMatcher[T] = ref TMatcher[T]

  var m: PMatcher[int]


block tmatcher2:
  type
    TMatcherKind = enum
      mkTerminal, mkSequence, mkAlternation, mkRepeat
    TMatcher[T] = object
      case kind: TMatcherKind
      of mkTerminal:
        value: T
      of mkSequence, mkAlternation:
        matchers: seq[TMatcher[T]]
      of mkRepeat:
        matcher: ref TMatcher[T]
        min, max: int
  
  var m: ref TMatcher[int]

