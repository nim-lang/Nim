discard """
  matrix: "--mm:refc; --mm:refc -d:release"
  ccodecheck: "\\i @('nimZeroMem(((void*) ((&colontmpD_)))')"
  valgrind: "leaks"
  output: '''
true 1
false 2
'''
"""

# bug #26600: the temporary of a value producing 'if' is passed as the result
# of a call. With refc the callee resets that result before it writes to it,
# so the temporary must be initialized

type
  Res[T, E] = object
    case ok: bool
    of false:
      err: E
    of true:
      val: T

template err[T, E](R: type Res[T, E], x: untyped): R =
  R(ok: false, err: x)

template err(v: auto): auto =
  err(typeof(result), v)

func mapErr[T, E0, E1](self: Res[T, E0], f: proc(x: E0): E1): Res[T, E1] {.
    inline, effectsOf: f.} =
  case self.ok
  of true:
    result = Res[T, E1](ok: true, val: self.val)
  of false:
    result = Res[T, E1](ok: false, err: f(self.err))

proc parse(flag: bool): Res[seq[byte], cstring] =
  if flag:
    Res[seq[byte], cstring](ok: true, val: @[1'u8])
  else:
    Res[seq[byte], cstring](ok: false, err: "bad")

proc check(flag, ok: bool): Res[seq[byte], int] =
  if not flag:
    err(1)
  else:
    parse(ok).mapErr(proc(x: cstring): int = 2)

proc fill() {.noinline.} =
  # dirties the stack that `check` uses for its temporary
  var b: array[512, byte]
  for i in 0 ..< b.len: b[i] = 0x01
  doAssert b[17] == 0x01

proc main() =
  fill()
  let a = check(true, true)
  echo a.ok, " ", a.val.len
  fill()
  let b = check(true, false)
  echo b.ok, " ", b.err

main()
