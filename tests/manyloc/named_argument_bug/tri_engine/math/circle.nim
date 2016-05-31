import
  ../config,
  vec

type
  TCircle* = tuple[p: TV2[TR], r: TR]

converter toCircle*(o: TR): TCircle =
  (newV2(), o)
