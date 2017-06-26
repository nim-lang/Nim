# bug #3452
import math

type
  Node* = concept n
    `==`(n, n) is bool

  Graph1* = concept g
    type N = Node
    distance(g, N, N) is float

  Graph2 = concept g
    distance(g, Node, Node) is float

  Graph3 = concept g
    var x: Node
    distance(g, x, x) is float

  XY* = tuple[x, y: int]

  MyGraph* = object
    points: seq[XY]

static:
  assert XY is Node

proc distance*( g: MyGraph, a, b: XY): float =
  sqrt( pow(float(a.x - b.x), 2) + pow(float(a.y - b.y), 2) )

static:
  assert MyGraph is Graph1
  assert MyGraph is Graph2
  assert MyGraph is Graph3

