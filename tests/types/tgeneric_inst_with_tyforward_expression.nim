# issue #25651
type
  GeneStatic[DefaultVal: static[auto]] = object
    x: typeof(DefaultVal)

type
  ObjA = GeneStatic[TyForward()]
  ObjA2 = GeneStatic[TyForward(tyFx: 123, tyFy: "XYZ")]
  ObjB = GeneStatic[default(TyForward)]
  ObjC = object
    x: GeneStatic[TyForward()]
    y: GeneStatic[TyForward(tyFx: 456, tyFy: "ABC")]
    z: GeneStatic[default(TyForward)]

  TyForward = object
    tyFx: int
    tyFy = "test val"

doAssert ObjA().DefaultVal == TyForward()
doAssert ObjA2().DefaultVal == TyForward(tyFx: 123, tyFy: "XYZ")
doAssert ObjB().DefaultVal == TyForward()
doAssert ObjC().x.DefaultVal == TyForward()
doAssert ObjC().y.DefaultVal == TyForward(tyFx: 456, tyFy: "ABC")
doAssert ObjC().z.DefaultVal == TyForward()
