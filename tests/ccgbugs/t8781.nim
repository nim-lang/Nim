discard """
output: ""
"""

type
  Drawable = object of RootObj
    discard

  # issue #8781, following type was broken due to 'U' suffix
  # on `animatedU`. U also added as union identifier for C.
  # replaced by "_U" prefix, which is not allowed as an
  # identifier
  TypeOne = ref object of Drawable
    animatedU: bool
    case animated: bool
    of true:
        frames: seq[int]
    of false:
        region: float

when true:
  let r = 1.5
  let a = TypeOne(animatedU: true,
                  animated: false,
                  region: r)
