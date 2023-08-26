type List[O] = ref object
  next: List[O]

proc initList[O](l: List[O]) =
  l.next = l

type
  PolytopeVertex[R] = object
    list: List[PolytopeVertex[R]]

  PolytopeEdge[R] = object
    list: List[PolytopeEdge[R]]

  Polytope[R] = object
    vertices: List[PolytopeVertex[R]]
    edges: List[PolytopeEdge[R]]

var pt: Polytope[float]
initList(pt.vertices)
initList(pt.edges)