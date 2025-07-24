discard """
action: compile
"""

type
  TTest = tuple[x: range[0..80], y: range[0..25]]

let x: TTest = (2, 23)
