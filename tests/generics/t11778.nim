discard """
  errormsg: "type mismatch: got <proc (func_data: FitObject[eccentricity.T])> but expected 'FuncProto[FitObject[system.int8]]'"
"""

# bug #11778: no crash for an uninstantiated generic proc passed to a generic param
type
  FuncProto[T] = proc (funcData: T)
  VarStruct[T] = object
    userFunc: FuncProto[T]
    data: T

  FitObject[T] = object
    cluster: T

proc initVarStruct[T, U](data: T, uFunc: U): VarStruct[FitObject[int8]] =
  result = VarStruct[FitObject[int8]](userFunc: uFunc, data: data)

proc eccentricity[T](func_data: FitObject[T]) =
  discard

proc reconstructSingleChip() =
  var fitObject: FitObject[int8]
  var varStruct = initVarStruct(fit_object, eccentricity)
