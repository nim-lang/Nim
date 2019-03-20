discard """
  errormsg: "illegal recursion in type 'RefTreeInt'"
"""

type
  RefTree[T] = ref tuple[le, ri: RefTree[T]; data: T]
  RefTreeInt = RefTree[int]
