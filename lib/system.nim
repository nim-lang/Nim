#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## The compiler depends on the System module to work properly and the System
## module depends on the compiler. Most of the routines listed here use
## special compiler magic.
##
## Each module implicitly imports the System module; it must not be listed
## explicitly. Because of this there cannot be a user-defined module named
## `system`.
##
## System module
## =============
##
## .. include:: ./system_overview.rst


type
  float* {.magic: Float.}     ## Default floating point type.
  float32* {.magic: Float32.} ## 32 bit floating point type.
  float64* {.magic: Float.}   ## 64 bit floating point type.

# 'float64' is now an alias to 'float'; this solves many problems

type
  char* {.magic: Char.}         ## Built-in 8 bit character type (unsigned).
  string* {.magic: String.}     ## Built-in string type.
  cstring* {.magic: Cstring.}   ## Built-in cstring (*compatible string*) type.
  pointer* {.magic: Pointer.}   ## Built-in pointer type, use the `addr`
                                ## operator to get a pointer to a variable.

  typedesc* {.magic: TypeDesc.} ## Meta type to denote a type description.

type
  `ptr`*[T] {.magic: Pointer.}   ## Built-in generic untraced pointer type.
  `ref`*[T] {.magic: Pointer.}   ## Built-in generic traced pointer type.

  `nil` {.magic: "Nil".}

  void* {.magic: "VoidType".}    ## Meta type to denote the absence of any type.
  auto* {.magic: Expr.}          ## Meta type for automatic type determination.
  any* {.deprecated: "Deprecated since v1.5; Use auto instead.".} = distinct auto  ## Deprecated; Use `auto` instead. See https://github.com/nim-lang/RFCs/issues/281
  untyped* {.magic: Expr.}       ## Meta type to denote an expression that
                                 ## is not resolved (for templates).
  typed* {.magic: Stmt.}         ## Meta type to denote an expression that
                                 ## is resolved (for templates).

include "system/basic_types"


proc runnableExamples*(rdoccmd = "", body: untyped) {.magic: "RunnableExamples".} =
  ## A section you should use to mark `runnable example`:idx: code with.
  ##
  ## - In normal debug and release builds code within
  ##   a `runnableExamples` section is ignored.
  ## - The documentation generator is aware of these examples and considers them
  ##   part of the `##` doc comment. As the last step of documentation
  ##   generation each runnableExample is put in its own file `$file_examples$i.nim`,
  ##   compiled and tested. The collected examples are
  ##   put into their own module to ensure the examples do not refer to
  ##   non-exported symbols.
  runnableExamples:
    proc timesTwo*(x: int): int =
      ## This proc doubles a number.
      runnableExamples:
        # at module scope
        const exported* = 123
        assert timesTwo(5) == 10
        block: # at block scope
          defer: echo "done"
      runnableExamples "-d:foo -b:cpp":
        import std/compilesettings
        assert querySetting(backend) == "cpp"
        assert defined(foo)
      runnableExamples "-r:off": ## this one is only compiled
         import std/browsers
         openDefaultBrowser "https://forum.nim-lang.org/"
      2 * x

proc compileOption*(option: string): bool {.
  magic: "CompileOption", noSideEffect.} =
  ## Can be used to determine an `on|off` compile-time option.
  ##
  ## See also:
  ## * `compileOption <#compileOption,string,string>`_ for enum options
  ## * `defined <#defined,untyped>`_
  ## * `std/compilesettings module <compilesettings.html>`_
  runnableExamples("--floatChecks:off"):
    static: doAssert not compileOption("floatchecks")
    {.push floatChecks: on.}
    static: doAssert compileOption("floatchecks")
    # floating point NaN and Inf checks enabled in this scope
    {.pop.}

proc compileOption*(option, arg: string): bool {.
  magic: "CompileOptionArg", noSideEffect.} =
  ## Can be used to determine an enum compile-time option.
  ##
  ## See also:
  ## * `compileOption <#compileOption,string>`_ for `on|off` options
  ## * `defined <#defined,untyped>`_
  ## * `std/compilesettings module <compilesettings.html>`_
  runnableExamples:
    when compileOption("opt", "size") and compileOption("gc", "boehm"):
      discard "compiled with optimization for size and uses Boehm's GC"

{.push warning[GcMem]: off, warning[Uninit]: off.}
# {.push hints: off.}

proc `or`*(a, b: typedesc): typedesc {.magic: "TypeTrait", noSideEffect.}
  ## Constructs an `or` meta class.

proc `and`*(a, b: typedesc): typedesc {.magic: "TypeTrait", noSideEffect.}
  ## Constructs an `and` meta class.

proc `not`*(a: typedesc): typedesc {.magic: "TypeTrait", noSideEffect.}
  ## Constructs an `not` meta class.


type
  SomeFloat* = float|float32|float64
    ## Type class matching all floating point number types.

  SomeNumber* = SomeInteger|SomeFloat
    ## Type class matching all number types.

proc defined*(x: untyped): bool {.magic: "Defined", noSideEffect, compileTime.}
  ## Special compile-time procedure that checks whether `x` is
  ## defined.
  ##
  ## See also:
  ## * `compileOption <#compileOption,string>`_ for `on|off` options
  ## * `compileOption <#compileOption,string,string>`_ for enum options
  ## * `define pragmas <manual.html#implementation-specific-pragmas-compileminustime-define-pragmas>`_
  ##
  ## `x` is an external symbol introduced through the compiler's
  ## `-d:x switch <nimc.html#compiler-usage-compileminustime-symbols>`_ to enable
  ## build time conditionals:
  ##
  ## .. code-block:: Nim
  ##   when not defined(release):
  ##     # Do here programmer friendly expensive sanity checks.
  ##   # Put here the normal code

when defined(nimHasIterable):
  type
    iterable*[T] {.magic: IterableType.}  ## Represents an expression that yields `T`

when defined(nimHashOrdinalFixed):
  type
    Ordinal*[T] {.magic: Ordinal.} ## Generic ordinal type. Includes integer,
                                   ## bool, character, and enumeration types
                                   ## as well as their subtypes. See also
                                   ## `SomeOrdinal`.
else:
  # bootstrap < 1.2.0
  type
    OrdinalImpl[T] {.magic: Ordinal.}
    Ordinal* = OrdinalImpl | uint | uint64

when defined(nimHasDeclaredMagic):
  proc declared*(x: untyped): bool {.magic: "Declared", noSideEffect, compileTime.}
    ## Special compile-time procedure that checks whether `x` is
    ## declared. `x` has to be an identifier or a qualified identifier.
    ##
    ## See also:
    ## * `declaredInScope <#declaredInScope,untyped>`_
    ##
    ## This can be used to check whether a library provides a certain
    ## feature or not:
    ##
    ## .. code-block:: Nim
    ##   when not declared(strutils.toUpper):
    ##     # provide our own toUpper proc here, because strutils is
    ##     # missing it.
else:
  proc declared*(x: untyped): bool {.magic: "Defined", noSideEffect, compileTime.}

when defined(nimHasDeclaredMagic):
  proc declaredInScope*(x: untyped): bool {.magic: "DeclaredInScope", noSideEffect, compileTime.}
    ## Special compile-time procedure that checks whether `x` is
    ## declared in the current scope. `x` has to be an identifier.
else:
  proc declaredInScope*(x: untyped): bool {.magic: "DefinedInScope", noSideEffect, compileTime.}

proc `addr`*[T](x: var T): ptr T {.magic: "Addr", noSideEffect.} =
  ## Builtin `addr` operator for taking the address of a memory location.
  ## Cannot be overloaded.
  ##
  ## See also:
  ## * `unsafeAddr <#unsafeAddr,T>`_
  ##
  ## .. code-block:: Nim
  ##  var
  ##    buf: seq[char] = @['a','b','c']
  ##    p = buf[1].addr
  ##  echo p.repr # ref 0x7faa35c40059 --> 'b'
  ##  echo p[]    # b
  discard

proc unsafeAddr*[T](x: T): ptr T {.magic: "Addr", noSideEffect.} =
  ## Builtin `addr` operator for taking the address of a memory
  ## location. This works even for `let` variables or parameters
  ## for better interop with C and so it is considered even more
  ## unsafe than the ordinary `addr <#addr,T>`_.
  ##
  ## **Note**: When you use it to write a wrapper for a C library, you should
  ## always check that the original library does never write to data behind the
  ## pointer that is returned from this procedure.
  ##
  ## Cannot be overloaded.
  discard

type
  `static`*[T] {.magic: "Static".}
    ## Meta type representing all values that can be evaluated at compile-time.
    ##
    ## The type coercion `static(x)` can be used to force the compile-time
    ## evaluation of the given expression `x`.

  `type`*[T] {.magic: "Type".}
    ## Meta type representing the type of all type values.
    ##
    ## The coercion `type(x)` can be used to obtain the type of the given
    ## expression `x`.

type
  TypeOfMode* = enum ## Possible modes of `typeof`.
    typeOfProc,      ## Prefer the interpretation that means `x` is a proc call.
    typeOfIter       ## Prefer the interpretation that means `x` is an iterator call.

proc typeof*(x: untyped; mode = typeOfIter): typedesc {.
  magic: "TypeOf", noSideEffect, compileTime.} =
  ## Builtin `typeof` operation for accessing the type of an expression.
  ## Since version 0.20.0.
  runnableExamples:
    proc myFoo(): float = 0.0
    iterator myFoo(): string = yield "abc"
    iterator myFoo2(): string = yield "abc"
    iterator myFoo3(): string {.closure.} = yield "abc"
    doAssert type(myFoo()) is string
    doAssert typeof(myFoo()) is string
    doAssert typeof(myFoo(), typeOfIter) is string
    doAssert typeof(myFoo3) is "iterator"

    doAssert typeof(myFoo(), typeOfProc) is float
    doAssert typeof(0.0, typeOfProc) is float
    doAssert typeof(myFoo3, typeOfProc) is "iterator"
    doAssert not compiles(typeof(myFoo2(), typeOfProc))
      # this would give: Error: attempting to call routine: 'myFoo2'
      # since `typeOfProc` expects a typed expression and `myFoo2()` can
      # only be used in a `for` context.

const ThisIsSystem = true

proc internalNew*[T](a: var ref T) {.magic: "New", noSideEffect.}
  ## Leaked implementation detail. Do not use.

when true:
  proc new*[T](a: var ref T, finalizer: proc (x: ref T) {.nimcall.}) {.
    magic: "NewFinalize", noSideEffect.}
    ## Creates a new object of type `T` and returns a safe (traced)
    ## reference to it in `a`.
    ##
    ## When the garbage collector frees the object, `finalizer` is called.
    ## The `finalizer` may not keep a reference to the
    ## object pointed to by `x`. The `finalizer` cannot prevent the GC from
    ## freeing the object.
    ##
    ## **Note**: The `finalizer` refers to the type `T`, not to the object!
    ## This means that for each object of type `T` the finalizer will be called!

proc wasMoved*[T](obj: var T) {.magic: "WasMoved", noSideEffect.} =
  ## Resets an object `obj` to its initial (binary zero) value to signify
  ## it was "moved" and to signify its destructor should do nothing and
  ## ideally be optimized away.
  discard

proc move*[T](x: var T): T {.magic: "Move", noSideEffect.} =
  result = x
  wasMoved(x)

type
  range*[T]{.magic: "Range".}         ## Generic type to construct range types.
  array*[I, T]{.magic: "Array".}      ## Generic type to construct
                                      ## fixed-length arrays.
  openArray*[T]{.magic: "OpenArray".} ## Generic type to construct open arrays.
                                      ## Open arrays are implemented as a
                                      ## pointer to the array data and a
                                      ## length field.
  varargs*[T]{.magic: "Varargs".}     ## Generic type to construct a varargs type.
  seq*[T]{.magic: "Seq".}             ## Generic type to construct sequences.
  set*[T]{.magic: "Set".}             ## Generic type to construct bit sets.

type
  UncheckedArray*[T]{.magic: "UncheckedArray".}
  ## Array with no bounds checking.

type sink*[T]{.magic: "BuiltinType".}
type lent*[T]{.magic: "BuiltinType".}

proc high*[T: Ordinal|enum|range](x: T): T {.magic: "High", noSideEffect,
  deprecated: "Deprecated since v1.4; there should not be `high(value)`. Use `high(type)`.".}
  ## Returns the highest possible value of an ordinal value `x`.
  ##
  ## As a special semantic rule, `x` may also be a type identifier.
  ##
  ## **This proc is deprecated**, use this one instead:
  ## * `high(typedesc) <#high,typedesc[T]>`_
  ##
  ## .. code-block:: Nim
  ##  high(2) # => 9223372036854775807

proc high*[T: Ordinal|enum|range](x: typedesc[T]): T {.magic: "High", noSideEffect.}
  ## Returns the highest possible value of an ordinal or enum type.
  ##
  ## `high(int)` is Nim's way of writing `INT_MAX`:idx: or `MAX_INT`:idx:.
  ##
  ## See also:
  ## * `low(typedesc) <#low,typedesc[T]>`_
  ##
  ## .. code-block:: Nim
  ##  high(int) # => 9223372036854775807

proc high*[T](x: openArray[T]): int {.magic: "High", noSideEffect.}
  ## Returns the highest possible index of a sequence `x`.
  ##
  ## See also:
  ## * `low(openArray) <#low,openArray[T]>`_
  ##
  ## .. code-block:: Nim
  ##  var s = @[1, 2, 3, 4, 5, 6, 7]
  ##  high(s) # => 6
  ##  for i in low(s)..high(s):
  ##    echo s[i]

proc high*[I, T](x: array[I, T]): I {.magic: "High", noSideEffect.}
  ## Returns the highest possible index of an array `x`.
  ##
  ## For empty arrays, the return type is `int`.
  ##
  ## See also:
  ## * `low(array) <#low,array[I,T]>`_
  ##
  ## .. code-block:: Nim
  ##  var arr = [1, 2, 3, 4, 5, 6, 7]
  ##  high(arr) # => 6
  ##  for i in low(arr)..high(arr):
  ##    echo arr[i]

proc high*[I, T](x: typedesc[array[I, T]]): I {.magic: "High", noSideEffect.}
  ## Returns the highest possible index of an array type.
  ##
  ## For empty arrays, the return type is `int`.
  ##
  ## See also:
  ## * `low(typedesc[array]) <#low,typedesc[array[I,T]]>`_
  ##
  ## .. code-block:: Nim
  ##  high(array[7, int]) # => 6

proc high*(x: cstring): int {.magic: "High", noSideEffect.}
  ## Returns the highest possible index of a compatible string `x`.
  ## This is sometimes an O(n) operation.
  ##
  ## See also:
  ## * `low(cstring) <#low,cstring>`_

proc high*(x: string): int {.magic: "High", noSideEffect.}
  ## Returns the highest possible index of a string `x`.
  ##
  ## See also:
  ## * `low(string) <#low,string>`_
  ##
  ## .. code-block:: Nim
  ##  var str = "Hello world!"
  ##  high(str) # => 11

proc low*[T: Ordinal|enum|range](x: T): T {.magic: "Low", noSideEffect,
  deprecated: "Deprecated since v1.4; there should not be `low(value)`. Use `low(type)`.".}
  ## Returns the lowest possible value of an ordinal value `x`. As a special
  ## semantic rule, `x` may also be a type identifier.
  ##
  ## **This proc is deprecated**, use this one instead:
  ## * `low(typedesc) <#low,typedesc[T]>`_
  ##
  ## .. code-block:: Nim
  ##  low(2) # => -9223372036854775808

proc low*[T: Ordinal|enum|range](x: typedesc[T]): T {.magic: "Low", noSideEffect.}
  ## Returns the lowest possible value of an ordinal or enum type.
  ##
  ## `low(int)` is Nim's way of writing `INT_MIN`:idx: or `MIN_INT`:idx:.
  ##
  ## See also:
  ## * `high(typedesc) <#high,typedesc[T]>`_
  ##
  ## .. code-block:: Nim
  ##  low(int) # => -9223372036854775808

proc low*[T](x: openArray[T]): int {.magic: "Low", noSideEffect.}
  ## Returns the lowest possible index of a sequence `x`.
  ##
  ## See also:
  ## * `high(openArray) <#high,openArray[T]>`_
  ##
  ## .. code-block:: Nim
  ##  var s = @[1, 2, 3, 4, 5, 6, 7]
  ##  low(s) # => 0
  ##  for i in low(s)..high(s):
  ##    echo s[i]

proc low*[I, T](x: array[I, T]): I {.magic: "Low", noSideEffect.}
  ## Returns the lowest possible index of an array `x`.
  ##
  ## For empty arrays, the return type is `int`.
  ##
  ## See also:
  ## * `high(array) <#high,array[I,T]>`_
  ##
  ## .. code-block:: Nim
  ##  var arr = [1, 2, 3, 4, 5, 6, 7]
  ##  low(arr) # => 0
  ##  for i in low(arr)..high(arr):
  ##    echo arr[i]

proc low*[I, T](x: typedesc[array[I, T]]): I {.magic: "Low", noSideEffect.}
  ## Returns the lowest possible index of an array type.
  ##
  ## For empty arrays, the return type is `int`.
  ##
  ## See also:
  ## * `high(typedesc[array]) <#high,typedesc[array[I,T]]>`_
  ##
  ## .. code-block:: Nim
  ##  low(array[7, int]) # => 0

proc low*(x: cstring): int {.magic: "Low", noSideEffect.}
  ## Returns the lowest possible index of a compatible string `x`.
  ##
  ## See also:
  ## * `high(cstring) <#high,cstring>`_

proc low*(x: string): int {.magic: "Low", noSideEffect.}
  ## Returns the lowest possible index of a string `x`.
  ##
  ## See also:
  ## * `high(string) <#high,string>`_
  ##
  ## .. code-block:: Nim
  ##  var str = "Hello world!"
  ##  low(str) # => 0

proc shallowCopy*[T](x: var T, y: T) {.noSideEffect, magic: "ShallowCopy".}
  ## Use this instead of `=` for a `shallow copy`:idx:.
  ##
  ## The shallow copy only changes the semantics for sequences and strings
  ## (and types which contain those).
  ##
  ## Be careful with the changed semantics though!
  ## There is a reason why the default assignment does a deep copy of sequences
  ## and strings.

# :array|openArray|string|seq|cstring|tuple
proc `[]`*[I: Ordinal;T](a: T; i: I): T {.
  noSideEffect, magic: "ArrGet".}
proc `[]=`*[I: Ordinal;T,S](a: T; i: I;
  x: sink S) {.noSideEffect, magic: "ArrPut".}
proc `=`*[T](dest: var T; src: T) {.noSideEffect, magic: "Asgn".}
proc `=copy`*[T](dest: var T; src: T) {.noSideEffect, magic: "Asgn".}

proc arrGet[I: Ordinal;T](a: T; i: I): T {.
  noSideEffect, magic: "ArrGet".}
proc arrPut[I: Ordinal;T,S](a: T; i: I;
  x: S) {.noSideEffect, magic: "ArrPut".}

proc `=destroy`*[T](x: var T) {.inline, magic: "Destroy".} =
  ## Generic `destructor`:idx: implementation that can be overridden.
  discard
proc `=sink`*[T](x: var T; y: T) {.inline, magic: "Asgn".} =
  ## Generic `sink`:idx: implementation that can be overridden.
  shallowCopy(x, y)

when defined(nimHasTrace):
  proc `=trace`*[T](x: var T; env: pointer) {.inline, magic: "Trace".} =
    ## Generic `trace`:idx: implementation that can be overridden.
    discard

type
  HSlice*[T, U] = object   ## "Heterogeneous" slice type.
    a*: T                  ## The lower bound (inclusive).
    b*: U                  ## The upper bound (inclusive).
  Slice*[T] = HSlice[T, T] ## An alias for `HSlice[T, T]`.

proc `..`*[T, U](a: sink T, b: sink U): HSlice[T, U] {.noSideEffect, inline, magic: "DotDot".} =
  ## Binary `slice`:idx: operator that constructs an interval `[a, b]`, both `a`
  ## and `b` are inclusive.
  ##
  ## Slices can also be used in the set constructor and in ordinal case
  ## statements, but then they are special-cased by the compiler.
  ##
  ## .. code-block:: Nim
  ##   let a = [10, 20, 30, 40, 50]
  ##   echo a[2 .. 3] # @[30, 40]
  result = HSlice[T, U](a: a, b: b)

proc `..`*[T](b: sink T): HSlice[int, T]
  {.noSideEffect, inline, magic: "DotDot", deprecated: "replace `..b` with `0..b`".} =
  ## Unary `slice`:idx: operator that constructs an interval `[default(int), b]`.
  ##
  ## .. code-block:: Nim
  ##   let a = [10, 20, 30, 40, 50]
  ##   echo a[.. 2] # @[10, 20, 30]
  result = HSlice[int, T](a: 0, b: b)

when defined(hotCodeReloading):
  {.pragma: hcrInline, inline.}
else:
  {.pragma: hcrInline.}

{.push profiler: off.}
let nimvm* {.magic: "Nimvm", compileTime.}: bool = false
  ## May be used only in `when` expression.
  ## It is true in Nim VM context and false otherwise.
{.pop.}

include "system/arithmetics"
include "system/comparisons"

const
  appType* {.magic: "AppType".}: string = ""
    ## A string that describes the application type. Possible values:
    ## `"console"`, `"gui"`, `"lib"`.

include "system/inclrtl"

const NoFakeVars = defined(nimscript) ## `true` if the backend doesn't support \
  ## "fake variables" like `var EBADF {.importc.}: cint`.

const notJSnotNims = not defined(js) and not defined(nimscript)

when not defined(js) and not defined(nimSeqsV2):
  type
    TGenericSeq {.compilerproc, pure, inheritable.} = object
      len, reserved: int
      when defined(gogc):
        elemSize: int
        elemAlign: int
    PGenericSeq {.exportc.} = ptr TGenericSeq
    # len and space without counting the terminating zero:
    NimStringDesc {.compilerproc, final.} = object of TGenericSeq
      data: UncheckedArray[char]
    NimString = ptr NimStringDesc

when notJSnotNims and not defined(nimSeqsV2):
  template space(s: PGenericSeq): int {.dirty.} =
    s.reserved and not (seqShallowFlag or strlitFlag)

when notJSnotNims:
  include "system/hti"

type
  byte* = uint8 ## This is an alias for `uint8`, that is an unsigned
                ## integer, 8 bits wide.

  Natural* = range[0..high(int)]
    ## is an `int` type ranging from zero to the maximum value
    ## of an `int`. This type is often useful for documentation and debugging.

  Positive* = range[1..high(int)]
    ## is an `int` type ranging from one to the maximum value
    ## of an `int`. This type is often useful for documentation and debugging.

  RootObj* {.compilerproc, inheritable.} =
    object ## The root of Nim's object hierarchy.
           ##
           ## Objects should inherit from `RootObj` or one of its descendants.
           ## However, objects that have no ancestor are also allowed.
  RootRef* = ref RootObj ## Reference to `RootObj`.


include "system/exceptions"

when defined(js) or defined(nimdoc):
  type
    JsRoot* = ref object of RootObj
      ## Root type of the JavaScript object hierarchy

proc unsafeNew*[T](a: var ref T, size: Natural) {.magic: "New", noSideEffect.}
  ## Creates a new object of type `T` and returns a safe (traced)
  ## reference to it in `a`.
  ##
  ## This is **unsafe** as it allocates an object of the passed `size`.
  ## This should only be used for optimization purposes when you know
  ## what you're doing!
  ##
  ## See also:
  ## * `new <#new,ref.T,proc(ref.T)>`_

proc sizeof*[T](x: T): int {.magic: "SizeOf", noSideEffect.}
  ## Returns the size of `x` in bytes.
  ##
  ## Since this is a low-level proc,
  ## its usage is discouraged - using `new <#new,ref.T,proc(ref.T)>`_ for
  ## the most cases suffices that one never needs to know `x`'s size.
  ##
  ## As a special semantic rule, `x` may also be a type identifier
  ## (`sizeof(int)` is valid).
  ##
  ## Limitations: If used for types that are imported from C or C++,
  ## sizeof should fallback to the `sizeof` in the C compiler. The
  ## result isn't available for the Nim compiler and therefore can't
  ## be used inside of macros.
  ##
  ## .. code-block:: Nim
  ##  sizeof('A') # => 1
  ##  sizeof(2) # => 8

proc alignof*[T](x: T): int {.magic: "AlignOf", noSideEffect.}
proc alignof*(x: typedesc): int {.magic: "AlignOf", noSideEffect.}

proc offsetOfDotExpr(typeAccess: typed): int {.magic: "OffsetOf", noSideEffect, compileTime.}

template offsetOf*[T](t: typedesc[T]; member: untyped): int =
  var tmp {.noinit.}: ptr T
  offsetOfDotExpr(tmp[].member)

template offsetOf*[T](value: T; member: untyped): int =
  offsetOfDotExpr(value.member)

#proc offsetOf*(memberaccess: typed): int {.magic: "OffsetOf", noSideEffect.}

proc sizeof*(x: typedesc): int {.magic: "SizeOf", noSideEffect.}


proc newSeq*[T](s: var seq[T], len: Natural) {.magic: "NewSeq", noSideEffect.}
  ## Creates a new sequence of type `seq[T]` with length `len`.
  ##
  ## This is equivalent to `s = @[]; setlen(s, len)`, but more
  ## efficient since no reallocation is needed.
  ##
  ## Note that the sequence will be filled with zeroed entries.
  ## After the creation of the sequence you should assign entries to
  ## the sequence instead of adding them. Example:
  ##
  ## .. code-block:: Nim
  ##   var inputStrings: seq[string]
  ##   newSeq(inputStrings, 3)
  ##   assert len(inputStrings) == 3
  ##   inputStrings[0] = "The fourth"
  ##   inputStrings[1] = "assignment"
  ##   inputStrings[2] = "would crash"
  ##   #inputStrings[3] = "out of bounds"

proc newSeq*[T](len = 0.Natural): seq[T] =
  ## Creates a new sequence of type `seq[T]` with length `len`.
  ##
  ## Note that the sequence will be filled with zeroed entries.
  ## After the creation of the sequence you should assign entries to
  ## the sequence instead of adding them.
  ##
  ## See also:
  ## * `newSeqOfCap <#newSeqOfCap,Natural>`_
  ## * `newSeqUninitialized <#newSeqUninitialized,Natural>`_
  ##
  ## .. code-block:: Nim
  ##   var inputStrings = newSeq[string](3)
  ##   assert len(inputStrings) == 3
  ##   inputStrings[0] = "The fourth"
  ##   inputStrings[1] = "assignment"
  ##   inputStrings[2] = "would crash"
  ##   #inputStrings[3] = "out of bounds"
  newSeq(result, len)

proc newSeqOfCap*[T](cap: Natural): seq[T] {.
  magic: "NewSeqOfCap", noSideEffect.} =
  ## Creates a new sequence of type `seq[T]` with length zero and capacity
  ## `cap`.
  ##
  ## .. code-block:: Nim
  ##   var x = newSeqOfCap[int](5)
  ##   assert len(x) == 0
  ##   x.add(10)
  ##   assert len(x) == 1
  discard

when not defined(js):
  proc newSeqUninitialized*[T: SomeNumber](len: Natural): seq[T] =
    ## Creates a new sequence of type `seq[T]` with length `len`.
    ##
    ## Only available for numbers types. Note that the sequence will be
    ## uninitialized. After the creation of the sequence you should assign
    ## entries to the sequence instead of adding them.
    ##
    ## .. code-block:: Nim
    ##   var x = newSeqUninitialized[int](3)
    ##   assert len(x) == 3
    ##   x[0] = 10
    result = newSeqOfCap[T](len)
    when defined(nimSeqsV2):
      cast[ptr int](addr result)[] = len
    else:
      var s = cast[PGenericSeq](result)
      s.len = len

func len*[TOpenArray: openArray|varargs](x: TOpenArray): int {.magic: "LengthOpenArray".} =
  ## Returns the length of an openArray.
  runnableExamples:
    proc bar[T](a: openArray[T]): int = len(a)
    assert bar([1,2]) == 2
    assert [1,2].len == 2

func len*(x: string): int {.magic: "LengthStr".} =
  ## Returns the length of a string.
  runnableExamples:
    assert "abc".len == 3
    assert "".len == 0
    assert string.default.len == 0

proc len*(x: cstring): int {.magic: "LengthStr", noSideEffect.} =
  ## Returns the length of a compatible string. This is an O(n) operation except
  ## in js at runtime.
  ##
  ## **Note:** On the JS backend this currently counts UTF-16 code points
  ## instead of bytes at runtime (not at compile time). For now, if you
  ## need the byte length of the UTF-8 encoding, convert to string with
  ## `$` first then call `len`.
  runnableExamples:
    doAssert len(cstring"abc") == 3
    doAssert len(cstring r"ab\0c") == 5 # \0 is escaped
    doAssert len(cstring"ab\0c") == 5 # ditto
    var a: cstring = "ab\0c"
    when defined(js): doAssert a.len == 4 # len ignores \0 for js
    else: doAssert a.len == 2 # \0 is a null terminator
    static:
      var a2: cstring = "ab\0c"
      doAssert a2.len == 2 # \0 is a null terminator, even in js vm

func len*(x: (type array)|array): int {.magic: "LengthArray".} =
  ## Returns the length of an array or an array type.
  ## This is roughly the same as `high(T)-low(T)+1`.
  runnableExamples:
    var a = [1, 1, 1]
    assert a.len == 3
    assert array[0, float].len == 0
    static: assert array[-2..2, float].len == 5

func len*[T](x: seq[T]): int {.magic: "LengthSeq".} =
  ## Returns the length of `x`.
  runnableExamples:
    assert @[0, 1].len == 2
    assert seq[int].default.len == 0
    assert newSeq[int](3).len == 3
    let s = newSeqOfCap[int](3)
    assert s.len == 0
  # xxx this gives cgen error: assert newSeqOfCap[int](3).len == 0

func ord*[T: Ordinal|enum](x: T): int {.magic: "Ord".} =
  ## Returns the internal `int` value of `x`, including for enum with holes
  ## and distinct ordinal types.
  runnableExamples:
    assert ord('A') == 65
    type Foo = enum
      f0 = 0, f1 = 3
    assert f1.ord == 3
    type Bar = distinct int
    assert 3.Bar.ord == 3

func chr*(u: range[0..255]): char {.magic: "Chr".} =
  ## Converts `u` to a `char`, same as `char(u)`.
  runnableExamples:
    doAssert chr(65) == 'A'
    doAssert chr(255) == '\255'
    doAssert chr(255) == char(255)
    doAssert not compiles chr(256)
    doAssert not compiles char(256)
    var x = 256
    doAssertRaises(RangeDefect): discard chr(x)
    doAssertRaises(RangeDefect): discard char(x)

# floating point operations:
proc `+`*(x: float32): float32 {.magic: "UnaryPlusF64", noSideEffect.}
proc `-`*(x: float32): float32 {.magic: "UnaryMinusF64", noSideEffect.}
proc `+`*(x, y: float32): float32 {.magic: "AddF64", noSideEffect.}
proc `-`*(x, y: float32): float32 {.magic: "SubF64", noSideEffect.}
proc `*`*(x, y: float32): float32 {.magic: "MulF64", noSideEffect.}
proc `/`*(x, y: float32): float32 {.magic: "DivF64", noSideEffect.}

proc `+`*(x: float): float {.magic: "UnaryPlusF64", noSideEffect.}
proc `-`*(x: float): float {.magic: "UnaryMinusF64", noSideEffect.}
proc `+`*(x, y: float): float {.magic: "AddF64", noSideEffect.}
proc `-`*(x, y: float): float {.magic: "SubF64", noSideEffect.}
proc `*`*(x, y: float): float {.magic: "MulF64", noSideEffect.}
proc `/`*(x, y: float): float {.magic: "DivF64", noSideEffect.}

proc `==`*(x, y: float32): bool {.magic: "EqF64", noSideEffect.}
proc `<=`*(x, y: float32): bool {.magic: "LeF64", noSideEffect.}
proc `<`  *(x, y: float32): bool {.magic: "LtF64", noSideEffect.}

proc `==`*(x, y: float): bool {.magic: "EqF64", noSideEffect.}
proc `<=`*(x, y: float): bool {.magic: "LeF64", noSideEffect.}
proc `<`*(x, y: float): bool {.magic: "LtF64", noSideEffect.}


include "system/setops"


proc contains*[U, V, W](s: HSlice[U, V], value: W): bool {.noSideEffect, inline.} =
  ## Checks if `value` is within the range of `s`; returns true if
  ## `value >= s.a and value <= s.b`
  ##
  ## .. code-block:: Nim
  ##   assert((1..3).contains(1) == true)
  ##   assert((1..3).contains(2) == true)
  ##   assert((1..3).contains(4) == false)
  result = s.a <= value and value <= s.b

template `in`*(x, y: untyped): untyped {.dirty.} = contains(y, x)
  ## Sugar for `contains`.
  ##
  ## .. code-block:: Nim
  ##   assert(1 in (1..3) == true)
  ##   assert(5 in (1..3) == false)
template `notin`*(x, y: untyped): untyped {.dirty.} = not contains(y, x)
  ## Sugar for `not contains`.
  ##
  ## .. code-block:: Nim
  ##   assert(1 notin (1..3) == false)
  ##   assert(5 notin (1..3) == true)

proc `is`*[T, S](x: T, y: S): bool {.magic: "Is", noSideEffect.}
  ## Checks if `T` is of the same type as `S`.
  ##
  ## For a negated version, use `isnot <#isnot.t,untyped,untyped>`_.
  ##
  ## .. code-block:: Nim
  ##   assert 42 is int
  ##   assert @[1, 2] is seq
  ##
  ##   proc test[T](a: T): int =
  ##     when (T is int):
  ##       return a
  ##     else:
  ##       return 0
  ##
  ##   assert(test[int](3) == 3)
  ##   assert(test[string]("xyz") == 0)
template `isnot`*(x, y: untyped): untyped = not (x is y)
  ## Negated version of `is <#is,T,S>`_. Equivalent to `not(x is y)`.
  ##
  ## .. code-block:: Nim
  ##   assert 42 isnot float
  ##   assert @[1, 2] isnot enum

when (defined(nimOwnedEnabled) and not defined(nimscript)) or defined(nimFixedOwned):
  type owned*[T]{.magic: "BuiltinType".} ## type constructor to mark a ref/ptr or a closure as `owned`.
else:
  template owned*(t: typedesc): typedesc = t

when defined(nimOwnedEnabled) and not defined(nimscript):
  proc new*[T](a: var owned(ref T)) {.magic: "New", noSideEffect.}
    ## Creates a new object of type `T` and returns a safe (traced)
    ## reference to it in `a`.

  proc new*(t: typedesc): auto =
    ## Creates a new object of type `T` and returns a safe (traced)
    ## reference to it as result value.
    ##
    ## When `T` is a ref type then the resulting type will be `T`,
    ## otherwise it will be `ref T`.
    when (t is ref):
      var r: owned t
    else:
      var r: owned(ref t)
    new(r)
    return r

  proc unown*[T](x: T): T {.magic: "Unown", noSideEffect.}
    ## Use the expression `x` ignoring its ownership attribute.


else:
  template unown*(x: typed): untyped = x

  proc new*[T](a: var ref T) {.magic: "New", noSideEffect.}
    ## Creates a new object of type `T` and returns a safe (traced)
    ## reference to it in `a`.

  proc new*(t: typedesc): auto =
    ## Creates a new object of type `T` and returns a safe (traced)
    ## reference to it as result value.
    ##
    ## When `T` is a ref type then the resulting type will be `T`,
    ## otherwise it will be `ref T`.
    when (t is ref):
      var r: t
    else:
      var r: ref t
    new(r)
    return r


template disarm*(x: typed) =
  ## Useful for `disarming` dangling pointers explicitly for `--newruntime`.
  ## Regardless of whether `--newruntime` is used or not
  ## this sets the pointer or callback `x` to `nil`. This is an
  ## experimental API!
  x = nil

proc `of`*[T, S](x: T, y: typedesc[S]): bool {.magic: "Of", noSideEffect.} =
  ## Checks if `x` is an instance of `y`.
  runnableExamples:
    type
      Base = ref object of RootObj
      Sub1 = ref object of Base
      Sub2 = ref object of Base
      Unrelated = ref object

    var base: Base = Sub1() # downcast
    doAssert base of Base # generates `CondTrue` (statically true)
    doAssert base of Sub1
    doAssert base isnot Sub1
    doAssert not (base of Sub2)

    base = Sub2() # re-assign
    doAssert base of Sub2
    doAssert Sub2(base) != nil # upcast
    doAssertRaises(ObjectConversionDefect): discard Sub1(base)

    var sub1 = Sub1()
    doAssert sub1 of Base
    doAssert sub1.Base of Sub1

    doAssert not compiles(base of Unrelated)

proc cmp*[T](x, y: T): int =
  ## Generic compare proc.
  ##
  ## Returns:
  ## * a value less than zero, if `x < y`
  ## * a value greater than zero, if `x > y`
  ## * zero, if `x == y`
  ##
  ## This is useful for writing generic algorithms without performance loss.
  ## This generic implementation uses the `==` and `<` operators.
  ##
  ## .. code-block:: Nim
  ##  import std/algorithm
  ##  echo sorted(@[4, 2, 6, 5, 8, 7], cmp[int])
  if x == y: return 0
  if x < y: return -1
  return 1

proc cmp*(x, y: string): int {.noSideEffect.}
  ## Compare proc for strings. More efficient than the generic version.
  ##
  ## **Note**: The precise result values depend on the used C runtime library and
  ## can differ between operating systems!

proc `@`* [IDX, T](a: sink array[IDX, T]): seq[T] {.magic: "ArrToSeq", noSideEffect.}
  ## Turns an array into a sequence.
  ##
  ## This most often useful for constructing
  ## sequences with the array constructor: `@[1, 2, 3]` has the type
  ## `seq[int]`, while `[1, 2, 3]` has the type `array[0..2, int]`.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = [1, 3, 5]
  ##     b = "foo"
  ##
  ##   echo @a # => @[1, 3, 5]
  ##   echo @b # => @['f', 'o', 'o']

proc default*[T](_: typedesc[T]): T {.magic: "Default", noSideEffect.} =
  ## returns the default value of the type `T`.
  runnableExamples:
    assert (int, float).default == (0, 0.0)
    # note: `var a = default(T)` is usually the same as `var a: T` and (currently) generates
    # a value whose binary representation is all 0, regardless of whether this
    # would violate type constraints such as `range`, `not nil`, etc. This
    # property is required to implement certain algorithms efficiently which
    # may require intermediate invalid states.
    type Foo = object
      a: range[2..6]
    var a1: range[2..6] # currently, this compiles
    # var a2: Foo # currently, this errors: Error: The Foo type doesn't have a default value.
    # var a3 = Foo() # ditto
    var a3 = Foo.default # this works, but generates a `UnsafeDefault` warning.
  # note: the doc comment also explains why `default` can't be implemented
  # via: `template default*[T](t: typedesc[T]): T = (var v: T; v)`

proc reset*[T](obj: var T) {.noSideEffect.} =
  ## Resets an object `obj` to its default value.
  obj = default(typeof(obj))

proc setLen*[T](s: var seq[T], newlen: Natural) {.
  magic: "SetLengthSeq", noSideEffect.}
  ## Sets the length of seq `s` to `newlen`. `T` may be any sequence type.
  ##
  ## If the current length is greater than the new length,
  ## `s` will be truncated.
  ##
  ## .. code-block:: Nim
  ##   var x = @[10, 20]
  ##   x.setLen(5)
  ##   x[4] = 50
  ##   assert x == @[10, 20, 0, 0, 50]
  ##   x.setLen(1)
  ##   assert x == @[10]

proc setLen*(s: var string, newlen: Natural) {.
  magic: "SetLengthStr", noSideEffect.}
  ## Sets the length of string `s` to `newlen`.
  ##
  ## If the current length is greater than the new length,
  ## `s` will be truncated.
  ##
  ## .. code-block:: Nim
  ##  var myS = "Nim is great!!"
  ##  myS.setLen(3) # myS <- "Nim"
  ##  echo myS, " is fantastic!!"

proc newString*(len: Natural): string {.
  magic: "NewString", importc: "mnewString", noSideEffect.}
  ## Returns a new string of length `len` but with uninitialized
  ## content. One needs to fill the string character after character
  ## with the index operator `s[i]`.
  ##
  ## This procedure exists only for optimization purposes;
  ## the same effect can be achieved with the `&` operator or with `add`.

proc newStringOfCap*(cap: Natural): string {.
  magic: "NewStringOfCap", importc: "rawNewString", noSideEffect.}
  ## Returns a new string of length `0` but with capacity `cap`.
  ##
  ## This procedure exists only for optimization purposes; the same effect can
  ## be achieved with the `&` operator or with `add`.

proc `&`*(x: string, y: char): string {.
  magic: "ConStrStr", noSideEffect, merge.}
  ## Concatenates `x` with `y`.
  ##
  ## .. code-block:: Nim
  ##   assert("ab" & 'c' == "abc")
proc `&`*(x, y: char): string {.
  magic: "ConStrStr", noSideEffect, merge.}
  ## Concatenates characters `x` and `y` into a string.
  ##
  ## .. code-block:: Nim
  ##   assert('a' & 'b' == "ab")
proc `&`*(x, y: string): string {.
  magic: "ConStrStr", noSideEffect, merge.}
  ## Concatenates strings `x` and `y`.
  ##
  ## .. code-block:: Nim
  ##   assert("ab" & "cd" == "abcd")
proc `&`*(x: char, y: string): string {.
  magic: "ConStrStr", noSideEffect, merge.}
  ## Concatenates `x` with `y`.
  ##
  ## .. code-block:: Nim
  ##   assert('a' & "bc" == "abc")

# implementation note: These must all have the same magic value "ConStrStr" so
# that the merge optimization works properly.

proc add*(x: var string, y: char) {.magic: "AppendStrCh", noSideEffect.}
  ## Appends `y` to `x` in place.
  ##
  ## .. code-block:: Nim
  ##   var tmp = ""
  ##   tmp.add('a')
  ##   tmp.add('b')
  ##   assert(tmp == "ab")

proc add*(x: var string, y: string) {.magic: "AppendStrStr", noSideEffect.} =
  ## Concatenates `x` and `y` in place.
  ##
  ## See also `strbasics.add`.
  runnableExamples:
    var tmp = ""
    tmp.add("ab")
    tmp.add("cd")
    assert tmp == "abcd"

type
  Endianness* = enum ## Type describing the endianness of a processor.
    littleEndian, bigEndian

const
  isMainModule* {.magic: "IsMainModule".}: bool = false
    ## True only when accessed in the main module. This works thanks to
    ## compiler magic. It is useful to embed testing code in a module.

  CompileDate* {.magic: "CompileDate".}: string = "0000-00-00"
    ## The date (in UTC) of compilation as a string of the form
    ## `YYYY-MM-DD`. This works thanks to compiler magic.

  CompileTime* {.magic: "CompileTime".}: string = "00:00:00"
    ## The time (in UTC) of compilation as a string of the form
    ## `HH:MM:SS`. This works thanks to compiler magic.

  cpuEndian* {.magic: "CpuEndian".}: Endianness = littleEndian
    ## The endianness of the target CPU. This is a valuable piece of
    ## information for low-level code only. This works thanks to compiler
    ## magic.

  hostOS* {.magic: "HostOS".}: string = ""
    ## A string that describes the host operating system.
    ##
    ## Possible values:
    ## `"windows"`, `"macosx"`, `"linux"`, `"netbsd"`, `"freebsd"`,
    ## `"openbsd"`, `"solaris"`, `"aix"`, `"haiku"`, `"standalone"`.

  hostCPU* {.magic: "HostCPU".}: string = ""
    ## A string that describes the host CPU.
    ##
    ## Possible values:
    ## `"i386"`, `"alpha"`, `"powerpc"`, `"powerpc64"`, `"powerpc64el"`,
    ## `"sparc"`, `"amd64"`, `"mips"`, `"mipsel"`, `"arm"`, `"arm64"`,
    ## `"mips64"`, `"mips64el"`, `"riscv32"`, `"riscv64"`.

  seqShallowFlag = low(int)
  strlitFlag = 1 shl (sizeof(int)*8 - 2) # later versions of the codegen \
  # emit this flag
  # for string literals, it allows for some optimizations.

const
  hasThreadSupport = compileOption("threads") and not defined(nimscript)
  hasSharedHeap = defined(boehmgc) or defined(gogc) # don't share heaps; every thread has its own

when hasThreadSupport and defined(tcc) and not compileOption("tlsEmulation"):
  # tcc doesn't support TLS
  {.error: "`--tlsEmulation:on` must be used when using threads with tcc backend".}

when defined(boehmgc):
  when defined(windows):
    when sizeof(int) == 8:
      const boehmLib = "boehmgc64.dll"
    else:
      const boehmLib = "boehmgc.dll"
  elif defined(macosx):
    const boehmLib = "libgc.dylib"
  elif defined(openbsd):
    const boehmLib = "libgc.so.(4|5).0"
  elif defined(freebsd):
    const boehmLib = "libgc-threaded.so.1"
  else:
    const boehmLib = "libgc.so.1"
  {.pragma: boehmGC, noconv, dynlib: boehmLib.}

type TaintedString* {.deprecated: "Deprecated since 1.5".} = string


when defined(profiler) and not defined(nimscript):
  proc nimProfile() {.compilerproc, noinline.}
when hasThreadSupport:
  {.pragma: rtlThreadVar, threadvar.}
else:
  {.pragma: rtlThreadVar.}

const
  QuitSuccess* = 0
    ## is the value that should be passed to `quit <#quit,int>`_ to indicate
    ## success.

  QuitFailure* = 1
    ## is the value that should be passed to `quit <#quit,int>`_ to indicate
    ## failure.

when not defined(js) and hostOS != "standalone":
  var programResult* {.compilerproc, exportc: "nim_program_result".}: int
    ## deprecated, prefer `quit` or `exitprocs.getProgramResult`, `exitprocs.setProgramResult`.

import std/private/since

proc align(address, alignment: int): int =
  if alignment == 0: # Actually, this is illegal. This branch exists to actively
                     # hide problems.
    result = address
  else:
    result = (address + (alignment - 1)) and not (alignment - 1)

when defined(nimdoc):
  proc quit*(errorcode: int = QuitSuccess) {.magic: "Exit", noreturn.}
    ## Stops the program immediately with an exit code.
    ##
    ## Before stopping the program the "exit procedures" are called in the
    ## opposite order they were added with `addExitProc <exitprocs.html#addExitProc,proc)>`_.
    ##
    ## The proc `quit(QuitSuccess)` is called implicitly when your nim
    ## program finishes without incident for platforms where this is the
    ## expected behavior. A raised unhandled exception is
    ## equivalent to calling `quit(QuitFailure)`.
    ##
    ## Note that this is a *runtime* call and using `quit` inside a macro won't
    ## have any compile time effect. If you need to stop the compiler inside a
    ## macro, use the `error <manual.html#pragmas-error-pragma>`_ or `fatal
    ## <manual.html#pragmas-fatal-pragma>`_ pragmas.
    ##
    ## .. danger:: In almost all cases, in particular in library code, prefer
    ##   alternatives, e.g. `doAssert false` or raise a `Defect`.
    ##   `quit` bypasses regular control flow in particular `defer`,
    ##   `try`, `catch`, `finally` and `destructors`, and exceptions that may have been
    ##   raised by an `addExitProc` proc, as well as cleanup code in other threads.
    ##   It does *not* call the garbage collector to free all the memory,
    ##   unless an `addExitProc` proc calls `GC_fullCollect <#GC_fullCollect>`_.

elif defined(genode):
  include genode/env

  var systemEnv {.exportc: runtimeEnvSym.}: GenodeEnvPtr

  type GenodeEnv* = GenodeEnvPtr
    ## Opaque type representing Genode environment.

  proc quit*(env: GenodeEnv; errorcode: int) {.magic: "Exit", noreturn,
    importcpp: "#->parent().exit(@); Genode::sleep_forever()", header: "<base/sleep.h>".}

  proc quit*(errorcode: int = QuitSuccess) =
    systemEnv.quit(errorcode)

elif defined(js) and defined(nodejs) and not defined(nimscript):
  proc quit*(errorcode: int = QuitSuccess) {.magic: "Exit",
    importc: "process.exit", noreturn.}

else:
  proc quit*(errorcode: int = QuitSuccess) {.
    magic: "Exit", importc: "exit", header: "<stdlib.h>", noreturn.}


template sysAssert(cond: bool, msg: string) =
  when defined(useSysAssert):
    if not cond:
      cstderr.rawWrite "[SYSASSERT] "
      cstderr.rawWrite msg
      cstderr.rawWrite "\n"
      quit 1

const hasAlloc = (hostOS != "standalone" or not defined(nogc)) and not defined(nimscript)

when notJSnotNims and hostOS != "standalone" and hostOS != "any":
  include "system/cgprocs"
when notJSnotNims and hasAlloc and not defined(nimSeqsV2):
  proc addChar(s: NimString, c: char): NimString {.compilerproc, benign.}

when defined(nimscript) or not defined(nimSeqsV2):
  proc add*[T](x: var seq[T], y: sink T) {.magic: "AppendSeqElem", noSideEffect.}
    ## Generic proc for adding a data item `y` to a container `x`.
    ##
    ## For containers that have an order, `add` means *append*. New generic
    ## containers should also call their adding proc `add` for consistency.
    ## Generic code becomes much easier to write if the Nim naming scheme is
    ## respected.

when false: # defined(gcDestructors):
  proc add*[T](x: var seq[T], y: sink openArray[T]) {.noSideEffect.} =
    ## Generic proc for adding a container `y` to a container `x`.
    ##
    ## For containers that have an order, `add` means *append*. New generic
    ## containers should also call their adding proc `add` for consistency.
    ## Generic code becomes much easier to write if the Nim naming scheme is
    ## respected.
    ##
    ## See also:
    ## * `& proc <#&,seq[T],seq[T]>`_
    ##
    ## .. code-block:: Nim
    ##   var s: seq[string] = @["test2","test2"]
    ##   s.add("test") # s <- @[test2, test2, test]
    {.noSideEffect.}:
      let xl = x.len
      setLen(x, xl + y.len)
      for i in 0..high(y):
        when nimvm:
          # workaround the fact that the VM does not yet
          # handle sink parameters properly:
          x[xl+i] = y[i]
        else:
          x[xl+i] = move y[i]
else:
  proc add*[T](x: var seq[T], y: openArray[T]) {.noSideEffect.} =
    ## Generic proc for adding a container `y` to a container `x`.
    ##
    ## For containers that have an order, `add` means *append*. New generic
    ## containers should also call their adding proc `add` for consistency.
    ## Generic code becomes much easier to write if the Nim naming scheme is
    ## respected.
    ##
    ## See also:
    ## * `& proc <#&,seq[T],seq[T]>`_
    ##
    ## .. code-block:: Nim
    ##   var s: seq[string] = @["test2","test2"]
    ##   s.add("test") # s <- @[test2, test2, test]
    {.noSideEffect.}:
      let xl = x.len
      setLen(x, xl + y.len)
      for i in 0..high(y): x[xl+i] = y[i]


when defined(nimSeqsV2):
  template movingCopy(a, b) =
    a = move(b)
else:
  template movingCopy(a, b) =
    shallowCopy(a, b)

proc del*[T](x: var seq[T], i: Natural) {.noSideEffect.} =
  ## Deletes the item at index `i` by putting `x[high(x)]` into position `i`.
  ##
  ## This is an `O(1)` operation.
  ##
  ## See also:
  ## * `delete <#delete,seq[T],Natural>`_ for preserving the order
  runnableExamples:
    var a = @[10, 11, 12, 13, 14]
    a.del(2)
    assert a == @[10, 11, 14, 13]
  let xl = x.len - 1
  movingCopy(x[i], x[xl])
  setLen(x, xl)

proc insert*[T](x: var seq[T], item: sink T, i = 0.Natural) {.noSideEffect.} =
  ## Inserts `item` into `x` at position `i`.
  ##
  ## .. code-block:: Nim
  ##  var i = @[1, 3, 5]
  ##  i.insert(99, 0) # i <- @[99, 1, 3, 5]
  {.noSideEffect.}:
    template defaultImpl =
      let xl = x.len
      setLen(x, xl+1)
      var j = xl-1
      while j >= i:
        movingCopy(x[j+1], x[j])
        dec(j)
    when nimvm:
      defaultImpl()
    else:
      when defined(js):
        var it : T
        {.emit: "`x` = `x` || []; `x`.splice(`i`, 0, `it`);".}
      else:
        defaultImpl()
    x[i] = item

when not defined(nimV2):
  proc repr*[T](x: T): string {.magic: "Repr", noSideEffect.}
    ## Takes any Nim variable and returns its string representation.
    ## No trailing newline is inserted (so `echo` won't add an empty newline).
    ## Use `-d:nimLegacyReprWithNewline` to revert to old behavior where newlines
    ## were added in some cases.
    ##
    ## It works even for complex data graphs with cycles. This is a great
    ## debugging tool.
    ##
    ## .. code-block:: Nim
    ##  var s: seq[string] = @["test2", "test2"]
    ##  var i = @[1, 2, 3, 4, 5]
    ##  echo repr(s) # => 0x1055eb050[0x1055ec050"test2", 0x1055ec078"test2"]
    ##  echo repr(i) # => 0x1055ed050[1, 2, 3, 4, 5]

type
  ByteAddress* = int
    ## is the signed integer type that should be used for converting
    ## pointers to integer addresses for readability.

  BiggestFloat* = float64
    ## is an alias for the biggest floating point type the Nim
    ## compiler supports. Currently this is `float64`, but it is
    ## platform-dependent in general.

when defined(js):
  type BiggestUInt* = uint32
    ## is an alias for the biggest unsigned integer type the Nim compiler
    ## supports. Currently this is `uint32` for JS and `uint64` for other
    ## targets.
else:
  type BiggestUInt* = uint64
    ## is an alias for the biggest unsigned integer type the Nim compiler
    ## supports. Currently this is `uint32` for JS and `uint64` for other
    ## targets.

when defined(windows):
  type
    clong* {.importc: "long", nodecl.} = int32
      ## This is the same as the type `long` in *C*.
    culong* {.importc: "unsigned long", nodecl.} = uint32
      ## This is the same as the type `unsigned long` in *C*.
else:
  type
    clong* {.importc: "long", nodecl.} = int
      ## This is the same as the type `long` in *C*.
    culong* {.importc: "unsigned long", nodecl.} = uint
      ## This is the same as the type `unsigned long` in *C*.

type # these work for most platforms:
  cchar* {.importc: "char", nodecl.} = char
    ## This is the same as the type `char` in *C*.
  cschar* {.importc: "signed char", nodecl.} = int8
    ## This is the same as the type `signed char` in *C*.
  cshort* {.importc: "short", nodecl.} = int16
    ## This is the same as the type `short` in *C*.
  cint* {.importc: "int", nodecl.} = int32
    ## This is the same as the type `int` in *C*.
  csize* {.importc: "size_t", nodecl, deprecated: "use `csize_t` instead".} = int
    ## This isn't the same as `size_t` in *C*. Don't use it.
  csize_t* {.importc: "size_t", nodecl.} = uint
    ## This is the same as the type `size_t` in *C*.
  clonglong* {.importc: "long long", nodecl.} = int64
    ## This is the same as the type `long long` in *C*.
  cfloat* {.importc: "float", nodecl.} = float32
    ## This is the same as the type `float` in *C*.
  cdouble* {.importc: "double", nodecl.} = float64
    ## This is the same as the type `double` in *C*.
  clongdouble* {.importc: "long double", nodecl.} = BiggestFloat
    ## This is the same as the type `long double` in *C*.
    ## This C type is not supported by Nim's code generator.

  cuchar* {.importc: "unsigned char", nodecl, deprecated: "use `char` or `uint8` instead".} = char
    ## Deprecated: Use `uint8` instead.
  cushort* {.importc: "unsigned short", nodecl.} = uint16
    ## This is the same as the type `unsigned short` in *C*.
  cuint* {.importc: "unsigned int", nodecl.} = uint32
    ## This is the same as the type `unsigned int` in *C*.
  culonglong* {.importc: "unsigned long long", nodecl.} = uint64
    ## This is the same as the type `unsigned long long` in *C*.

  cstringArray* {.importc: "char**", nodecl.} = ptr UncheckedArray[cstring]
    ## This is binary compatible to the type `char**` in *C*. The array's
    ## high value is large enough to disable bounds checking in practice.
    ## Use `cstringArrayToSeq proc <#cstringArrayToSeq,cstringArray,Natural>`_
    ## to convert it into a `seq[string]`.

  PFloat32* = ptr float32    ## An alias for `ptr float32`.
  PFloat64* = ptr float64    ## An alias for `ptr float64`.
  PInt64* = ptr int64        ## An alias for `ptr int64`.
  PInt32* = ptr int32        ## An alias for `ptr int32`.

proc toFloat*(i: int): float {.noSideEffect, inline.} =
  ## Converts an integer `i` into a `float`. Same as `float(i)`.
  ##
  ## If the conversion fails, `ValueError` is raised.
  ## However, on most platforms the conversion cannot fail.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = 2
  ##     b = 3.7
  ##
  ##   echo a.toFloat + b # => 5.7
  float(i)

proc toBiggestFloat*(i: BiggestInt): BiggestFloat {.noSideEffect, inline.} =
  ## Same as `toFloat <#toFloat,int>`_ but for `BiggestInt` to `BiggestFloat`.
  BiggestFloat(i)

proc toInt*(f: float): int {.noSideEffect.} =
  ## Converts a floating point number `f` into an `int`.
  ##
  ## Conversion rounds `f` half away from 0, see
  ## `Round half away from zero
  ## <https://en.wikipedia.org/wiki/Rounding#Round_half_away_from_zero>`_,
  ## as opposed to a type conversion which rounds towards zero.
  ##
  ## Note that some floating point numbers (e.g. infinity or even 1e19)
  ## cannot be accurately converted.
  ##
  ## .. code-block:: Nim
  ##   doAssert toInt(0.49) == 0
  ##   doAssert toInt(0.5) == 1
  ##   doAssert toInt(-0.5) == -1 # rounding is symmetrical
  if f >= 0: int(f+0.5) else: int(f-0.5)

proc toBiggestInt*(f: BiggestFloat): BiggestInt {.noSideEffect.} =
  ## Same as `toInt <#toInt,float>`_ but for `BiggestFloat` to `BiggestInt`.
  if f >= 0: BiggestInt(f+0.5) else: BiggestInt(f-0.5)

proc addQuitProc*(quitProc: proc() {.noconv.}) {.
  importc: "atexit", header: "<stdlib.h>", deprecated: "use exitprocs.addExitProc".}
  ## Adds/registers a quit procedure.
  ##
  ## Each call to `addQuitProc` registers another quit procedure. Up to 30
  ## procedures can be registered. They are executed on a last-in, first-out
  ## basis (that is, the last function registered is the first to be executed).
  ## `addQuitProc` raises an EOutOfIndex exception if `quitProc` cannot be
  ## registered.
  # Support for addQuitProc() is done by Ansi C's facilities here.
  # In case of an unhandled exception the exit handlers should
  # not be called explicitly! The user may decide to do this manually though.

proc swap*[T](a, b: var T) {.magic: "Swap", noSideEffect.}
  ## Swaps the values `a` and `b`.
  ##
  ## This is often more efficient than `tmp = a; a = b; b = tmp`.
  ## Particularly useful for sorting algorithms.
  ##
  ## .. code-block:: Nim
  ##   var
  ##     a = 5
  ##     b = 9
  ##
  ##   swap(a, b)
  ##
  ##   assert a == 9
  ##   assert b == 5

when not defined(js) and not defined(booting) and defined(nimTrMacros):
  template swapRefsInArray*{swap(arr[a], arr[b])}(arr: openArray[ref], a, b: int) =
    # Optimize swapping of array elements if they are refs. Default swap
    # implementation will cause unsureAsgnRef to be emitted which causes
    # unnecessary slow down in this case.
    swap(cast[ptr pointer](addr arr[a])[], cast[ptr pointer](addr arr[b])[])

const
  Inf* = 0x7FF0000000000000'f64
    ## Contains the IEEE floating point value of positive infinity.
  NegInf* = 0xFFF0000000000000'f64
    ## Contains the IEEE floating point value of negative infinity.
  NaN* = 0x7FF7FFFFFFFFFFFF'f64
    ## Contains an IEEE floating point value of *Not A Number*.
    ##
    ## Note that you cannot compare a floating point value to this value
    ## and expect a reasonable result - use the `isNaN` or `classify` procedure
    ## in the `math module <math.html>`_ for checking for NaN.


include "system/memalloc"


proc `|`*(a, b: typedesc): typedesc = discard

include "system/iterators_1"


{.push stackTrace: off.}


when defined(js):
  proc js_abs[T: SomeNumber](x: T): T {.importc: "Math.abs".}
else:
  proc c_fabs(x: cdouble): cdouble {.importc: "fabs", header: "<math.h>".}
  proc c_fabsf(x: cfloat): cfloat {.importc: "fabsf", header: "<math.h>".}

proc abs*[T: float64 | float32](x: T): T {.noSideEffect, inline.} =
  when nimvm:
    if x < 0.0: result = -x
    elif x == 0.0: result = 0.0 # handle 0.0, -0.0
    else: result = x # handle NaN, > 0
  else:
    when defined(js): result = js_abs(x)
    else:
      when T is float64:
        result = c_fabs(x)
      else:
        result = c_fabsf(x)

proc min*(x, y: float32): float32 {.noSideEffect, inline.} =
  if x <= y or y != y: x else: y
proc min*(x, y: float64): float64 {.noSideEffect, inline.} =
  if x <= y or y != y: x else: y
proc max*(x, y: float32): float32 {.noSideEffect, inline.} =
  if y <= x or y != y: x else: y
proc max*(x, y: float64): float64 {.noSideEffect, inline.} =
  if y <= x or y != y: x else: y
proc min*[T: not SomeFloat](x, y: T): T {.inline.} =
  if x <= y: x else: y
proc max*[T: not SomeFloat](x, y: T): T {.inline.} =
  if y <= x: x else: y

{.pop.} # stackTrace: off


proc high*(T: typedesc[SomeFloat]): T = Inf
proc low*(T: typedesc[SomeFloat]): T = NegInf

proc len*[U: Ordinal; V: Ordinal](x: HSlice[U, V]): int {.noSideEffect, inline.} =
  ## Length of ordinal slice. When x.b < x.a returns zero length.
  ##
  ## .. code-block:: Nim
  ##   assert((0..5).len == 6)
  ##   assert((5..2).len == 0)
  result = max(0, ord(x.b) - ord(x.a) + 1)

when true: # PRTEMP: remove?
  proc isNil*[T](x: seq[T]): bool {.noSideEffect, magic: "IsNil", error.}
    ## Seqs are no longer nil by default, but set and empty.
    ## Check for zero length instead.
    ##
    ## See also:
    ## * `isNil(string) <#isNil,string>`_

  proc isNil*(x: string): bool {.noSideEffect, magic: "IsNil", error.}
    ## See also:
    ## * `isNil(seq[T]) <#isNil,seq[T]>`_

proc isNil*[T](x: ref T): bool {.noSideEffect, magic: "IsNil".}

proc isNil*[T](x: ptr T): bool {.noSideEffect, magic: "IsNil".}
proc isNil*(x: pointer): bool {.noSideEffect, magic: "IsNil".}
proc isNil*(x: cstring): bool {.noSideEffect, magic: "IsNil".}
proc isNil*[T: proc](x: T): bool {.noSideEffect, magic: "IsNil".}
  ## Fast check whether `x` is nil. This is sometimes more efficient than
  ## `== nil`.


proc `@`*[T](a: openArray[T]): seq[T] =
  ## Turns an *openArray* into a sequence.
  ##
  ## This is not as efficient as turning a fixed length array into a sequence
  ## as it always copies every element of `a`.
  newSeq(result, a.len)
  for i in 0..a.len-1: result[i] = a[i]


when defined(nimSeqsV2):

  proc `&`*[T](x, y: sink seq[T]): seq[T] {.noSideEffect.} =
    ## Concatenates two sequences.
    ##
    ## Requires copying of the sequences.
    ##
    ## See also:
    ## * `add(var seq[T], openArray[T]) <#add,seq[T],openArray[T]>`_
    ##
    ## .. code-block:: Nim
    ##   assert(@[1, 2, 3, 4] & @[5, 6] == @[1, 2, 3, 4, 5, 6])
    newSeq(result, x.len + y.len)
    for i in 0..x.len-1:
      result[i] = move(x[i])
    for i in 0..y.len-1:
      result[i+x.len] = move(y[i])

  proc `&`*[T](x: sink seq[T], y: sink T): seq[T] {.noSideEffect.} =
    ## Appends element y to the end of the sequence.
    ##
    ## Requires copying of the sequence.
    ##
    ## See also:
    ## * `add(var seq[T], T) <#add,seq[T],sinkT>`_
    ##
    ## .. code-block:: Nim
    ##   assert(@[1, 2, 3] & 4 == @[1, 2, 3, 4])
    newSeq(result, x.len + 1)
    for i in 0..x.len-1:
      result[i] = move(x[i])
    result[x.len] = move(y)

  proc `&`*[T](x: sink T, y: sink seq[T]): seq[T] {.noSideEffect.} =
    ## Prepends the element x to the beginning of the sequence.
    ##
    ## Requires copying of the sequence.
    ##
    ## .. code-block:: Nim
    ##   assert(1 & @[2, 3, 4] == @[1, 2, 3, 4])
    newSeq(result, y.len + 1)
    result[0] = move(x)
    for i in 0..y.len-1:
      result[i+1] = move(y[i])

else:

  proc `&`*[T](x, y: seq[T]): seq[T] {.noSideEffect.} =
    ## Concatenates two sequences.
    ##
    ## Requires copying of the sequences.
    ##
    ## See also:
    ## * `add(var seq[T], openArray[T]) <#add,seq[T],openArray[T]>`_
    ##
    ## .. code-block:: Nim
    ##   assert(@[1, 2, 3, 4] & @[5, 6] == @[1, 2, 3, 4, 5, 6])
    newSeq(result, x.len + y.len)
    for i in 0..x.len-1:
      result[i] = x[i]
    for i in 0..y.len-1:
      result[i+x.len] = y[i]

  proc `&`*[T](x: seq[T], y: T): seq[T] {.noSideEffect.} =
    ## Appends element y to the end of the sequence.
    ##
    ## Requires copying of the sequence.
    ##
    ## See also:
    ## * `add(var seq[T], T) <#add,seq[T],sinkT>`_
    ##
    ## .. code-block:: Nim
    ##   assert(@[1, 2, 3] & 4 == @[1, 2, 3, 4])
    newSeq(result, x.len + 1)
    for i in 0..x.len-1:
      result[i] = x[i]
    result[x.len] = y

  proc `&`*[T](x: T, y: seq[T]): seq[T] {.noSideEffect.} =
    ## Prepends the element x to the beginning of the sequence.
    ##
    ## Requires copying of the sequence.
    ##
    ## .. code-block:: Nim
    ##   assert(1 & @[2, 3, 4] == @[1, 2, 3, 4])
    newSeq(result, y.len + 1)
    result[0] = x
    for i in 0..y.len-1:
      result[i+1] = y[i]


proc astToStr*[T](x: T): string {.magic: "AstToStr", noSideEffect.}
  ## Converts the AST of `x` into a string representation. This is very useful
  ## for debugging.

proc instantiationInfo*(index = -1, fullPaths = false): tuple[
  filename: string, line: int, column: int] {.magic: "InstantiationInfo", noSideEffect.}
  ## Provides access to the compiler's instantiation stack line information
  ## of a template.
  ##
  ## While similar to the `caller info`:idx: of other languages, it is determined
  ## at compile time.
  ##
  ## This proc is mostly useful for meta programming (eg. `assert` template)
  ## to retrieve information about the current filename and line number.
  ## Example:
  ##
  ## .. code-block:: nim
  ##   import std/strutils
  ##
  ##   template testException(exception, code: untyped): typed =
  ##     try:
  ##       let pos = instantiationInfo()
  ##       discard(code)
  ##       echo "Test failure at $1:$2 with '$3'" % [pos.filename,
  ##         $pos.line, astToStr(code)]
  ##       assert false, "A test expecting failure succeeded?"
  ##     except exception:
  ##       discard
  ##
  ##   proc tester(pos: int): int =
  ##     let
  ##       a = @[1, 2, 3]
  ##     result = a[pos]
  ##
  ##   when isMainModule:
  ##     testException(IndexDefect, tester(30))
  ##     testException(IndexDefect, tester(1))
  ##     # --> Test failure at example.nim:20 with 'tester(1)'

proc compiles*(x: untyped): bool {.magic: "Compiles", noSideEffect, compileTime.} =
  ## Special compile-time procedure that checks whether `x` can be compiled
  ## without any semantic error.
  ## This can be used to check whether a type supports some operation:
  ##
  ## .. code-block:: Nim
  ##   when compiles(3 + 4):
  ##     echo "'+' for integers is available"
  discard

when notJSnotNims:
  import system/ansi_c
  import system/memory


{.push stackTrace: off.}

when not defined(js) and hasThreadSupport and hostOS != "standalone":
  const insideRLocksModule = false
  include "system/syslocks"
  include "system/threadlocalstorage"

when not defined(js) and defined(nimV2):
  type
    DestructorProc = proc (p: pointer) {.nimcall, benign, raises: [].}
    TNimTypeV2 {.compilerproc.} = object
      destructor: pointer
      size: int
      align: int
      name: cstring
      traceImpl: pointer
      typeInfoV1: pointer # for backwards compat, usually nil
      flags: int
    PNimTypeV2 = ptr TNimTypeV2

when notJSnotNims and defined(nimSeqsV2):
  include "system/strs_v2"
  include "system/seqs_v2"

{.pop.}

when not defined(nimscript):
  proc writeStackTrace*() {.tags: [], gcsafe, raises: [].}
    ## Writes the current stack trace to `stderr`. This is only works
    ## for debug builds. Since it's usually used for debugging, this
    ## is proclaimed to have no IO effect!

when not declared(sysFatal):
  include "system/fatal"

when not defined(nimscript):
  {.push stackTrace: off, profiler: off.}

  proc atomicInc*(memLoc: var int, x: int = 1): int {.inline,
    discardable, benign.}
    ## Atomic increment of `memLoc`. Returns the value after the operation.

  proc atomicDec*(memLoc: var int, x: int = 1): int {.inline,
    discardable, benign.}
    ## Atomic decrement of `memLoc`. Returns the value after the operation.

  include "system/atomics"

  {.pop.}


when defined(nimV2):
  include system/arc

import system/assertions
export assertions

import system/iterators
export iterators


proc find*[T, S](a: T, item: S): int {.inline.}=
  ## Returns the first index of `item` in `a` or -1 if not found. This requires
  ## appropriate `items` and `==` operations to work.
  result = 0
  for i in items(a):
    if i == item: return
    inc(result)
  result = -1

proc contains*[T](a: openArray[T], item: T): bool {.inline.}=
  ## Returns true if `item` is in `a` or false if not found. This is a shortcut
  ## for `find(a, item) >= 0`.
  ##
  ## This allows the `in` operator: `a.contains(item)` is the same as
  ## `item in a`.
  ##
  ## .. code-block:: Nim
  ##   var a = @[1, 3, 5]
  ##   assert a.contains(5)
  ##   assert 3 in a
  ##   assert 99 notin a
  return find(a, item) >= 0

proc pop*[T](s: var seq[T]): T {.inline, noSideEffect.} =
  ## Returns the last item of `s` and decreases `s.len` by one. This treats
  ## `s` as a stack and implements the common *pop* operation.
  runnableExamples:
    var a = @[1, 3, 5, 7]
    let b = pop(a)
    assert b == 7
    assert a == @[1, 3, 5]

  var L = s.len-1
  when defined(nimV2):
    result = move s[L]
    shrink(s, L)
  else:
    result = s[L]
    setLen(s, L)

proc `==`*[T: tuple|object](x, y: T): bool =
  ## Generic `==` operator for tuples that is lifted from the components.
  ## of `x` and `y`.
  for a, b in fields(x, y):
    if a != b: return false
  return true

proc `<=`*[T: tuple](x, y: T): bool =
  ## Generic lexicographic `<=` operator for tuples that is lifted from the
  ## components of `x` and `y`. This implementation uses `cmp`.
  for a, b in fields(x, y):
    var c = cmp(a, b)
    if c < 0: return true
    if c > 0: return false
  return true

proc `<`*[T: tuple](x, y: T): bool =
  ## Generic lexicographic `<` operator for tuples that is lifted from the
  ## components of `x` and `y`. This implementation uses `cmp`.
  for a, b in fields(x, y):
    var c = cmp(a, b)
    if c < 0: return true
    if c > 0: return false
  return false


include "system/gc_interface"

# we have to compute this here before turning it off in except.nim anyway ...
const NimStackTrace = compileOption("stacktrace")

import system/coro_detection

{.push checks: off.}
# obviously we cannot generate checking operations here :-)
# because it would yield into an endless recursion
# however, stack-traces are available for most parts
# of the code

when notJSnotNims:
  var
    globalRaiseHook*: proc (e: ref Exception): bool {.nimcall, benign.}
      ## With this hook you can influence exception handling on a global level.
      ## If not nil, every 'raise' statement ends up calling this hook.
      ##
      ## .. warning:: Ordinary application code should never set this hook! You better know what you do when setting this.
      ##
      ## If `globalRaiseHook` returns false, the exception is caught and does
      ## not propagate further through the call stack.

    localRaiseHook* {.threadvar.}: proc (e: ref Exception): bool {.nimcall, benign.}
      ## With this hook you can influence exception handling on a
      ## thread local level.
      ## If not nil, every 'raise' statement ends up calling this hook.
      ##
      ## .. warning:: Ordinary application code should never set this hook! You better know what you do when setting this.
      ##
      ## If `localRaiseHook` returns false, the exception
      ## is caught and does not propagate further through the call stack.

    outOfMemHook*: proc () {.nimcall, tags: [], benign, raises: [].}
      ## Set this variable to provide a procedure that should be called
      ## in case of an `out of memory`:idx: event. The standard handler
      ## writes an error message and terminates the program.
      ##
      ## `outOfMemHook` can be used to raise an exception in case of OOM like so:
      ##
      ## .. code-block:: Nim
      ##
      ##   var gOutOfMem: ref EOutOfMemory
      ##   new(gOutOfMem) # need to be allocated *before* OOM really happened!
      ##   gOutOfMem.msg = "out of memory"
      ##
      ##   proc handleOOM() =
      ##     raise gOutOfMem
      ##
      ##   system.outOfMemHook = handleOOM
      ##
      ## If the handler does not raise an exception, ordinary control flow
      ## continues and the program is terminated.
    unhandledExceptionHook*: proc (e: ref Exception) {.nimcall, tags: [], benign, raises: [].}
      ## Set this variable to provide a procedure that should be called
      ## in case of an `unhandle exception` event. The standard handler
      ## writes an error message and terminates the program, except when
      ## using `--os:any`

type
  PFrame* = ptr TFrame  ## Represents a runtime frame of the call stack;
                        ## part of the debugger API.
  # keep in sync with nimbase.h `struct TFrame_`
  TFrame* {.importc, nodecl, final.} = object ## The frame itself.
    prev*: PFrame       ## Previous frame; used for chaining the call stack.
    procname*: cstring  ## Name of the proc that is currently executing.
    line*: int          ## Line number of the proc that is currently executing.
    filename*: cstring  ## Filename of the proc that is currently executing.
    len*: int16         ## Length of the inspectable slots.
    calldepth*: int16   ## Used for max call depth checking.
    when NimStackTraceMsgs:
      frameMsgLen*: int   ## end position in frameMsgBuf for this frame.

when defined(js) or defined(nimdoc):
  proc add*(x: var string, y: cstring) {.asmNoStackFrame.} =
    ## Appends `y` to `x` in place.
    runnableExamples:
      var tmp = ""
      tmp.add(cstring("ab"))
      tmp.add(cstring("cd"))
      doAssert tmp == "abcd"
    asm """
      if (`x` === null) { `x` = []; }
      var off = `x`.length;
      `x`.length += `y`.length;
      for (var i = 0; i < `y`.length; ++i) {
        `x`[off+i] = `y`.charCodeAt(i);
      }
    """
  proc add*(x: var cstring, y: cstring) {.magic: "AppendStrStr".} =
    ## Appends `y` to `x` in place.
    ## Only implemented for JS backend.
    runnableExamples:
      when defined(js):
        var tmp: cstring = ""
        tmp.add(cstring("ab"))
        tmp.add(cstring("cd"))
        doAssert tmp == cstring("abcd")

elif hasAlloc:
  {.push stackTrace: off, profiler: off.}
  proc add*(x: var string, y: cstring) =
    var i = 0
    if y != nil:
      while y[i] != '\0':
        add(x, y[i])
        inc(i)
  {.pop.}

proc echo*(x: varargs[typed, `$`]) {.magic: "Echo", benign, sideEffect.}
  ## Writes and flushes the parameters to the standard output.
  ##
  ## Special built-in that takes a variable number of arguments. Each argument
  ## is converted to a string via `$`, so it works for user-defined
  ## types that have an overloaded `$` operator.
  ## It is roughly equivalent to `writeLine(stdout, x); flushFile(stdout)`, but
  ## available for the JavaScript target too.
  ##
  ## Unlike other IO operations this is guaranteed to be thread-safe as
  ## `echo` is very often used for debugging convenience. If you want to use
  ## `echo` inside a `proc without side effects
  ## <manual.html#pragmas-nosideeffect-pragma>`_ you can use `debugEcho
  ## <#debugEcho,varargs[typed,]>`_ instead.

proc debugEcho*(x: varargs[typed, `$`]) {.magic: "Echo", noSideEffect,
                                          tags: [], raises: [].}
  ## Same as `echo <#echo,varargs[typed,]>`_, but as a special semantic rule,
  ## `debugEcho` pretends to be free of side effects, so that it can be used
  ## for debugging routines marked as `noSideEffect
  ## <manual.html#pragmas-nosideeffect-pragma>`_.

template newException*(exceptn: typedesc, message: string;
                       parentException: ref Exception = nil): untyped =
  ## Creates an exception object of type `exceptn` and sets its `msg` field
  ## to `message`. Returns the new exception object.
  (ref exceptn)(msg: message, parent: parentException)

when hostOS == "standalone" and defined(nogc):
  proc nimToCStringConv(s: NimString): cstring {.compilerproc, inline.} =
    if s == nil or s.len == 0: result = cstring""
    else: result = cstring(addr s.data)

proc getTypeInfo*[T](x: T): pointer {.magic: "GetTypeInfo", benign.}
  ## Get type information for `x`.
  ##
  ## Ordinary code should not use this, but the `typeinfo module
  ## <typeinfo.html>`_ instead.

{.push stackTrace: off.}
func abs*(x: int): int {.magic: "AbsI", inline.} =
  if x < 0: -x else: x
func abs*(x: int8): int8 {.magic: "AbsI", inline.} =
  if x < 0: -x else: x
func abs*(x: int16): int16 {.magic: "AbsI", inline.} =
  if x < 0: -x else: x
func abs*(x: int32): int32 {.magic: "AbsI", inline.} =
  if x < 0: -x else: x
func abs*(x: int64): int64 {.magic: "AbsI", inline.} =
  ## Returns the absolute value of `x`.
  ##
  ## If `x` is `low(x)` (that is -MININT for its type),
  ## an overflow exception is thrown (if overflow checking is turned on).
  result = if x < 0: -x else: x
{.pop.}

when not defined(js):

  proc likelyProc(val: bool): bool {.importc: "NIM_LIKELY", nodecl, noSideEffect.}
  proc unlikelyProc(val: bool): bool {.importc: "NIM_UNLIKELY", nodecl, noSideEffect.}

template likely*(val: bool): bool =
  ## Hints the optimizer that `val` is likely going to be true.
  ##
  ## You can use this template to decorate a branch condition. On certain
  ## platforms this can help the processor predict better which branch is
  ## going to be run. Example:
  ##
  ## .. code-block:: Nim
  ##   for value in inputValues:
  ##     if likely(value <= 100):
  ##       process(value)
  ##     else:
  ##       echo "Value too big!"
  ##
  ## On backends without branch prediction (JS and the nimscript VM), this
  ## template will not affect code execution.
  when nimvm:
    val
  else:
    when defined(js):
      val
    else:
      likelyProc(val)

template unlikely*(val: bool): bool =
  ## Hints the optimizer that `val` is likely going to be false.
  ##
  ## You can use this proc to decorate a branch condition. On certain
  ## platforms this can help the processor predict better which branch is
  ## going to be run. Example:
  ##
  ## .. code-block:: Nim
  ##   for value in inputValues:
  ##     if unlikely(value > 100):
  ##       echo "Value too big!"
  ##     else:
  ##       process(value)
  ##
  ## On backends without branch prediction (JS and the nimscript VM), this
  ## template will not affect code execution.
  when nimvm:
    val
  else:
    when defined(js):
      val
    else:
      unlikelyProc(val)

const
  NimMajor* {.intdefine.}: int = 1
    ## is the major number of Nim's version. Example:
    ##
    ## .. code-block:: Nim
    ##   when (NimMajor, NimMinor, NimPatch) >= (1, 3, 1): discard
    # see also std/private/since

  NimMinor* {.intdefine.}: int = 5
    ## is the minor number of Nim's version.
    ## Odd for devel, even for releases.

  NimPatch* {.intdefine.}: int = 1
    ## is the patch number of Nim's version.
    ## Odd for devel, even for releases.

import system/dollars
export dollars

when defined(nimAuditDelete):
  {.pragma: auditDelete, deprecated: "review this call for out of bounds behavior".}
else:
  {.pragma: auditDelete.}

proc delete*[T](x: var seq[T], i: Natural) {.noSideEffect, auditDelete.} =
  ## Deletes the item at index `i` by moving all `x[i+1..^1]` items by one position.
  ##
  ## This is an `O(n)` operation.
  ##
  ## See also:
  ## * `del <#del,seq[T],Natural>`_ for O(1) operation
  ##
  runnableExamples:
    var s = @[1, 2, 3, 4, 5]
    s.delete(2)
    doAssert s == @[1, 2, 4, 5]

  when defined(nimStrictDelete):
    if i > high(x):
      # xxx this should call `raiseIndexError2(i, high(x))` after some refactoring
      raise (ref IndexDefect)(msg: "index out of bounds: '" & $i & "' < '" & $x.len & "' failed")

  template defaultImpl =
    let xl = x.len
    for j in i.int..xl-2: movingCopy(x[j], x[j+1])
    setLen(x, xl-1)

  when nimvm:
    defaultImpl()
  else:
    when defined(js):
      {.emit: "`x`.splice(`i`, 1);".}
    else:
      defaultImpl()


const
  NimVersion*: string = $NimMajor & "." & $NimMinor & "." & $NimPatch
    ## is the version of Nim as a string.


type
  FileSeekPos* = enum ## Position relative to which seek should happen.
                      # The values are ordered so that they match with stdio
                      # SEEK_SET, SEEK_CUR and SEEK_END respectively.
    fspSet            ## Seek to absolute value
    fspCur            ## Seek relative to current position
    fspEnd            ## Seek relative to end


when not defined(js):
  {.push stackTrace: off, profiler: off.}

  when hasAlloc:
    when not defined(gcRegions) and not usesDestructors:
      proc initGC() {.gcsafe, raises: [].}

    proc initStackBottom() {.inline, compilerproc.} =
      # WARNING: This is very fragile! An array size of 8 does not work on my
      # Linux 64bit system. -- That's because the stack direction is the other
      # way around.
      when declared(nimGC_setStackBottom):
        var locals {.volatile, noinit.}: pointer
        locals = addr(locals)
        nimGC_setStackBottom(locals)

    proc initStackBottomWith(locals: pointer) {.inline, compilerproc.} =
      # We need to keep initStackBottom around for now to avoid
      # bootstrapping problems.
      when declared(nimGC_setStackBottom):
        nimGC_setStackBottom(locals)

    when not usesDestructors:
      {.push profiler: off.}
      var
        strDesc = TNimType(size: sizeof(string), kind: tyString, flags: {ntfAcyclic})
      {.pop.}

  {.pop.}


when not defined(js):
  # ugly hack, see the accompanying .pop for
  # the mysterious error message
  {.push stackTrace: off, profiler: off.}

when notJSnotNims:
  proc zeroMem(p: pointer, size: Natural) =
    nimZeroMem(p, size)
    when declared(memTrackerOp):
      memTrackerOp("zeroMem", p, size)
  proc copyMem(dest, source: pointer, size: Natural) =
    nimCopyMem(dest, source, size)
    when declared(memTrackerOp):
      memTrackerOp("copyMem", dest, size)
  proc moveMem(dest, source: pointer, size: Natural) =
    c_memmove(dest, source, csize_t(size))
    when declared(memTrackerOp):
      memTrackerOp("moveMem", dest, size)
  proc equalMem(a, b: pointer, size: Natural): bool =
    nimCmpMem(a, b, size) == 0
  proc cmpMem(a, b: pointer, size: Natural): int =
    nimCmpMem(a, b, size)

when not defined(js):
  proc cmp(x, y: string): int =
    when nimvm:
      if x < y: result = -1
      elif x > y: result = 1
      else: result = 0
    else:
      when not defined(nimscript): # avoid semantic checking
        let minlen = min(x.len, y.len)
        result = int(nimCmpMem(x.cstring, y.cstring, cast[csize_t](minlen)))
        if result == 0:
          result = x.len - y.len

  when declared(newSeq):
    proc cstringArrayToSeq*(a: cstringArray, len: Natural): seq[string] =
      ## Converts a `cstringArray` to a `seq[string]`. `a` is supposed to be
      ## of length `len`.
      newSeq(result, len)
      for i in 0..len-1: result[i] = $a[i]

    proc cstringArrayToSeq*(a: cstringArray): seq[string] =
      ## Converts a `cstringArray` to a `seq[string]`. `a` is supposed to be
      ## terminated by `nil`.
      var L = 0
      while a[L] != nil: inc(L)
      result = cstringArrayToSeq(a, L)


when not defined(js) and declared(alloc0) and declared(dealloc):
  proc allocCStringArray*(a: openArray[string]): cstringArray =
    ## Creates a NULL terminated cstringArray from `a`. The result has to
    ## be freed with `deallocCStringArray` after it's not needed anymore.
    result = cast[cstringArray](alloc0((a.len+1) * sizeof(cstring)))

    let x = cast[ptr UncheckedArray[string]](a)
    for i in 0 .. a.high:
      result[i] = cast[cstring](alloc0(x[i].len+1))
      copyMem(result[i], addr(x[i][0]), x[i].len)

  proc deallocCStringArray*(a: cstringArray) =
    ## Frees a NULL terminated cstringArray.
    var i = 0
    while a[i] != nil:
      dealloc(a[i])
      inc(i)
    dealloc(a)

when notJSnotNims:
  type
    PSafePoint = ptr TSafePoint
    TSafePoint {.compilerproc, final.} = object
      prev: PSafePoint # points to next safe point ON THE STACK
      status: int
      context: C_JmpBuf
    SafePoint = TSafePoint

when not defined(js):
  when declared(initAllocator):
    initAllocator()
  when hasThreadSupport:
    when hostOS != "standalone": include "system/threads"
  elif not defined(nogc) and not defined(nimscript):
    when not defined(useNimRtl) and not defined(createNimRtl): initStackBottom()
    when declared(initGC): initGC()

when notJSnotNims:
  proc setControlCHook*(hook: proc () {.noconv.})
    ## Allows you to override the behaviour of your application when CTRL+C
    ## is pressed. Only one such hook is supported.

  when not defined(noSignalHandler) and not defined(useNimRtl):
    proc unsetControlCHook*()
      ## Reverts a call to setControlCHook.

  when hostOS != "standalone":
    proc getStackTrace*(): string {.gcsafe.}
      ## Gets the current stack trace. This only works for debug builds.

    proc getStackTrace*(e: ref Exception): string {.gcsafe.}
      ## Gets the stack trace associated with `e`, which is the stack that
      ## lead to the `raise` statement. This only works for debug builds.

  {.push stackTrace: off, profiler: off.}
  when defined(memtracker):
    include "system/memtracker"

  when hostOS == "standalone":
    include "system/embedded"
  else:
    include "system/excpt"
  include "system/chcks"

  # we cannot compile this with stack tracing on
  # as it would recurse endlessly!
  when defined(nimNewIntegerOps):
    include "system/integerops"
  else:
    include "system/arithm"
  {.pop.}


when not defined(js):
  # this is a hack: without this when statement, you would get:
  # Error: system module needs: nimGCvisit
  {.pop.} # stackTrace: off, profiler: off



when notJSnotNims:
  when hostOS != "standalone" and hostOS != "any":
    include "system/dyncalls"

  import system/countbits_impl
  include "system/sets"

  when defined(gogc):
    const GenericSeqSize = (3 * sizeof(int))
  else:
    const GenericSeqSize = (2 * sizeof(int))

  proc getDiscriminant(aa: pointer, n: ptr TNimNode): uint =
    sysAssert(n.kind == nkCase, "getDiscriminant: node != nkCase")
    var d: uint
    var a = cast[uint](aa)
    case n.typ.size
    of 1: d = uint(cast[ptr uint8](a + uint(n.offset))[])
    of 2: d = uint(cast[ptr uint16](a + uint(n.offset))[])
    of 4: d = uint(cast[ptr uint32](a + uint(n.offset))[])
    of 8: d = uint(cast[ptr uint64](a + uint(n.offset))[])
    else:
      d = 0'u
      sysAssert(false, "getDiscriminant: invalid n.typ.size")
    return d

  proc selectBranch(aa: pointer, n: ptr TNimNode): ptr TNimNode =
    var discr = getDiscriminant(aa, n)
    if discr < cast[uint](n.len):
      result = n.sons[discr]
      if result == nil: result = n.sons[n.len]
      # n.sons[n.len] contains the `else` part (but may be nil)
    else:
      result = n.sons[n.len]

when notJSnotNims and hasAlloc:
  {.push profiler: off.}
  include "system/mmdisp"
  {.pop.}
  {.push stackTrace: off, profiler: off.}
  when not defined(nimSeqsV2):
    include "system/sysstr"
  {.pop.}

  include "system/strmantle"
  include "system/assign"

  when not defined(nimV2):
    include "system/repr"

when notJSnotNims and hasThreadSupport and hostOS != "standalone":
  include "system/channels_builtin"


when notJSnotNims and hostOS != "standalone":
  proc getCurrentException*(): ref Exception {.compilerRtl, inl, benign.} =
    ## Retrieves the current exception; if there is none, `nil` is returned.
    result = currException

  proc nimBorrowCurrentException(): ref Exception {.compilerRtl, inl, benign, nodestroy.} =
    # .nodestroy here so that we do not produce a write barrier as the
    # C codegen only uses it in a borrowed way:
    result = currException

  proc getCurrentExceptionMsg*(): string {.inline, benign.} =
    ## Retrieves the error message that was attached to the current
    ## exception; if there is none, `""` is returned.
    return if currException == nil: "" else: currException.msg

  proc setCurrentException*(exc: ref Exception) {.inline, benign.} =
    ## Sets the current exception.
    ##
    ## .. warning:: Only use this if you know what you are doing.
    currException = exc
elif defined(nimscript):
  proc getCurrentException*(): ref Exception {.compilerRtl.} = discard

when notJSnotNims:
  {.push stackTrace: off, profiler: off.}
  when (defined(profiler) or defined(memProfiler)):
    include "system/profiler"
  {.pop.}

  proc rawProc*[T: proc](x: T): pointer {.noSideEffect, inline.} =
    ## Retrieves the raw proc pointer of the closure `x`. This is
    ## useful for interfacing closures with C/C++, hash compuations, etc.
    when T is "closure":
      #[
      The conversion from function pointer to `void*` is a tricky topic, but this
      should work at least for c++ >= c++11, e.g. for `dlsym` support.
      refs: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=57869,
      https://stackoverflow.com/questions/14125474/casts-between-pointer-to-function-and-pointer-to-object-in-c-and-c
      ]#
      {.emit: """
      `result` = (void*)`x`.ClP_0;
      """.}
    else:
      {.error: "Only closure function and iterator are allowed!".}

  proc rawEnv*[T: proc](x: T): pointer {.noSideEffect, inline.} =
    ## Retrieves the raw environment pointer of the closure `x`. See also `rawProc`.
    when T is "closure":
      {.emit: """
      `result` = `x`.ClE_0;
      """.}
    else:
      {.error: "Only closure function and iterator are allowed!".}

  proc finished*[T: proc](x: T): bool {.noSideEffect, inline, magic: "Finished".} =
    ## It can be used to determine if a first class iterator has finished.
    when T is "iterator":
      {.emit: """
      `result` = ((NI*) `x`.ClE_0)[1] < 0;
      """.}
    else:
      {.error: "Only closure iterator is allowed!".}

from std/private/digitsutils import addInt
export addInt

when defined(js):
  include "system/jssys"
  include "system/reprjs"

proc quit*(errormsg: string, errorcode = QuitFailure) {.noreturn.} =
  ## A shorthand for `echo(errormsg); quit(errorcode)`.
  when defined(nimscript) or defined(js) or (hostOS == "standalone"):
    echo errormsg
  else:
    when nimvm:
      echo errormsg
    else:
      cstderr.rawWrite(errormsg)
      cstderr.rawWrite("\n")
  quit(errorcode)

{.pop.} # checks: off
# {.pop.} # hints: off

proc `/`*(x, y: int): float {.inline, noSideEffect.} =
  ## Division of integers that results in a float.
  ##
  ## See also:
  ## * `div <#div,int,int>`_
  ## * `mod <#mod,int,int>`_
  ##
  ## .. code-block:: Nim
  ##   echo 7 / 5 # => 1.4
  result = toFloat(x) / toFloat(y)

type
  BackwardsIndex* = distinct int ## Type that is constructed by `^` for
                                 ## reversed array accesses.
                                 ## (See `^ template <#^.t,int>`_)

template `^`*(x: int): BackwardsIndex = BackwardsIndex(x)
  ## Builtin `roof`:idx: operator that can be used for convenient array access.
  ## `a[^x]` is a shortcut for `a[a.len-x]`.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = [1, 3, 5, 7, 9]
  ##     b = "abcdefgh"
  ##
  ##   echo a[^1] # => 9
  ##   echo b[^2] # => g

template `..^`*(a, b: untyped): untyped =
  ## A shortcut for `.. ^` to avoid the common gotcha that a space between
  ## '..' and '^' is required.
  a .. ^b

template `..<`*(a, b: untyped): untyped =
  ## A shortcut for `a .. pred(b)`.
  ##
  ## .. code-block:: Nim
  ##   for i in 5 ..< 9:
  ##     echo i # => 5; 6; 7; 8
  a .. (when b is BackwardsIndex: succ(b) else: pred(b))

template spliceImpl(s, a, L, b: untyped): untyped =
  # make room for additional elements or cut:
  var shift = b.len - max(0,L)  # ignore negative slice size
  var newLen = s.len + shift
  if shift > 0:
    # enlarge:
    setLen(s, newLen)
    for i in countdown(newLen-1, a+b.len): movingCopy(s[i], s[i-shift])
  else:
    for i in countup(a+b.len, newLen-1): movingCopy(s[i], s[i-shift])
    # cut down:
    setLen(s, newLen)
  # fill the hole:
  for i in 0 ..< b.len: s[a+i] = b[i]

template `^^`(s, i: untyped): untyped =
  (when i is BackwardsIndex: s.len - int(i) else: int(i))

template `[]`*(s: string; i: int): char = arrGet(s, i)
template `[]=`*(s: string; i: int; val: char) = arrPut(s, i, val)

proc `[]`*[T, U: Ordinal](s: string, x: HSlice[T, U]): string {.inline.} =
  ## Slice operation for strings.
  ## Returns the inclusive range `[s[x.a], s[x.b]]`:
  ##
  ## .. code-block:: Nim
  ##    var s = "abcdef"
  ##    assert s[1..3] == "bcd"
  let a = s ^^ x.a
  let L = (s ^^ x.b) - a + 1
  result = newString(L)
  for i in 0 ..< L: result[i] = s[i + a]

proc `[]=`*[T, U: Ordinal](s: var string, x: HSlice[T, U], b: string) =
  ## Slice assignment for strings.
  ##
  ## If `b.len` is not exactly the number of elements that are referred to
  ## by `x`, a `splice`:idx: is performed:
  ##
  runnableExamples:
    var s = "abcdefgh"
    s[1 .. ^2] = "xyz"
    assert s == "axyzh"

  var a = s ^^ x.a
  var L = (s ^^ x.b) - a + 1
  if L == b.len:
    for i in 0..<L: s[i+a] = b[i]
  else:
    spliceImpl(s, a, L, b)

proc `[]`*[Idx, T; U, V: Ordinal](a: array[Idx, T], x: HSlice[U, V]): seq[T] =
  ## Slice operation for arrays.
  ## Returns the inclusive range `[a[x.a], a[x.b]]`:
  ##
  ## .. code-block:: Nim
  ##    var a = [1, 2, 3, 4]
  ##    assert a[0..2] == @[1, 2, 3]
  let xa = a ^^ x.a
  let L = (a ^^ x.b) - xa + 1
  result = newSeq[T](L)
  for i in 0..<L: result[i] = a[Idx(i + xa)]

proc `[]=`*[Idx, T; U, V: Ordinal](a: var array[Idx, T], x: HSlice[U, V], b: openArray[T]) =
  ## Slice assignment for arrays.
  ##
  ## .. code-block:: Nim
  ##   var a = [10, 20, 30, 40, 50]
  ##   a[1..2] = @[99, 88]
  ##   assert a == [10, 99, 88, 40, 50]
  let xa = a ^^ x.a
  let L = (a ^^ x.b) - xa + 1
  if L == b.len:
    for i in 0..<L: a[Idx(i + xa)] = b[i]
  else:
    sysFatal(RangeDefect, "different lengths for slice assignment")

proc `[]`*[T; U, V: Ordinal](s: openArray[T], x: HSlice[U, V]): seq[T] =
  ## Slice operation for sequences.
  ## Returns the inclusive range `[s[x.a], s[x.b]]`:
  ##
  ## .. code-block:: Nim
  ##    var s = @[1, 2, 3, 4]
  ##    assert s[0..2] == @[1, 2, 3]
  let a = s ^^ x.a
  let L = (s ^^ x.b) - a + 1
  newSeq(result, L)
  for i in 0 ..< L: result[i] = s[i + a]

proc `[]=`*[T; U, V: Ordinal](s: var seq[T], x: HSlice[U, V], b: openArray[T]) =
  ## Slice assignment for sequences.
  ##
  ## If `b.len` is not exactly the number of elements that are referred to
  ## by `x`, a `splice`:idx: is performed.
  runnableExamples:
    var s = @"abcdefgh"
    s[1 .. ^2] = @"xyz"
    assert s == @"axyzh"

  let a = s ^^ x.a
  let L = (s ^^ x.b) - a + 1
  if L == b.len:
    for i in 0 ..< L: s[i+a] = b[i]
  else:
    spliceImpl(s, a, L, b)

proc `[]`*[T](s: openArray[T]; i: BackwardsIndex): T {.inline.} =
  system.`[]`(s, s.len - int(i))

proc `[]`*[Idx, T](a: array[Idx, T]; i: BackwardsIndex): T {.inline.} =
  a[Idx(a.len - int(i) + int low(a))]
proc `[]`*(s: string; i: BackwardsIndex): char {.inline.} = s[s.len - int(i)]

proc `[]`*[T](s: var openArray[T]; i: BackwardsIndex): var T {.inline.} =
  system.`[]`(s, s.len - int(i))
proc `[]`*[Idx, T](a: var array[Idx, T]; i: BackwardsIndex): var T {.inline.} =
  a[Idx(a.len - int(i) + int low(a))]
proc `[]`*(s: var string; i: BackwardsIndex): var char {.inline.} = s[s.len - int(i)]

proc `[]=`*[T](s: var openArray[T]; i: BackwardsIndex; x: T) {.inline.} =
  system.`[]=`(s, s.len - int(i), x)
proc `[]=`*[Idx, T](a: var array[Idx, T]; i: BackwardsIndex; x: T) {.inline.} =
  a[Idx(a.len - int(i) + int low(a))] = x
proc `[]=`*(s: var string; i: BackwardsIndex; x: char) {.inline.} =
  s[s.len - int(i)] = x

proc slurp*(filename: string): string {.magic: "Slurp".}
  ## This is an alias for `staticRead <#staticRead,string>`_.

proc staticRead*(filename: string): string {.magic: "Slurp".}
  ## Compile-time `readFile <io.html#readFile,string>`_ proc for easy
  ## `resource`:idx: embedding:
  ##
  ## The maximum file size limit that `staticRead` and `slurp` can read is
  ## near or equal to the *free* memory of the device you are using to compile.
  ##
  ## .. code-block:: Nim
  ##     const myResource = staticRead"mydatafile.bin"
  ##
  ## `slurp <#slurp,string>`_ is an alias for `staticRead`.

proc gorge*(command: string, input = "", cache = ""): string {.
  magic: "StaticExec".} = discard
  ## This is an alias for `staticExec <#staticExec,string,string,string>`_.

proc staticExec*(command: string, input = "", cache = ""): string {.
  magic: "StaticExec".} = discard
  ## Executes an external process at compile-time and returns its text output
  ## (stdout + stderr).
  ##
  ## If `input` is not an empty string, it will be passed as a standard input
  ## to the executed program.
  ##
  ## .. code-block:: Nim
  ##     const buildInfo = "Revision " & staticExec("git rev-parse HEAD") &
  ##                       "\nCompiled on " & staticExec("uname -v")
  ##
  ## `gorge <#gorge,string,string,string>`_ is an alias for `staticExec`.
  ##
  ## Note that you can use this proc inside a pragma like
  ## `passc <manual.html#implementation-specific-pragmas-passc-pragma>`_ or
  ## `passl <manual.html#implementation-specific-pragmas-passl-pragma>`_.
  ##
  ## If `cache` is not empty, the results of `staticExec` are cached within
  ## the `nimcache` directory. Use `--forceBuild` to get rid of this caching
  ## behaviour then. `command & input & cache` (the concatenated string) is
  ## used to determine whether the entry in the cache is still valid. You can
  ## use versioning information for `cache`:
  ##
  ## .. code-block:: Nim
  ##     const stateMachine = staticExec("dfaoptimizer", "input", "0.8.0")

proc gorgeEx*(command: string, input = "", cache = ""): tuple[output: string,
                                                              exitCode: int] =
  ## Similar to `gorge <#gorge,string,string,string>`_ but also returns the
  ## precious exit code.
  discard


proc `+=`*[T: float|float32|float64] (x: var T, y: T) {.
  inline, noSideEffect.} =
  ## Increments in place a floating point number.
  x = x + y

proc `-=`*[T: float|float32|float64] (x: var T, y: T) {.
  inline, noSideEffect.} =
  ## Decrements in place a floating point number.
  x = x - y

proc `*=`*[T: float|float32|float64] (x: var T, y: T) {.
  inline, noSideEffect.} =
  ## Multiplies in place a floating point number.
  x = x * y

proc `/=`*(x: var float64, y: float64) {.inline, noSideEffect.} =
  ## Divides in place a floating point number.
  x = x / y

proc `/=`*[T: float|float32](x: var T, y: T) {.inline, noSideEffect.} =
  ## Divides in place a floating point number.
  x = x / y

proc `&=`*(x: var string, y: string) {.magic: "AppendStrStr", noSideEffect.}
  ## Appends in place to a string.
  ##
  ## .. code-block:: Nim
  ##   var a = "abc"
  ##   a &= "de" # a <- "abcde"

template `&=`*(x, y: typed) =
  ## Generic 'sink' operator for Nim.
  ##
  ## For files an alias for `write`.
  ## If not specialized further, an alias for `add`.
  add(x, y)
when declared(File):
  template `&=`*(f: File, x: typed) = write(f, x)

template currentSourcePath*: string = instantiationInfo(-1, true).filename
  ## Returns the full file-system path of the current source.
  ##
  ## To get the directory containing the current source, use it with
  ## `os.parentDir() <os.html#parentDir%2Cstring>`_ as `currentSourcePath.parentDir()`.
  ##
  ## The path returned by this template is set at compile time.
  ##
  ## See the docstring of `macros.getProjectPath() <macros.html#getProjectPath>`_
  ## for an example to see the distinction between the `currentSourcePath`
  ## and `getProjectPath`.
  ##
  ## See also:
  ## * `getCurrentDir proc <os.html#getCurrentDir>`_

when compileOption("rangechecks"):
  template rangeCheck*(cond) =
    ## Helper for performing user-defined range checks.
    ## Such checks will be performed only when the `rangechecks`
    ## compile-time option is enabled.
    if not cond: sysFatal(RangeDefect, "range check failed")
else:
  template rangeCheck*(cond) = discard

proc shallow*[T](s: var seq[T]) {.noSideEffect, inline.} =
  ## Marks a sequence `s` as `shallow`:idx:. Subsequent assignments will not
  ## perform deep copies of `s`.
  ##
  ## This is only useful for optimization purposes.
  if s.len == 0: return
  when not defined(js) and not defined(nimscript) and not defined(nimSeqsV2):
    var s = cast[PGenericSeq](s)
    s.reserved = s.reserved or seqShallowFlag

proc shallow*(s: var string) {.noSideEffect, inline.} =
  ## Marks a string `s` as `shallow`:idx:. Subsequent assignments will not
  ## perform deep copies of `s`.
  ##
  ## This is only useful for optimization purposes.
  when not defined(js) and not defined(nimscript) and not defined(nimSeqsV2):
    var s = cast[PGenericSeq](s)
    if s == nil:
      s = cast[PGenericSeq](newString(0))
    # string literals cannot become 'shallow':
    if (s.reserved and strlitFlag) == 0:
      s.reserved = s.reserved or seqShallowFlag

type
  NimNodeObj = object

  NimNode* {.magic: "PNimrodNode".} = ref NimNodeObj
    ## Represents a Nim AST node. Macros operate on this type.

when defined(nimV2):
  import system/repr_v2
  export repr_v2

macro varargsLen*(x: varargs[untyped]): int {.since: (1, 1).} =
  ## returns number of variadic arguments in `x`
  proc varargsLenImpl(x: NimNode): NimNode {.magic: "LengthOpenArray", noSideEffect.}
  varargsLenImpl(x)

when false:
  template eval*(blk: typed): typed =
    ## Executes a block of code at compile time just as if it was a macro.
    ##
    ## Optionally, the block can return an AST tree that will replace the
    ## eval expression.
    macro payload: typed {.gensym.} = blk
    payload()

when hasAlloc or defined(nimscript):
  proc insert*(x: var string, item: string, i = 0.Natural) {.noSideEffect.} =
    ## Inserts `item` into `x` at position `i`.
    ##
    ## .. code-block:: Nim
    ##   var a = "abc"
    ##   a.insert("zz", 0) # a <- "zzabc"
    var xl = x.len
    setLen(x, xl+item.len)
    var j = xl-1
    while j >= i:
      shallowCopy(x[j+item.len], x[j])
      dec(j)
    j = 0
    while j < item.len:
      x[j+i] = item[j]
      inc(j)

when declared(initDebugger):
  initDebugger()

proc addEscapedChar*(s: var string, c: char) {.noSideEffect, inline.} =
  ## Adds a char to string `s` and applies the following escaping:
  ##
  ## * replaces any ``\`` by `\\`
  ## * replaces any `'` by `\'`
  ## * replaces any `"` by `\"`
  ## * replaces any `\a` by `\\a`
  ## * replaces any `\b` by `\\b`
  ## * replaces any `\t` by `\\t`
  ## * replaces any `\n` by `\\n`
  ## * replaces any `\v` by `\\v`
  ## * replaces any `\f` by `\\f`
  ## * replaces any `\r` by `\\r`
  ## * replaces any `\e` by `\\e`
  ## * replaces any other character not in the set `{\21..\126}`
  ##   by `\xHH` where `HH` is its hexadecimal value
  ##
  ## The procedure has been designed so that its output is usable for many
  ## different common syntaxes.
  ##
  ## .. warning:: This is **not correct** for producing ANSI C code!
  ##
  case c
  of '\a': s.add "\\a" # \x07
  of '\b': s.add "\\b" # \x08
  of '\t': s.add "\\t" # \x09
  of '\n': s.add "\\n" # \x0A
  of '\v': s.add "\\v" # \x0B
  of '\f': s.add "\\f" # \x0C
  of '\r': (when defined(nimLegacyAddEscapedCharx0D): s.add "\\c" else: s.add "\\r") # \x0D
  of '\e': s.add "\\e" # \x1B
  of '\\': s.add("\\\\")
  of '\'': s.add("\\'")
  of '\"': s.add("\\\"")
  of {'\32'..'\126'} - {'\\', '\'', '\"'}: s.add(c)
  else:
    s.add("\\x")
    const HexChars = "0123456789ABCDEF"
    let n = ord(c)
    s.add(HexChars[int((n and 0xF0) shr 4)])
    s.add(HexChars[int(n and 0xF)])

proc addQuoted*[T](s: var string, x: T) =
  ## Appends `x` to string `s` in place, applying quoting and escaping
  ## if `x` is a string or char.
  ##
  ## See `addEscapedChar <#addEscapedChar,string,char>`_
  ## for the escaping scheme. When `x` is a string, characters in the
  ## range `{\128..\255}` are never escaped so that multibyte UTF-8
  ## characters are untouched (note that this behavior is different from
  ## `addEscapedChar`).
  ##
  ## The Nim standard library uses this function on the elements of
  ## collections when producing a string representation of a collection.
  ## It is recommended to use this function as well for user-side collections.
  ## Users may overload `addQuoted` for custom (string-like) types if
  ## they want to implement a customized element representation.
  ##
  ## .. code-block:: Nim
  ##   var tmp = ""
  ##   tmp.addQuoted(1)
  ##   tmp.add(", ")
  ##   tmp.addQuoted("string")
  ##   tmp.add(", ")
  ##   tmp.addQuoted('c')
  ##   assert(tmp == """1, "string", 'c'""")
  when T is string or T is cstring:
    s.add("\"")
    for c in x:
      # Only ASCII chars are escaped to avoid butchering
      # multibyte UTF-8 characters.
      if c <= 127.char:
        s.addEscapedChar(c)
      else:
        s.add c
    s.add("\"")
  elif T is char:
    s.add("'")
    s.addEscapedChar(x)
    s.add("'")
  # prevent temporary string allocation
  elif T is SomeInteger:
    s.addInt(x)
  elif T is SomeFloat:
    s.addFloat(x)
  elif compiles(s.add(x)):
    s.add(x)
  else:
    s.add($x)

proc locals*(): RootObj {.magic: "Plugin", noSideEffect.} =
  ## Generates a tuple constructor expression listing all the local variables
  ## in the current scope.
  ##
  ## This is quite fast as it does not rely
  ## on any debug or runtime information. Note that in contrast to what
  ## the official signature says, the return type is *not* `RootObj` but a
  ## tuple of a structure that depends on the current scope. Example:
  ##
  ## .. code-block:: Nim
  ##   proc testLocals() =
  ##     var
  ##       a = "something"
  ##       b = 4
  ##       c = locals()
  ##       d = "super!"
  ##
  ##     b = 1
  ##     for name, value in fieldPairs(c):
  ##       echo "name ", name, " with value ", value
  ##     echo "B is ", b
  ##   # -> name a with value something
  ##   # -> name b with value 4
  ##   # -> B is 1
  discard

when hasAlloc and notJSnotNims:
  # XXX how to implement 'deepCopy' is an open problem.
  proc deepCopy*[T](x: var T, y: T) {.noSideEffect, magic: "DeepCopy".} =
    ## Performs a deep copy of `y` and copies it into `x`.
    ##
    ## This is also used by the code generator
    ## for the implementation of `spawn`.
    ##
    ## For `--gc:arc` or `--gc:orc` deepcopy support has to be enabled
    ## via `--deepcopy:on`.
    discard

  proc deepCopy*[T](y: T): T =
    ## Convenience wrapper around `deepCopy` overload.
    deepCopy(result, y)

  include "system/deepcopy"

proc procCall*(x: untyped) {.magic: "ProcCall", compileTime.} =
  ## Special magic to prohibit dynamic binding for `method`:idx: calls.
  ## This is similar to `super`:idx: in ordinary OO languages.
  ##
  ## .. code-block:: Nim
  ##   # 'someMethod' will be resolved fully statically:
  ##   procCall someMethod(a, b)
  discard


proc `==`*(x, y: cstring): bool {.magic: "EqCString", noSideEffect,
                                   inline.} =
  ## Checks for equality between two `cstring` variables.
  proc strcmp(a, b: cstring): cint {.noSideEffect,
    importc, header: "<string.h>".}
  if pointer(x) == pointer(y): result = true
  elif x.isNil or y.isNil: result = false
  else: result = strcmp(x, y) == 0

when true: # xxx PRTEMP remove
  # bug #9149; ensure that 'typeof(nil)' does not match *too* well by using 'typeof(nil) | typeof(nil)',
  # especially for converters, see tests/overload/tconverter_to_string.nim
  # Eventually we will be able to remove this hack completely.
  proc `==`*(x: string; y: typeof(nil) | typeof(nil)): bool {.
      error: "'nil' is now invalid for 'string'".} =
    discard
  proc `==`*(x: typeof(nil) | typeof(nil); y: string): bool {.
      error: "'nil' is now invalid for 'string'".} =
    discard

template closureScope*(body: untyped): untyped =
  ## Useful when creating a closure in a loop to capture local loop variables by
  ## their current iteration values.
  ##
  ## Note: This template may not work in some cases, use
  ## `capture <sugar.html#capture.m,varargs[typed],untyped>`_ instead.
  ##
  ## Example:
  ##
  ## .. code-block:: Nim
  ##   var myClosure : proc()
  ##   # without closureScope:
  ##   for i in 0 .. 5:
  ##     let j = i
  ##     if j == 3:
  ##       myClosure = proc() = echo j
  ##   myClosure() # outputs 5. `j` is changed after closure creation
  ##   # with closureScope:
  ##   for i in 0 .. 5:
  ##     closureScope: # Everything in this scope is locked after closure creation
  ##       let j = i
  ##       if j == 3:
  ##         myClosure = proc() = echo j
  ##   myClosure() # outputs 3
  (proc() = body)()

template once*(body: untyped): untyped =
  ## Executes a block of code only once (the first time the block is reached).
  ##
  ## .. code-block:: Nim
  ##
  ##  proc draw(t: Triangle) =
  ##    once:
  ##      graphicsInit()
  ##    line(t.p1, t.p2)
  ##    line(t.p2, t.p3)
  ##    line(t.p3, t.p1)
  ##
  var alreadyExecuted {.global.} = false
  if not alreadyExecuted:
    alreadyExecuted = true
    body

{.pop.} # warning[GcMem]: off, warning[Uninit]: off

proc substr*(s: string, first, last: int): string =
  ## Copies a slice of `s` into a new string and returns this new
  ## string.
  ##
  ## The bounds `first` and `last` denote the indices of
  ## the first and last characters that shall be copied. If `last`
  ## is omitted, it is treated as `high(s)`. If `last >= s.len`, `s.len`
  ## is used instead: This means `substr` can also be used to `cut`:idx:
  ## or `limit`:idx: a string's length.
  runnableExamples:
    let a = "abcdefgh"
    assert a.substr(2, 5) == "cdef"
    assert a.substr(2) == "cdefgh"
    assert a.substr(5, 99) == "fgh"

  let first = max(first, 0)
  let L = max(min(last, high(s)) - first + 1, 0)
  result = newString(L)
  for i in 0 .. L-1:
    result[i] = s[i+first]

proc substr*(s: string, first = 0): string =
  result = substr(s, first, high(s))

when defined(nimconfig):
  include "system/nimscript"

when not defined(js):
  proc toOpenArray*[T](x: ptr UncheckedArray[T]; first, last: int): openArray[T] {.
    magic: "Slice".}
  when defined(nimToOpenArrayCString):
    proc toOpenArray*(x: cstring; first, last: int): openArray[char] {.
      magic: "Slice".}
    proc toOpenArrayByte*(x: cstring; first, last: int): openArray[byte] {.
      magic: "Slice".}

proc toOpenArray*[T](x: seq[T]; first, last: int): openArray[T] {.
  magic: "Slice".}
proc toOpenArray*[T](x: openArray[T]; first, last: int): openArray[T] {.
  magic: "Slice".}
proc toOpenArray*[I, T](x: array[I, T]; first, last: I): openArray[T] {.
  magic: "Slice".}
proc toOpenArray*(x: string; first, last: int): openArray[char] {.
  magic: "Slice".}

proc toOpenArrayByte*(x: string; first, last: int): openArray[byte] {.
  magic: "Slice".}
proc toOpenArrayByte*(x: openArray[char]; first, last: int): openArray[byte] {.
  magic: "Slice".}
proc toOpenArrayByte*(x: seq[char]; first, last: int): openArray[byte] {.
  magic: "Slice".}

type
  ForLoopStmt* {.compilerproc.} = object ## \
    ## A special type that marks a macro as a `for-loop macro`:idx:.
    ## See `"For Loop Macro" <manual.html#macros-for-loop-macro>`_.

when defined(genode):
  var componentConstructHook*: proc (env: GenodeEnv) {.nimcall.}
    ## Hook into the Genode component bootstrap process.
    ##
    ## This hook is called after all globals are initialized.
    ## When this hook is set the component will not automatically exit,
    ## call `quit` explicitly to do so. This is the only available method
    ## of accessing the initial Genode environment.

  proc nim_component_construct(env: GenodeEnv) {.exportc.} =
    ## Procedure called during `Component::construct` by the loader.
    if componentConstructHook.isNil:
      env.quit(programResult)
        # No native Genode application initialization,
        # exit as would POSIX.
    else:
      componentConstructHook(env)
        # Perform application initialization
        # and return to thread entrypoint.


import system/widestrs
export widestrs

import system/io
export io

when not defined(createNimHcr) and not defined(nimscript):
  include nimhcr

when notJSnotNims and not defined(nimSeqsV2):
  proc prepareMutation*(s: var string) {.inline.} =
    ## String literals (e.g. "abc", etc) in the ARC/ORC mode are "copy on write",
    ## therefore you should call `prepareMutation` before modifying the strings
    ## via `addr`.
    runnableExamples("--gc:arc"):
      var x = "abc"
      var y = "defgh"
      prepareMutation(y) # without this, you may get a `SIGBUS` or `SIGSEGV`
      moveMem(addr y[0], addr x[0], x.len)
      assert y == "abcgh"
    discard
