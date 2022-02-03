from os import parentDir, `/`

type
  Rectangle* {.importc: "Rectangle", header: currentSourcePath().parentDir()/"rect.h", bycopy.} = object
    x* {.importc: "x".}: cfloat  ##  NmrlbNow_Rectangle top-left corner position x
    y* {.importc: "y".}: cfloat  ##  NmrlbNow_Rectangle top-left corner position y
    width* {.importc: "width".}: cfloat ##  NmrlbNow_Rectangle width
    height* {.importc: "height".}: cfloat ##  NmrlbNow_Rectangle height

  ValueType* = object
    payload: int
  Effect* = object
  
  Node* = object
    disabled: bool
    shapepos: Rectangle
    inputs: seq[ValueType]
    outputs: seq[ValueType]
    rails: seq[Effect]

const SHAPEPOS = Rectangle(x: 12.0, y: 34.0, width: 56.0, height: 78.0)

var nodes: seq[Node]
var node: Node = default(Node)
let shapepos = SHAPEPOS
node.shapepos = shapepos
node.inputs.add ValueType(payload:42)
echo node
nodes.add node
echo nodes
doAssert nodes[0].shapepos.x == SHAPEPOS.x
doAssert nodes[0].shapepos == SHAPEPOS
