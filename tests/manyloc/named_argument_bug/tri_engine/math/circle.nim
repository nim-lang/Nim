import
  tri_engine/config,
  tri_engine/math/vec

type
  TCircle* = tuple[p: TV2[TR], r: TR]

converter toCircle*(o: TR): TCircle =
  (newV2(), o)
