import
  tri_engine/config,
  tri_engine/math/vec,
  tri_engine/math/circle,
  tri_engine/gfx/gl/primitive,
  tri_engine/gfx/tex,
  tri_engine/gfx/color,
  tri_engine/tri_engine,
  gui

var isRunning = true

block:
  var renderer = newRenderer(w=10, h=10)

  var primitive = newPrimitiveCircle(0.3.TR, color=white(0.5, 0.8), z=15)
  renderer.addPrimitive(primitive)

  var verts = newVert((min: newV2xy(-0.4), size: newV2xy(0.3)))
  var primitive2 = newPrimitive(verts, color=red(0.5, 0.8), z=10)
  renderer.addPrimitive(primitive2)

  var mainMenuWidget = newWidget(wtImg, wlBg, rect=(newV2xy(-1.0), newV2xy(2.0)))
