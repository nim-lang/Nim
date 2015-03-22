type
  hasFieldX = concept z
    z.x is int

  obj_x = object
    x: int

  ref_obj_x = ref object
    x: int

  ref_to_obj_x = ref obj_x

  p_o_x = ptr obj_x
  v_o_x = var obj_x

template check(x) =
  static: assert(x)

check obj_x is hasFieldX
check ref_obj_x is hasFieldX
check ref_to_obj_x is hasFieldX
check p_o_x is hasFieldX
check v_o_x is hasFieldX

