import
  tri_engine/config,
  tri_engine/math/vec

type
  TRect* = tuple[min, size: TV2[TR]]

proc max*(o: TRect): TV2[TR] = o.min + o.size
