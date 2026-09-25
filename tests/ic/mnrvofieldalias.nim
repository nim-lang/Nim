type
  Damage* = object
    kind*: int
    payload*: array[10, int]

  State* = object
    pending*: Damage

proc mergeDamage*(a, b: Damage): Damage =
  if a.kind == 1 or b.kind == 1:
    result = Damage(kind: 1, payload: a.payload)
  elif a.kind == 0:
    result = b
  elif b.kind == 0:
    result = a
  else:
    result = Damage(kind: a.kind + b.kind, payload: a.payload)

proc invalidate*(state: var State; damage: Damage) =
  state.pending = mergeDamage(state.pending, damage)
