import
  tri_engine/gfx/gl/primitive,
  tri_engine/gfx/tex,
  tri_engine/gfx/color,
  tri_engine/math/rect,
  tri_engine/math/vec

type
  TWidgetLayer* = enum
    wlBg      = 100,
    wlOverlap = 200,
    wlMain    = 300,
    wlOverlay = 400,
    wlCursor  = 500
  TWidgetLayerType = TWidgetLayer|int
  TWidgetType* = enum
    wtImg
  PWidget* = ref object
    `type`* : TWidgetType
    layer*  : TWidgetLayer
    rect*   : TRect
    prim*   : PPrimitive

const
  baseZ = 5000

proc newWidget*(`type`: TWidgetType, layer: TWidgetLayerType, rect: TRect): PWidget =
  new(result)
  result.`type` = `type`
  result.layer = layer
  result.rect = rect

  var verts = newVert(rect)

  # This works because z is accessible at this scope.
  #var z = baseZ + layer.int
  #result.prim = newPrimitive(verts, z=z)

  # Doesn't work, because the compiler looks for a symbol called z in this scope,
  # but it should only check that it is the name of one of the params.
  #result.prim = newPrimitive(verts, z=baseZ + layer.int)

  # This doesn't work either.
  result.prim = newPrimitive(verts, z=0)
