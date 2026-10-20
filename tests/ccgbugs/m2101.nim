type World* = object
  dingo*: int

var w = World(dingo: 42)
var worldptr* {.codegenDecl: "__thread $# $#".}: ptr World = addr w
