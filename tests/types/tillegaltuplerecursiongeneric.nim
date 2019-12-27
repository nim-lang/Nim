discard """
  errormsg: "illegal recursion in type 'RefTree'"
"""

type
  RefTree[T] = ref tuple[le, ri: RefTree[T]; data: T]
  RefTreeInt = RefTree[int]
