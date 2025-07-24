type List[O] = object
  next: ptr List[O]

proc initList[O](l: ptr List[O]) =
  l[].next = l

type
  PolytopeVertex[R] = object
    list: List[PolytopeVertex[R]]

  PolytopeEdge[R] = object
    list: List[PolytopeEdge[R]]

  Polytope[R] = object
    vertices: List[PolytopeVertex[R]]
    edges: List[PolytopeEdge[R]]

var pt: Polytope[float]

static:
  doAssert pt.vertices.next is (ptr List[PolytopeVertex[float]])
  doAssert pt.edges.next is (ptr List[PolytopeEdge[float]])

initList(addr pt.vertices)
initList(addr pt.edges)