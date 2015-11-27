discard """
  output: '''XY is Node
MyGraph is Graph'''
"""
# bug #3452
import math

type
    Node* = concept n
        `==`(n, n) is bool

    Graph* = concept g
        var x: Node
        distance(g, x, x) is float

    XY* = tuple[x, y: int]

    MyGraph* = object
        points: seq[XY]

if XY is Node:
    echo "XY is Node"

proc distance*( g: MyGraph, a, b: XY): float =
    sqrt( pow(float(a.x - b.x), 2) + pow(float(a.y - b.y), 2) )

if MyGraph is Graph:
    echo "MyGraph is Graph"

