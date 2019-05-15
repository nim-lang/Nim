=========================
Nim Experimental Features
=========================

:Authors: Andreas Rumpf
:Version: |nimversion|

.. contents::


About this document
===================

This document describes features of Nim that are to be considered experimental.
Some of these are not covered by the ``.experimental`` pragma or
``--experimental`` switch because they are already behind a special syntax and
one may want to use Nim libraries using these features without using them
oneself.

**Note**: Unless otherwise indicated, these features are not to be removed,
but refined and overhauled.


Package level objects
=====================

Every Nim module resides in a (nimble) package. An object type can be attached
to the package it resides in. If that is done, the type can be referenced from
other modules as an `incomplete`:idx: object type. This feature allows to
break up recursive type dependencies accross module boundaries. Incomplete
object types are always passed ``byref`` and can only be used in pointer like
contexts (``var/ref/ptr IncompleteObject``) in general since the compiler does
not yet know the size of the object. To complete an incomplete object
the ``package`` pragma has to be used. ``package`` implies ``byref``.

As long as a type ``T`` is incomplete, neither ``sizeof(T)`` nor runtime
type information for ``T`` is available.


Example:

.. code-block:: nim

  # module A (in an arbitrary package)
  type
    Pack.SomeObject = object ## declare as incomplete object of package 'Pack'
    Triple = object
      a, b, c: ref SomeObject ## pointers to incomplete objects are allowed

  ## Incomplete objects can be used as parameters:
  proc myproc(x: SomeObject) = discard


.. code-block:: nim

  # module B (in package "Pack")
  type
    SomeObject* {.package.} = object ## Use 'package' to complete the object
      s, t: string
      x, y: int


Void type
=========

The ``void`` type denotes the absence of any type. Parameters of
type ``void`` are treated as non-existent, ``void`` as a return type means that
the procedure does not return a value:

.. code-block:: nim
  proc nothing(x, y: void): void =
    echo "ha"

  nothing() # writes "ha" to stdout

The ``void`` type is particularly useful for generic code:

.. code-block:: nim
  proc callProc[T](p: proc (x: T), x: T) =
    when T is void:
      p()
    else:
      p(x)

  proc intProc(x: int) = discard
  proc emptyProc() = discard

  callProc[int](intProc, 12)
  callProc[void](emptyProc)

However, a ``void`` type cannot be inferred in generic code:

.. code-block:: nim
  callProc(emptyProc)
  # Error: type mismatch: got (proc ())
  # but expected one of:
  # callProc(p: proc (T), x: T)

The ``void`` type is only valid for parameters and return types; other symbols
cannot have the type ``void``.



Covariance
==========

Covariance in Nim can be introduced only though pointer-like types such
as ``ptr`` and ``ref``. Sequence, Array and OpenArray types, instantiated
with pointer-like types will be considered covariant if and only if they
are also immutable. The introduction of a ``var`` modifier or additional
``ptr`` or ``ref`` indirections would result in invariant treatment of
these types.

``proc`` types are currently always invariant, but future versions of Nim
may relax this rule.

User-defined generic types may also be covariant with respect to some of
their parameters. By default, all generic params are considered invariant,
but you may choose the apply the prefix modifier ``in`` to a parameter to
make it contravariant or ``out`` to make it covariant:

.. code-block:: nim
  type
    AnnotatedPtr[out T] =
      metadata: MyTypeInfo
      p: ref T

    RingBuffer[out T] =
      startPos: int
      data: seq[T]

    Action {.importcpp: "std::function<void ('0)>".} [in T] = object

When the designated generic parameter is used to instantiate a pointer-like
type as in the case of `AnnotatedPtr` above, the resulting generic type will
also have pointer-like covariance:

.. code-block:: nim
  type
    GuiWidget = object of RootObj
    Button = object of GuiWidget
    ComboBox = object of GuiWidget

  var
    widgetPtr: AnnotatedPtr[GuiWidget]
    buttonPtr: AnnotatedPtr[Button]

  ...

  proc drawWidget[T](x: AnnotatedPtr[GuiWidget]) = ...

  # you can call procs expecting base types by supplying a derived type
  drawWidget(buttonPtr)

  # and you can convert more-specific pointer types to more general ones
  widgetPtr = buttonPtr

Just like with regular pointers, covariance will be enabled only for immutable
values:

.. code-block:: nim
  proc makeComboBox[T](x: var AnnotatedPtr[GuiWidget]) =
    x.p = new(ComboBox)

  makeComboBox(buttonPtr) # Error, AnnotatedPtr[Button] cannot be modified
                          # to point to a ComboBox

On the other hand, in the `RingBuffer` example above, the designated generic
param is used to instantiate the non-pointer ``seq`` type, which means that
the resulting generic type will have covariance that mimics an array or
sequence (i.e. it will be covariant only when instantiated with ``ptr`` and
``ref`` types):

.. code-block:: nim

  type
    Base = object of RootObj
    Derived = object of Base

  proc consumeBaseValues(b: RingBuffer[Base]) = ...

  var derivedValues: RingBuffer[Derived]

  consumeBaseValues(derivedValues) # Error, Base and Derived values may differ
                                   # in size

  proc consumeBasePointers(b: RingBuffer[ptr Base]) = ...

  var derivedPointers: RingBuffer[ptr Derived]

  consumeBaseValues(derivedPointers) # This is legal

Please note that Nim will treat the user-defined pointer-like types as
proper alternatives to the built-in pointer types. That is, types such
as `seq[AnnotatedPtr[T]]` or `RingBuffer[AnnotatedPtr[T]]` will also be
considered covariant and you can create new pointer-like types by instantiating
other user-defined pointer-like types.

The contravariant parameters introduced with the ``in`` modifier are currently
useful only when interfacing with imported types having such semantics.


Automatic dereferencing
=======================

If the `experimental mode <#pragmas-experimental-pragma>`_ is active and no other match
is found, the first argument ``a`` is dereferenced automatically if it's a
pointer type and overloading resolution is tried with ``a[]`` instead.


Automatic self insertions
=========================

**Note**: The ``.this`` pragma is deprecated and should not be used anymore.

Starting with version 0.14 of the language, Nim supports ``field`` as a
shortcut for ``self.field`` comparable to the `this`:idx: keyword in Java
or C++. This feature has to be explicitly enabled via a ``{.this: self.}``
statement pragma (instead of ``self`` any other identifier can be used too).
This pragma is active for the rest of the module:

.. code-block:: nim
  type
    Parent = object of RootObj
      parentField: int
    Child = object of Parent
      childField: int

  {.this: self.}
  proc sumFields(self: Child): int =
    result = parentField + childField
    # is rewritten to:
    # result = self.parentField + self.childField

In addition to fields, routine applications are also rewritten, but only
if no other interpretation of the call is possible:

.. code-block:: nim
  proc test(self: Child) =
    echo childField, " ", sumFields()
    # is rewritten to:
    echo self.childField, " ", sumFields(self)
    # but NOT rewritten to:
    echo self, self.childField, " ", sumFields(self)


Do notation
===========

As a special more convenient notation, proc expressions involved in procedure
calls can use the ``do`` keyword:

.. code-block:: nim
  sort(cities) do (x,y: string) -> int:
    cmp(x.len, y.len)

  # Less parenthesis using the method plus command syntax:
  cities = cities.map do (x:string) -> string:
    "City of " & x

  # In macros, the do notation is often used for quasi-quoting
  macroResults.add quote do:
    if not `ex`:
      echo `info`, ": Check failed: ", `expString`

``do`` is written after the parentheses enclosing the regular proc params.
The proc expression represented by the do block is appended to them.
In calls using the command syntax, the do block will bind to the immediately
preceeding expression, transforming it in a call.

``do`` with parentheses is an anonymous ``proc``; however a ``do`` without
parentheses is just a block of code. The ``do`` notation can be used to
pass multiple blocks to a macro:

.. code-block:: nim
  macro performWithUndo(task, undo: untyped) = ...

  performWithUndo do:
    # multiple-line block of code
    # to perform the task
  do:
    # code to undo it


Special Operators
=================

dot operators
-------------

**Note**: Dot operators are still experimental and so need to be enabled
via ``{.experimental: "dotOperators".}``.

Nim offers a special family of dot operators that can be used to
intercept and rewrite proc call and field access attempts, referring
to previously undeclared symbol names. They can be used to provide a
fluent interface to objects lying outside the static confines of the
type system such as values from dynamic scripting languages
or dynamic file formats such as JSON or XML.

When Nim encounters an expression that cannot be resolved by the
standard overload resolution rules, the current scope will be searched
for a dot operator that can be matched against a re-written form of
the expression, where the unknown field or proc name is passed to
an ``untyped`` parameter:

.. code-block:: nim
  a.b # becomes `.`(a, b)
  a.b(c, d) # becomes `.`(a, b, c, d)

The matched dot operators can be symbols of any callable kind (procs,
templates and macros), depending on the desired effect:

.. code-block:: nim
  template `.` (js: PJsonNode, field: untyped): JSON = js[astToStr(field)]

  var js = parseJson("{ x: 1, y: 2}")
  echo js.x # outputs 1
  echo js.y # outputs 2

The following dot operators are available:

operator `.`
------------
This operator will be matched against both field accesses and method calls.

operator `.()`
---------------
This operator will be matched exclusively against method calls. It has higher
precedence than the `.` operator and this allows one to handle expressions like
`x.y` and `x.y()` differently if one is interfacing with a scripting language
for example.

operator `.=`
-------------
This operator will be matched against assignments to missing fields.

.. code-block:: nim
  a.b = c # becomes `.=`(a, b, c)



Concepts
========

Concepts, also known as "user-defined type classes", are used to specify an
arbitrary set of requirements that the matched type must satisfy.

Concepts are written in the following form:

.. code-block:: nim
  type
    Comparable = concept x, y
      (x < y) is bool

    Stack[T] = concept s, var v
      s.pop() is T
      v.push(T)

      s.len is Ordinal

      for value in s:
        value is T

The concept is a match if:

a) all of the expressions within the body can be compiled for the tested type
b) all statically evaluable boolean expressions in the body must be true

The identifiers following the ``concept`` keyword represent instances of the
currently matched type. You can apply any of the standard type modifiers such
as ``var``, ``ref``, ``ptr`` and ``static`` to denote a more specific type of
instance. You can also apply the `type` modifier to create a named instance of
the type itself:

.. code-block:: nim
  type
    MyConcept = concept x, var v, ref r, ptr p, static s, type T
      ...

Within the concept body, types can appear in positions where ordinary values
and parameters are expected. This provides a more convenient way to check for
the presence of callable symbols with specific signatures:

.. code-block:: nim
  type
    OutputStream = concept var s
      s.write(string)

In order to check for symbols accepting ``type`` params, you must prefix
the type with the explicit ``type`` modifier. The named instance of the
type, following the ``concept`` keyword is also considered to have the
explicit modifier and will be matched only as a type.

.. code-block:: nim
  type
    # Let's imagine a user-defined casting framework with operators
    # such as `val.to(string)` and `val.to(JSonValue)`. We can test
    # for these with the following concept:
    MyCastables = concept x
      x.to(type string)
      x.to(type JSonValue)

    # Let's define a couple of concepts, known from Algebra:
    AdditiveMonoid* = concept x, y, type T
      x + y is T
      T.zero is T # require a proc such as `int.zero` or 'Position.zero'

    AdditiveGroup* = concept x, y, type T
      x is AdditiveMonoid
      -x is T
      x - y is T

Please note that the ``is`` operator allows one to easily verify the precise
type signatures of the required operations, but since type inference and
default parameters are still applied in the concept body, it's also possible
to describe usage protocols that do not reveal implementation details.

Much like generics, concepts are instantiated exactly once for each tested type
and any static code included within the body is executed only once.


Concept diagnostics
-------------------

By default, the compiler will report the matching errors in concepts only when
no other overload can be selected and a normal compilation error is produced.
When you need to understand why the compiler is not matching a particular
concept and, as a result, a wrong overload is selected, you can apply the
``explain`` pragma to either the concept body or a particular call-site.

.. code-block:: nim
  type
    MyConcept {.explain.} = concept ...

  overloadedProc(x, y, z) {.explain.}

This will provide Hints in the compiler output either every time the concept is
not matched or only on the particular call-site.


Generic concepts and type binding rules
---------------------------------------

The concept types can be parametric just like the regular generic types:

.. code-block:: nim
  ### matrixalgo.nim

  import typetraits

  type
    AnyMatrix*[R, C: static int; T] = concept m, var mvar, type M
      M.ValueType is T
      M.Rows == R
      M.Cols == C

      m[int, int] is T
      mvar[int, int] = T

      type TransposedType = stripGenericParams(M)[C, R, T]

    AnySquareMatrix*[N: static int, T] = AnyMatrix[N, N, T]

    AnyTransform3D* = AnyMatrix[4, 4, float]

  proc transposed*(m: AnyMatrix): m.TransposedType =
    for r in 0 ..< m.R:
      for c in 0 ..< m.C:
        result[r, c] = m[c, r]

  proc determinant*(m: AnySquareMatrix): int =
    ...

  proc setPerspectiveProjection*(m: AnyTransform3D) =
    ...

  --------------
  ### matrix.nim

  type
    Matrix*[M, N: static int; T] = object
      data: array[M*N, T]

  proc `[]`*(M: Matrix; m, n: int): M.T =
    M.data[m * M.N + n]

  proc `[]=`*(M: var Matrix; m, n: int; v: M.T) =
    M.data[m * M.N + n] = v

  # Adapt the Matrix type to the concept's requirements
  template Rows*(M: typedesc[Matrix]): int = M.M
  template Cols*(M: typedesc[Matrix]): int = M.N
  template ValueType*(M: typedesc[Matrix]): typedesc = M.T

  -------------
  ### usage.nim

  import matrix, matrixalgo

  var
    m: Matrix[3, 3, int]
    projectionMatrix: Matrix[4, 4, float]

  echo m.transposed.determinant
  setPerspectiveProjection projectionMatrix

When the concept type is matched against a concrete type, the unbound type
parameters are inferred from the body of the concept in a way that closely
resembles the way generic parameters of callable symbols are inferred on
call sites.

Unbound types can appear both as params to calls such as `s.push(T)` and
on the right-hand side of the ``is`` operator in cases such as `x.pop is T`
and `x.data is seq[T]`.

Unbound static params will be inferred from expressions involving the `==`
operator and also when types dependent on them are being matched:

.. code-block:: nim
  type
    MatrixReducer[M, N: static int; T] = concept x
      x.reduce(SquareMatrix[N, T]) is array[M, int]

The Nim compiler includes a simple linear equation solver, allowing it to
infer static params in some situations where integer arithmetic is involved.

Just like in regular type classes, Nim discriminates between ``bind once``
and ``bind many`` types when matching the concept. You can add the ``distinct``
modifier to any of the otherwise inferable types to get a type that will be
matched without permanently inferring it. This may be useful when you need
to match several procs accepting the same wide class of types:

.. code-block:: nim
  type
    Enumerable[T] = concept e
      for v in e:
        v is T

  type
    MyConcept = concept o
      # this could be inferred to a type such as Enumerable[int]
      o.foo is distinct Enumerable

      # this could be inferred to a different type such as Enumerable[float]
      o.bar is distinct Enumerable

      # it's also possible to give an alias name to a `bind many` type class
      type Enum = distinct Enumerable
      o.baz is Enum

On the other hand, using ``bind once`` types allows you to test for equivalent
types used in multiple signatures, without actually requiring any concrete
types, thus allowing you to encode implementation-defined types:

.. code-block:: nim
  type
    MyConcept = concept x
      type T1 = auto
      x.foo(T1)
      x.bar(T1) # both procs must accept the same type

      type T2 = seq[SomeNumber]
      x.alpha(T2)
      x.omega(T2) # both procs must accept the same type
                  # and it must be a numeric sequence

As seen in the previous examples, you can refer to generic concepts such as
`Enumerable[T]` just by their short name. Much like the regular generic types,
the concept will be automatically instantiated with the bind once auto type
in the place of each missing generic param.

Please note that generic concepts such as `Enumerable[T]` can be matched
against concrete types such as `string`. Nim doesn't require the concept
type to have the same number of parameters as the type being matched.
If you wish to express a requirement towards the generic parameters of
the matched type, you can use a type mapping operator such as `genericHead`
or `stripGenericParams` within the body of the concept to obtain the
uninstantiated version of the type, which you can then try to instantiate
in any required way. For example, here is how one might define the classic
`Functor` concept from Haskell and then demonstrate that Nim's `Option[T]`
type is an instance of it:

.. code-block:: nim
    :test: "nim c $1"

  import sugar, typetraits

  type
    Functor[A] = concept f
      type MatchedGenericType = genericHead(f.type)
        # `f` will be a value of a type such as `Option[T]`
        # `MatchedGenericType` will become the `Option` type

      f.val is A
        # The Functor should provide a way to obtain
        # a value stored inside it

      type T = auto
      map(f, A -> T) is MatchedGenericType[T]
        # And it should provide a way to map one instance of
        # the Functor to a instance of a different type, given
        # a suitable `map` operation for the enclosed values

  import options
  echo Option[int] is Functor # prints true


Concept derived values
----------------------

All top level constants or types appearing within the concept body are
accessible through the dot operator in procs where the concept was successfully
matched to a concrete type:

.. code-block:: nim
  type
    DateTime = concept t1, t2, type T
      const Min = T.MinDate
      T.Now is T

      t1 < t2 is bool

      type TimeSpan = type(t1 - t2)
      TimeSpan * int is TimeSpan
      TimeSpan + TimeSpan is TimeSpan

      t1 + TimeSpan is T

  proc eventsJitter(events: Enumerable[DateTime]): float =
    var
      # this variable will have the inferred TimeSpan type for
      # the concrete Date-like value the proc was called with:
      averageInterval: DateTime.TimeSpan

      deviation: float
    ...


Concept refinement
------------------

When the matched type within a concept is directly tested against a different
concept, we say that the outer concept is a refinement of the inner concept and
thus it is more-specific. When both concepts are matched in a call during
overload resolution, Nim will assign a higher precedence to the most specific
one. As an alternative way of defining concept refinements, you can use the
object inheritance syntax involving the ``of`` keyword:

.. code-block:: nim
  type
    Graph = concept g, type G of EqualyComparable, Copyable
      type
        VertexType = G.VertexType
        EdgeType = G.EdgeType

      VertexType is Copyable
      EdgeType is Copyable

      var
        v: VertexType
        e: EdgeType

    IncidendeGraph = concept of Graph
      # symbols such as variables and types from the refined
      # concept are automatically in scope:

      g.source(e) is VertexType
      g.target(e) is VertexType

      g.outgoingEdges(v) is Enumerable[EdgeType]

    BidirectionalGraph = concept g, type G
      # The following will also turn the concept into a refinement when it
      # comes to overload resolution, but it doesn't provide the convenient
      # symbol inheritance
      g is IncidendeGraph

      g.incomingEdges(G.VertexType) is Enumerable[G.EdgeType]

  proc f(g: IncidendeGraph)
  proc f(g: BidirectionalGraph) # this one will be preferred if we pass a type
                                # matching the BidirectionalGraph concept

..
  Converter type classes
  ----------------------

  Concepts can also be used to convert a whole range of types to a single type or
  a small set of simpler types. This is achieved with a `return` statement within
  the concept body:

  .. code-block:: nim
    type
      Stringable = concept x
        $x is string
        return $x

      StringRefValue[CharType] = object
        base: ptr CharType
        len: int

      StringRef = concept x
        # the following would be an overloaded proc for cstring, string, seq and
        # other user-defined types, returning either a StringRefValue[char] or
        # StringRefValue[wchar]
        return makeStringRefValue(x)

    # the varargs param will here be converted to an array of StringRefValues
    # the proc will have only two instantiations for the two character types
    proc log(format: static string, varargs[StringRef])

    # this proc will allow char and wchar values to be mixed in
    # the same call at the cost of additional instantiations
    # the varargs param will be converted to a tuple
    proc log(format: static string, varargs[distinct StringRef])


..
  VTable types
  ------------

  Concepts allow Nim to define a great number of algorithms, using only
  static polymorphism and without erasing any type information or sacrificing
  any execution speed. But when polymorphic collections of objects are required,
  the user must use one of the provided type erasure techniques - either common
  base types or VTable types.

  VTable types are represented as "fat pointers" storing a reference to an
  object together with a reference to a table of procs implementing a set of
  required operations (the so called vtable).

  In contrast to other programming languages, the vtable in Nim is stored
  externally to the object, allowing you to create multiple different vtable
  views for the same object. Thus, the polymorphism in Nim is unbounded -
  any type can implement an unlimited number of protocols or interfaces not
  originally envisioned by the type's author.

  Any concept type can be turned into a VTable type by using the ``vtref``
  or the ``vtptr`` compiler magics. Under the hood, these magics generate
  a converter type class, which converts the regular instances of the matching
  types to the corresponding VTable type.

  .. code-block:: nim
    type
      IntEnumerable = vtref Enumerable[int]

      MyObject = object
        enumerables: seq[IntEnumerable]
        streams: seq[OutputStream.vtref]

    proc addEnumerable(o: var MyObject, e: IntEnumerable) =
      o.enumerables.add e

    proc addStream(o: var MyObject, e: OutputStream.vtref) =
      o.streams.add e

  The procs that will be included in the vtable are derived from the concept
  body and include all proc calls for which all param types were specified as
  concrete types. All such calls should include exactly one param of the type
  matched against the concept (not necessarily in the first position), which
  will be considered the value bound to the vtable.

  Overloads will be created for all captured procs, accepting the vtable type
  in the position of the captured underlying object.

  Under these rules, it's possible to obtain a vtable type for a concept with
  unbound type parameters or one instantiated with metatypes (type classes),
  but it will include a smaller number of captured procs. A completely empty
  vtable will be reported as an error.

  The ``vtref`` magic produces types which can be bound to ``ref`` types and
  the ``vtptr`` magic produced types bound to ``ptr`` types.


Type bound operations
=====================

There are 3 operations that are bound to a type:

1. Assignment
2. Destruction
3. Deep copying for communication between threads

These operations can be *overridden* instead of *overloaded*. This means the
implementation is automatically lifted to structured types. For instance if type
``T`` has an overridden assignment operator ``=`` this operator is also used
for assignments of the type ``seq[T]``. Since these operations are bound to a
type they have to be bound to a nominal type for reasons of simplicity of
implementation: This means an overridden ``deepCopy`` for ``ref T`` is really
bound to ``T`` and not to ``ref T``. This also means that one cannot override
``deepCopy`` for both ``ptr T`` and ``ref T`` at the same time; instead a
helper distinct or object type has to be used for one pointer type.


operator `=`
------------

This operator is the assignment operator. Note that in the contexts
``result = expr``, ``parameter = defaultValue`` or for
parameter passing no assignment is performed. For a type ``T`` that has an
overloaded assignment operator ``var v = T()`` is rewritten
to ``var v: T; v = T()``; in other words ``var`` and ``let`` contexts do count
as assignments.

The assignment operator needs to be attached to an object or distinct
type ``T``. Its signature has to be ``(var T, T)``. Example:

.. code-block:: nim
  type
    Concrete = object
      a, b: string

  proc `=`(d: var Concrete; src: Concrete) =
    shallowCopy(d.a, src.a)
    shallowCopy(d.b, src.b)
    echo "Concrete '=' called"

  var x, y: array[0..2, Concrete]
  var cA, cB: Concrete

  var cATup, cBTup: tuple[x: int, ha: Concrete]

  x = y
  cA = cB
  cATup = cBTup



destructors
-----------

A destructor must have a single parameter with a concrete type (the name of a
generic type is allowed too). The name of the destructor has to be ``=destroy``.

``=destroy(v)`` will be automatically invoked for every local stack
variable ``v`` that goes out of scope.

If a structured type features a field with destructable type and
the user has not provided an explicit implementation, a destructor for the
structured type will be automatically generated. Calls to any base class
destructors in both user-defined and generated destructors will be inserted.

A destructor is attached to the type it destructs.

.. code-block:: nim
  type
    MyObj = object
      x, y: int
      p: pointer

  proc `=destroy`(o: var MyObj) =
    if o.p != nil: dealloc o.p

  proc open: MyObj =
    result = MyObj(x: 1, y: 2, p: alloc(3))

  proc work(o: MyObj) =
    echo o.x
    # No destructor invoked here for 'o' as 'o' is a parameter.

  proc main() =
    # destructor automatically invoked at the end of the scope:
    var x = open()
    # valid: pass 'x' to some other proc:
    work(x)


deepCopy
--------

``=deepCopy`` is a builtin that is invoked whenever data is passed to
a ``spawn``'ed proc to ensure memory safety. The programmer can override its
behaviour for a specific ``ref`` or ``ptr`` type ``T``. (Later versions of the
language may weaken this restriction.)

The signature has to be:

.. code-block:: nim
  proc `=deepCopy`(x: T): T

This mechanism will be used by most data structures that support shared memory
like channels to implement thread safe automatic memory management.

The builtin ``deepCopy`` can even clone closures and their environments. See
the documentation of `spawn`_ for details.


Term rewriting macros
=====================

Term rewriting macros are macros or templates that have not only
a *name* but also a *pattern* that is searched for after the semantic checking
phase of the compiler: This means they provide an easy way to enhance the
compilation pipeline with user defined optimizations:

.. code-block:: nim
  template optMul{`*`(a, 2)}(a: int): int = a+a

  let x = 3
  echo x * 2

The compiler now rewrites ``x * 2`` as ``x + x``. The code inside the
curlies is the pattern to match against. The operators ``*``,  ``**``,
``|``, ``~`` have a special meaning in patterns if they are written in infix
notation, so to match verbatim against ``*`` the ordinary function call syntax
needs to be used.

Term rewriting macro are applied recursively, up to a limit. This means that
if the result of a term rewriting macro is eligible for another rewriting,
the compiler will try to perform it, and so on, until no more optimizations
are applicable. To avoid putting the compiler into an infinite loop, there is
a hard limit on how many times a single term rewriting macro can be applied.
Once this limit has been passed, the term rewriting macro will be ignored.

Unfortunately optimizations are hard to get right and even the tiny example
is **wrong**:

.. code-block:: nim
  template optMul{`*`(a, 2)}(a: int): int = a+a

  proc f(): int =
    echo "side effect!"
    result = 55

  echo f() * 2

We cannot duplicate 'a' if it denotes an expression that has a side effect!
Fortunately Nim supports side effect analysis:

.. code-block:: nim
  template optMul{`*`(a, 2)}(a: int{noSideEffect}): int = a+a

  proc f(): int =
    echo "side effect!"
    result = 55

  echo f() * 2 # not optimized ;-)

You can make one overload matching with a constraint and one without, and the
one with a constraint will have precedence, and so you can handle both cases
differently.

So what about ``2 * a``? We should tell the compiler ``*`` is commutative. We
cannot really do that however as the following code only swaps arguments
blindly:

.. code-block:: nim
  template mulIsCommutative{`*`(a, b)}(a, b: int): int = b*a

What optimizers really need to do is a *canonicalization*:

.. code-block:: nim
  template canonMul{`*`(a, b)}(a: int{lit}, b: int): int = b*a

The ``int{lit}`` parameter pattern matches against an expression of
type ``int``, but only if it's a literal.



Parameter constraints
---------------------

The `parameter constraint`:idx: expression can use the operators ``|`` (or),
``&`` (and) and ``~`` (not) and the following predicates:

===================      =====================================================
Predicate                Meaning
===================      =====================================================
``atom``                 The matching node has no children.
``lit``                  The matching node is a literal like "abc", 12.
``sym``                  The matching node must be a symbol (a bound
                         identifier).
``ident``                The matching node must be an identifier (an unbound
                         identifier).
``call``                 The matching AST must be a call/apply expression.
``lvalue``               The matching AST must be an lvalue.
``sideeffect``           The matching AST must have a side effect.
``nosideeffect``         The matching AST must have no side effect.
``param``                A symbol which is a parameter.
``genericparam``         A symbol which is a generic parameter.
``module``               A symbol which is a module.
``type``                 A symbol which is a type.
``var``                  A symbol which is a variable.
``let``                  A symbol which is a ``let`` variable.
``const``                A symbol which is a constant.
``result``               The special ``result`` variable.
``proc``                 A symbol which is a proc.
``method``               A symbol which is a method.
``iterator``             A symbol which is an iterator.
``converter``            A symbol which is a converter.
``macro``                A symbol which is a macro.
``template``             A symbol which is a template.
``field``                A symbol which is a field in a tuple or an object.
``enumfield``            A symbol which is a field in an enumeration.
``forvar``               A for loop variable.
``label``                A label (used in ``block`` statements).
``nk*``                  The matching AST must have the specified kind.
                         (Example: ``nkIfStmt`` denotes an ``if`` statement.)
``alias``                States that the marked parameter needs to alias
                         with *some* other parameter.
``noalias``              States that *every* other parameter must not alias
                         with the marked parameter.
===================      =====================================================

Predicates that share their name with a keyword have to be escaped with
backticks.
The ``alias`` and ``noalias`` predicates refer not only to the matching AST,
but also to every other bound parameter; syntactically they need to occur after
the ordinary AST predicates:

.. code-block:: nim
  template ex{a = b + c}(a: int{noalias}, b, c: int) =
    # this transformation is only valid if 'b' and 'c' do not alias 'a':
    a = b
    inc a, c


Pattern operators
-----------------

The operators ``*``,  ``**``, ``|``, ``~`` have a special meaning in patterns
if they are written in infix notation.


The ``|`` operator
~~~~~~~~~~~~~~~~~~

The ``|`` operator if used as infix operator creates an ordered choice:

.. code-block:: nim
  template t{0|1}(): untyped = 3
  let a = 1
  # outputs 3:
  echo a

The matching is performed after the compiler performed some optimizations like
constant folding, so the following does not work:

.. code-block:: nim
  template t{0|1}(): untyped = 3
  # outputs 1:
  echo 1

The reason is that the compiler already transformed the 1 into "1" for
the ``echo`` statement. However, a term rewriting macro should not change the
semantics anyway. In fact they can be deactivated with the ``--patterns:off``
command line option or temporarily with the ``patterns`` pragma.


The ``{}`` operator
~~~~~~~~~~~~~~~~~~~

A pattern expression can be bound to a pattern parameter via the ``expr{param}``
notation:

.. code-block:: nim
  template t{(0|1|2){x}}(x: untyped): untyped = x+1
  let a = 1
  # outputs 2:
  echo a


The ``~`` operator
~~~~~~~~~~~~~~~~~~

The ``~`` operator is the **not** operator in patterns:

.. code-block:: nim
  template t{x = (~x){y} and (~x){z}}(x, y, z: bool) =
    x = y
    if x: x = z

  var
    a = false
    b = true
    c = false
  a = b and c
  echo a


The ``*`` operator
~~~~~~~~~~~~~~~~~~

The ``*`` operator can *flatten* a nested binary expression like ``a & b & c``
to ``&(a, b, c)``:

.. code-block:: nim
  var
    calls = 0

  proc `&&`(s: varargs[string]): string =
    result = s[0]
    for i in 1..len(s)-1: result.add s[i]
    inc calls

  template optConc{ `&&` * a }(a: string): untyped = &&a

  let space = " "
  echo "my" && (space & "awe" && "some " ) && "concat"

  # check that it's been optimized properly:
  doAssert calls == 1


The second operator of `*` must be a parameter; it is used to gather all the
arguments. The expression ``"my" && (space & "awe" && "some " ) && "concat"``
is passed to ``optConc`` in ``a`` as a special list (of kind ``nkArgList``)
which is flattened into a call expression; thus the invocation of ``optConc``
produces:

.. code-block:: nim
   `&&`("my", space & "awe", "some ", "concat")


The ``**`` operator
~~~~~~~~~~~~~~~~~~~

The ``**`` is much like the ``*`` operator, except that it gathers not only
all the arguments, but also the matched operators in reverse polish notation:

.. code-block:: nim
  import macros

  type
    Matrix = object
      dummy: int

  proc `*`(a, b: Matrix): Matrix = discard
  proc `+`(a, b: Matrix): Matrix = discard
  proc `-`(a, b: Matrix): Matrix = discard
  proc `$`(a: Matrix): string = result = $a.dummy
  proc mat21(): Matrix =
    result.dummy = 21

  macro optM{ (`+`|`-`|`*`) ** a }(a: Matrix): untyped =
    echo treeRepr(a)
    result = newCall(bindSym"mat21")

  var x, y, z: Matrix

  echo x + y * z - x

This passes the expression ``x + y * z - x`` to the ``optM`` macro as
an ``nnkArgList`` node containing::

  Arglist
    Sym "x"
    Sym "y"
    Sym "z"
    Sym "*"
    Sym "+"
    Sym "x"
    Sym "-"

(Which is the reverse polish notation of ``x + y * z - x``.)


Parameters
----------

Parameters in a pattern are type checked in the matching process. If a
parameter is of the type ``varargs`` it is treated specially and it can match
0 or more arguments in the AST to be matched against:

.. code-block:: nim
  template optWrite{
    write(f, x)
    ((write|writeLine){w})(f, y)
  }(x, y: varargs[untyped], f: File, w: untyped) =
    w(f, x, y)



Example: Partial evaluation
---------------------------

The following example shows how some simple partial evaluation can be
implemented with term rewriting:

.. code-block:: nim
  proc p(x, y: int; cond: bool): int =
    result = if cond: x + y else: x - y

  template optP1{p(x, y, true)}(x, y: untyped): untyped = x + y
  template optP2{p(x, y, false)}(x, y: untyped): untyped = x - y


Example: Hoisting
-----------------

The following example shows how some form of hoisting can be implemented:

.. code-block:: nim
  import pegs

  template optPeg{peg(pattern)}(pattern: string{lit}): Peg =
    var gl {.global, gensym.} = peg(pattern)
    gl

  for i in 0 .. 3:
    echo match("(a b c)", peg"'(' @ ')'")
    echo match("W_HI_Le", peg"\y 'while'")

The ``optPeg`` template optimizes the case of a peg constructor with a string
literal, so that the pattern will only be parsed once at program startup and
stored in a global ``gl`` which is then re-used. This optimization is called
hoisting because it is comparable to classical loop hoisting.


AST based overloading
=====================

Parameter constraints can also be used for ordinary routine parameters; these
constraints affect ordinary overloading resolution then:

.. code-block:: nim
  proc optLit(a: string{lit|`const`}) =
    echo "string literal"
  proc optLit(a: string) =
    echo "no string literal"

  const
    constant = "abc"

  var
    variable = "xyz"

  optLit("literal")
  optLit(constant)
  optLit(variable)

However, the constraints ``alias`` and ``noalias`` are not available in
ordinary routines.


Parallel & Spawn
================

Nim has two flavors of parallelism:
1) `Structured`:idx: parallelism via the ``parallel`` statement.
2) `Unstructured`:idx: parallelism via the standalone ``spawn`` statement.

Nim has a builtin thread pool that can be used for CPU intensive tasks. For
IO intensive tasks the ``async`` and ``await`` features should be
used instead. Both parallel and spawn need the `threadpool <threadpool.html>`_
module to work.

Somewhat confusingly, ``spawn`` is also used in the ``parallel`` statement
with slightly different semantics. ``spawn`` always takes a call expression of
the form ``f(a, ...)``. Let ``T`` be ``f``'s return type. If ``T`` is ``void``
then ``spawn``'s return type is also ``void`` otherwise it is ``FlowVar[T]``.

Within a ``parallel`` section sometimes the ``FlowVar[T]`` is eliminated
to ``T``. This happens when ``T`` does not contain any GC'ed memory.
The compiler can ensure the location in ``location = spawn f(...)`` is not
read prematurely within a ``parallel`` section and so there is no need for
the overhead of an indirection via ``FlowVar[T]`` to ensure correctness.

**Note**: Currently exceptions are not propagated between ``spawn``'ed tasks!


Spawn statement
---------------

`spawn`:idx: can be used to pass a task to the thread pool:

.. code-block:: nim
  import threadpool

  proc processLine(line: string) =
    discard "do some heavy lifting here"

  for x in lines("myinput.txt"):
    spawn processLine(x)
  sync()

For reasons of type safety and implementation simplicity the expression
that ``spawn`` takes is restricted:

* It must be a call expression ``f(a, ...)``.
* ``f`` must be ``gcsafe``.
* ``f`` must not have the calling convention ``closure``.
* ``f``'s parameters may not be of type ``var``.
  This means one has to use raw ``ptr``'s for data passing reminding the
  programmer to be careful.
* ``ref`` parameters are deeply copied which is a subtle semantic change and
  can cause performance problems but ensures memory safety. This deep copy
  is performed via ``system.deepCopy`` and so can be overridden.
* For *safe* data exchange between ``f`` and the caller a global ``TChannel``
  needs to be used. However, since spawn can return a result, often no further
  communication is required.


``spawn`` executes the passed expression on the thread pool and returns
a `data flow variable`:idx: ``FlowVar[T]`` that can be read from. The reading
with the ``^`` operator is **blocking**. However, one can use ``blockUntilAny`` to
wait on multiple flow variables at the same time:

.. code-block:: nim
  import threadpool, ...

  # wait until 2 out of 3 servers received the update:
  proc main =
    var responses = newSeq[FlowVarBase](3)
    for i in 0..2:
      responses[i] = spawn tellServer(Update, "key", "value")
    var index = blockUntilAny(responses)
    assert index >= 0
    responses.del(index)
    discard blockUntilAny(responses)

Data flow variables ensure that no data races
are possible. Due to technical limitations not every type ``T`` is possible in
a data flow variable: ``T`` has to be of the type ``ref``, ``string``, ``seq``
or of a type that doesn't contain a type that is garbage collected. This
restriction is not hard to work-around in practice.



Parallel statement
------------------

Example:

.. code-block:: nim
    :test: "nim c --threads:on $1"

  # Compute PI in an inefficient way
  import strutils, math, threadpool
  {.experimental: "parallel".}

  proc term(k: float): float = 4 * math.pow(-1, k) / (2*k + 1)

  proc pi(n: int): float =
    var ch = newSeq[float](n+1)
    parallel:
      for k in 0..ch.high:
        ch[k] = spawn term(float(k))
    for k in 0..ch.high:
      result += ch[k]

  echo formatFloat(pi(5000))


The parallel statement is the preferred mechanism to introduce parallelism in a
Nim program. A subset of the Nim language is valid within a ``parallel``
section. This subset is checked during semantic analysis to be free of data
races. A sophisticated `disjoint checker`:idx: ensures that no data races are
possible even though shared memory is extensively supported!

The subset is in fact the full language with the following
restrictions / changes:

* ``spawn`` within a ``parallel`` section has special semantics.
* Every location of the form ``a[i]`` and ``a[i..j]`` and ``dest`` where
  ``dest`` is part of the pattern ``dest = spawn f(...)`` has to be
  provably disjoint. This is called the *disjoint check*.
* Every other complex location ``loc`` that is used in a spawned
  proc (``spawn f(loc)``) has to be immutable for the duration of
  the ``parallel`` section. This is called the *immutability check*. Currently
  it is not specified what exactly "complex location" means. We need to make
  this an optimization!
* Every array access has to be provably within bounds. This is called
  the *bounds check*.
* Slices are optimized so that no copy is performed. This optimization is not
  yet performed for ordinary slices outside of a ``parallel`` section.


Guards and locks
================

Apart from ``spawn`` and ``parallel`` Nim also provides all the common low level
concurrency mechanisms like locks, atomic intrinsics or condition variables.

Nim significantly improves on the safety of these features via additional
pragmas:

1) A `guard`:idx: annotation is introduced to prevent data races.
2) Every access of a guarded memory location needs to happen in an
   appropriate `locks`:idx: statement.
3) Locks and routines can be annotated with `lock levels`:idx: to allow
   potential deadlocks to be detected during semantic analysis.


Guards and the locks section
----------------------------

Protecting global variables
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Object fields and global variables can be annotated via a ``guard`` pragma:

.. code-block:: nim
  var glock: TLock
  var gdata {.guard: glock.}: int

The compiler then ensures that every access of ``gdata`` is within a ``locks``
section:

.. code-block:: nim
  proc invalid =
    # invalid: unguarded access:
    echo gdata

  proc valid =
    # valid access:
    {.locks: [glock].}:
      echo gdata

Top level accesses to ``gdata`` are always allowed so that it can be initialized
conveniently. It is *assumed* (but not enforced) that every top level statement
is executed before any concurrent action happens.

The ``locks`` section deliberately looks ugly because it has no runtime
semantics and should not be used directly! It should only be used in templates
that also implement some form of locking at runtime:

.. code-block:: nim
  template lock(a: TLock; body: untyped) =
    pthread_mutex_lock(a)
    {.locks: [a].}:
      try:
        body
      finally:
        pthread_mutex_unlock(a)


The guard does not need to be of any particular type. It is flexible enough to
model low level lockfree mechanisms:

.. code-block:: nim
  var dummyLock {.compileTime.}: int
  var atomicCounter {.guard: dummyLock.}: int

  template atomicRead(x): untyped =
    {.locks: [dummyLock].}:
      memoryReadBarrier()
      x

  echo atomicRead(atomicCounter)


The ``locks`` pragma takes a list of lock expressions ``locks: [a, b, ...]``
in order to support *multi lock* statements. Why these are essential is
explained in the `lock levels <#guards-and-locks-lock-levels>`_ section.


Protecting general locations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``guard`` annotation can also be used to protect fields within an object.
The guard then needs to be another field within the same object or a
global variable.

Since objects can reside on the heap or on the stack this greatly enhances the
expressivity of the language:

.. code-block:: nim
  type
    ProtectedCounter = object
      v {.guard: L.}: int
      L: TLock

  proc incCounters(counters: var openArray[ProtectedCounter]) =
    for i in 0..counters.high:
      lock counters[i].L:
        inc counters[i].v

The access to field ``x.v`` is allowed since its guard ``x.L``  is active.
After template expansion, this amounts to:

.. code-block:: nim
  proc incCounters(counters: var openArray[ProtectedCounter]) =
    for i in 0..counters.high:
      pthread_mutex_lock(counters[i].L)
      {.locks: [counters[i].L].}:
        try:
          inc counters[i].v
        finally:
          pthread_mutex_unlock(counters[i].L)

There is an analysis that checks that ``counters[i].L`` is the lock that
corresponds to the protected location ``counters[i].v``. This analysis is called
`path analysis`:idx: because it deals with paths to locations
like ``obj.field[i].fieldB[j]``.

The path analysis is **currently unsound**, but that doesn't make it useless.
Two paths are considered equivalent if they are syntactically the same.

This means the following compiles (for now) even though it really should not:

.. code-block:: nim
  {.locks: [a[i].L].}:
    inc i
    access a[i].v



Lock levels
-----------

Lock levels are used to enforce a global locking order in order to detect
potential deadlocks during semantic analysis. A lock level is an constant
integer in the range 0..1_000. Lock level 0 means that no lock is acquired at
all.

If a section of code holds a lock of level ``M`` than it can also acquire any
lock of level ``N < M``. Another lock of level ``M`` cannot be acquired. Locks
of the same level can only be acquired *at the same time* within a
single ``locks`` section:

.. code-block:: nim
  var a, b: TLock[2]
  var x: TLock[1]
  # invalid locking order: TLock[1] cannot be acquired before TLock[2]:
  {.locks: [x].}:
    {.locks: [a].}:
      ...
  # valid locking order: TLock[2] acquired before TLock[1]:
  {.locks: [a].}:
    {.locks: [x].}:
      ...

  # invalid locking order: TLock[2] acquired before TLock[2]:
  {.locks: [a].}:
    {.locks: [b].}:
      ...

  # valid locking order, locks of the same level acquired at the same time:
  {.locks: [a, b].}:
    ...


Here is how a typical multilock statement can be implemented in Nim. Note how
the runtime check is required to ensure a global ordering for two locks ``a``
and ``b`` of the same lock level:

.. code-block:: nim
  template multilock(a, b: ptr TLock; body: untyped) =
    if cast[ByteAddress](a) < cast[ByteAddress](b):
      pthread_mutex_lock(a)
      pthread_mutex_lock(b)
    else:
      pthread_mutex_lock(b)
      pthread_mutex_lock(a)
    {.locks: [a, b].}:
      try:
        body
      finally:
        pthread_mutex_unlock(a)
        pthread_mutex_unlock(b)


Whole routines can also be annotated with a ``locks`` pragma that takes a lock
level. This then means that the routine may acquire locks of up to this level.
This is essential so that procs can be called within a ``locks`` section:

.. code-block:: nim
  proc p() {.locks: 3.} = discard

  var a: TLock[4]
  {.locks: [a].}:
    # p's locklevel (3) is strictly less than a's (4) so the call is allowed:
    p()


As usual ``locks`` is an inferred effect and there is a subtype
relation: ``proc () {.locks: N.}`` is a subtype of ``proc () {.locks: M.}``
iff (M <= N).

The ``locks`` pragma can also take the special value ``"unknown"``. This
is useful in the context of dynamic method dispatching. In the following
example, the compiler can infer a lock level of 0 for the ``base`` case.
However, one of the overloaded methods calls a procvar which is
potentially locking. Thus, the lock level of calling ``g.testMethod``
cannot be inferred statically, leading to compiler warnings. By using
``{.locks: "unknown".}``, the base method can be marked explicitly as
having unknown lock level as well:

.. code-block:: nim
  type SomeBase* = ref object of RootObj
  type SomeDerived* = ref object of SomeBase
    memberProc*: proc ()

  method testMethod(g: SomeBase) {.base, locks: "unknown".} = discard
  method testMethod(g: SomeDerived) =
    if g.memberProc != nil:
      g.memberProc()


Taint mode
==========

The Nim compiler and most parts of the standard library support
a taint mode. Input strings are declared with the `TaintedString`:idx:
string type declared in the ``system`` module.

If the taint mode is turned on (via the ``--taintMode:on`` command line
option) it is a distinct string type which helps to detect input
validation errors:

.. code-block:: nim
  echo "your name: "
  var name: TaintedString = stdin.readline
  # it is safe here to output the name without any input validation, so
  # we simply convert `name` to string to make the compiler happy:
  echo "hi, ", name.string

If the taint mode is turned off, ``TaintedString`` is simply an alias for
``string``.


Aliasing restrictions in parameter passing
==========================================

**Note**: The aliasing restrictions are currently not enforced by the
implementation and need to be fleshed out futher.

"Aliasing" here means that the underlying storage locations overlap in memory
at runtime. An "output parameter" is a parameter of type ``var T``, an input
parameter is any parameter that is not of type ``var``.

1. Two output parameters should never be aliased.
2. An input and an output parameter should not be aliased.
3. An output parameter should never be aliased with a global or thread local
   variable referenced by the called proc.
4. An input parameter should not be aliased with a global or thread local
   variable updated by the called proc.

One problem with rules 3 and 4 is that they affect specific global or thread
local variables, but Nim's effect tracking only tracks "uses no global variable"
via ``.noSideEffect``. The rules 3 and 4 can also be approximated by a different rule:

5. A global or thread local variable (or a location derived from such a location)
   can only passed to a parameter of a ``.noSideEffect`` proc.
