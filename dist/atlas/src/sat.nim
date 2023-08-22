## SAT solver
## (c) 2021 Andreas Rumpf
## Based on explanations and Haskell code from
## https://andrew.gibiansky.com/blog/verification/writing-a-sat-solver/

## Formulars as packed ASTs, no pointers no cry. Solves formulars with many
## thousands of variables in no time.

type
  FormKind* = enum
    FalseForm, TrueForm, VarForm, NotForm, AndForm, OrForm, ExactlyOneOfForm # roughly 8 so the last 3 bits
  BaseType = int32
  Atom = distinct BaseType
  VarId* = distinct BaseType
  Formular* = seq[Atom] # linear storage

proc `==`*(a, b: VarId): bool {.borrow.}

const
  KindBits = 3
  KindMask = 0b111

template kind(a: Atom): FormKind = FormKind(BaseType(a) and KindMask)
template intVal(a: Atom): BaseType = BaseType(a) shr KindBits

proc newVar*(val: VarId): Atom {.inline.} =
  Atom((BaseType(val) shl KindBits) or BaseType(VarForm))

proc newOperation(k: FormKind; val: BaseType): Atom {.inline.} =
  Atom((val shl KindBits) or BaseType(k))

proc trueLit(): Atom {.inline.} = Atom(TrueForm)
proc falseLit(): Atom {.inline.} = Atom(FalseForm)

proc lit(k: FormKind): Atom {.inline.} = Atom(k)

when false:
  proc isTrueLit(a: Atom): bool {.inline.} = a.kind == TrueForm
  proc isFalseLit(a: Atom): bool {.inline.} = a.kind == FalseForm

proc varId(a: Atom): VarId =
  assert a.kind == VarForm
  result = VarId(BaseType(a) shr KindBits)

type
  PatchPos = distinct int
  FormPos = distinct int

proc prepare(dest: var Formular; source: Formular; sourcePos: FormPos): PatchPos =
  result = PatchPos dest.len
  dest.add source[sourcePos.int]

proc patch(f: var Formular; pos: PatchPos) =
  let pos = pos.int
  let k = f[pos].kind
  assert k > VarForm
  let distance = int32(f.len - pos)
  f[pos] = newOperation(k, distance)

proc nextChild(f: Formular; pos: var int) {.inline.} =
  let x = f[int pos]
  pos += (if x.kind <= VarForm: 1 else: int(intVal(x)))

iterator sonsReadonly(f: Formular; n: FormPos): FormPos =
  var pos = n.int
  assert f[pos].kind > VarForm
  let last = pos + f[pos].intVal
  inc pos
  while pos < last:
    yield FormPos pos
    nextChild f, pos

iterator sons(dest: var Formular; source: Formular; n: FormPos): FormPos =
  let patchPos = prepare(dest, source, n)
  for x in sonsReadonly(source, n): yield x
  patch dest, patchPos

# String representation

proc toString(dest: var string; f: Formular; n: FormPos; varRepr: proc (dest: var string; i: int)) =
  assert n.int >= 0
  assert n.int < f.len
  case f[n.int].kind
  of FalseForm: dest.add 'F'
  of TrueForm: dest.add 'T'
  of VarForm:
    varRepr dest, varId(f[n.int]).int
  else:
    case f[n.int].kind
    of AndForm:
      dest.add "(&"
    of OrForm:
      dest.add "(|"
    of ExactlyOneOfForm:
      dest.add "(1=="
    of NotForm:
      dest.add "(~"
    else: assert false, "cannot happen"
    for child in sonsReadonly(f, n):
      toString(dest, f, child, varRepr)
      dest.add ' '
    dest[^1] = ')'

proc `$`*(f: Formular): string =
  assert f.len > 0
  toString(result, f, FormPos 0, proc (dest: var string; x: int) =
    dest.add 'v'
    dest.addInt x
  )

proc `$`*(f: Formular; varRepr: proc (dest: var string; i: int)): string =
  assert f.len > 0
  toString(result, f, FormPos 0, varRepr)

type
  Builder* = object
    f: Formular
    toPatch: seq[PatchPos]

proc isEmpty*(b: Builder): bool {.inline.} =
  b.f.len == 0 or b.f.len == 1 and b.f[0].kind in {NotForm, AndForm, OrForm, ExactlyOneOfForm}

proc openOpr*(b: var Builder; k: FormKind) =
  b.toPatch.add PatchPos b.f.len
  b.f.add newOperation(k, 0)

proc add*(b: var Builder; a: Atom) =
  b.f.add a

proc closeOpr*(b: var Builder) =
  patch(b.f, b.toPatch.pop())

proc deleteLastNode*(b: var Builder) =
  b.f.setLen b.f.len - 1

type
  BuilderPos* = distinct int

proc rememberPos*(b: Builder): BuilderPos {.inline.} = BuilderPos b.f.len
proc rewind*(b: var Builder; pos: BuilderPos) {.inline.} = setLen b.f, int(pos)

proc toForm*(b: var Builder): Formular =
  assert b.toPatch.len == 0, "missing `closeOpr` calls"
  result = move b.f

# Code from the blog translated into Nim and into our representation

const
  NoVar = VarId(-1)

proc freeVariable(f: Formular): VarId =
  ## returns NoVar if there is no free variable.
  for i in 0..<f.len:
    if f[i].kind == VarForm: return varId(f[i])
  return NoVar

type
  BindingKind* = enum
    dontCare,
    setToFalse,
    setToTrue
  Solution* = seq[BindingKind]

proc simplify(dest: var Formular; source: Formular; n: FormPos; sol: Solution): FormKind =
  ## Returns either a Const constructor or a simplified expression;
  ## if the result is not a Const constructor, it guarantees that there
  ## are no Const constructors in the source tree further down.
  let s = source[n.int]
  result = s.kind
  case result
  of FalseForm, TrueForm:
    # nothing interesting to do:
    dest.add s
  of VarForm:
    let v = varId(s).int
    if v < sol.len:
      case sol[v]
      of dontCare:
        dest.add s
      of setToFalse:
        dest.add falseLit()
        result = FalseForm
      of setToTrue:
        dest.add trueLit()
        result = TrueForm
    else:
      dest.add s
  of NotForm:
    let oldLen = dest.len
    var inner: FormKind
    for child in sons(dest, source, n):
      inner = simplify(dest, source, child, sol)
    if inner in {FalseForm, TrueForm}:
      setLen dest, oldLen
      result = (if inner == FalseForm: TrueForm else: FalseForm)
      dest.add lit(result)
  of AndForm, OrForm:
    let (tForm, fForm) = if result == AndForm: (TrueForm, FalseForm)
                         else:                 (FalseForm, TrueForm)

    let initialLen = dest.len
    var childCount = 0
    for child in sons(dest, source, n):
      let oldLen = dest.len

      let inner = simplify(dest, source, child, sol)
      # ignore 'and T' or 'or F' subexpressions:
      if inner == tForm:
        setLen dest, oldLen
      elif inner == fForm:
        # 'and F' is always false and 'or T' is always true:
        result = fForm
        break
      else:
        inc childCount

    if result == fForm:
      setLen dest, initialLen
      dest.add lit(result)
    elif childCount == 1:
      for i in initialLen..<dest.len-1:
        dest[i] = dest[i+1]
      setLen dest, dest.len-1
      result = dest[initialLen].kind
    elif childCount == 0:
      # that means all subexpressions where ignored:
      setLen dest, initialLen
      result = tForm
      dest.add lit(result)
  of ExactlyOneOfForm:
    let initialLen = dest.len
    var childCount = 0
    var couldEval = 0
    for child in sons(dest, source, n):
      let oldLen = dest.len

      let inner = simplify(dest, source, child, sol)
      # ignore 'exactlyOneOf F' subexpressions:
      if inner == FalseForm:
        setLen dest, oldLen
      else:
        if inner == TrueForm:
          inc couldEval
        inc childCount

    if couldEval == childCount:
      setLen dest, initialLen
      if couldEval != 1:
        dest.add lit FalseForm
      else:
        dest.add lit TrueForm
    elif childCount == 1:
      for i in initialLen..<dest.len-1:
        dest[i] = dest[i+1]
      setLen dest, dest.len-1
      result = dest[initialLen].kind

proc satisfiable*(f: Formular; s: var Solution): bool =
  let v = freeVariable(f)
  if v == NoVar:
    result = f[0].kind == TrueForm
  else:
    result = false
    # We have a variable to guess.
    # Construct the two guesses.
    # Return whether either one of them works.
    if v.int >= s.len: s.setLen v.int+1
    # try `setToFalse` first so that we don't end up with unnecessary dependencies:
    s[v.int] = setToFalse

    var falseGuess: Formular
    let res = simplify(falseGuess, f, FormPos 0, s)

    if res == TrueForm:
      result = true
    else:
      result = satisfiable(falseGuess, s)
      if not result:
        s[v.int] = setToTrue

        var trueGuess: Formular
        let res = simplify(trueGuess, f, FormPos 0, s)

        if res == TrueForm:
          result = true
        else:
          result = satisfiable(trueGuess, s)
          if not result:
            # heuristic that provides a solution that comes closest to the "real" conflict:
            s[v.int] = if trueGuess.len <= falseGuess.len: setToFalse else: setToTrue

when isMainModule:
  proc main =
    var b: Builder
    b.openOpr(AndForm)

    b.openOpr(OrForm)
    b.add newVar(VarId 1)
    b.add newVar(VarId 2)
    b.add newVar(VarId 3)
    b.add newVar(VarId 4)
    b.closeOpr

    b.openOpr(ExactlyOneOfForm)
    b.add newVar(VarId 5)
    b.add newVar(VarId 6)
    b.add newVar(VarId 7)

    #b.openOpr(NotForm)
    b.add newVar(VarId 8)
    #b.closeOpr
    b.closeOpr

    b.add newVar(VarId 5)
    b.add newVar(VarId 6)
    b.closeOpr

    let f = toForm(b)
    echo "original: "
    echo f

    var s: Solution
    echo satisfiable(f, s)
    echo "solution"
    for i in 0..<s.len:
      echo "v", i, " ", s[i]

  main()
