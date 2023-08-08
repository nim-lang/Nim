discard """
  targets: "c cpp"
"""

import macros

macro make_test_type(idents: varargs[untyped]): untyped =
  result = nnkStmtList.newTree()

  var ident_defs: seq[NimNode] = @[]
  for i in idents:
    ident_defs.add newIdentDefs(i, ident("int"))

  result.add newTree(nnkTypeSection,
    newTree(nnkTypeDef,
      ident("TestType"),
      newEmptyNode(),
      newTree(nnkObjectTy,
        newEmptyNode(),
        newEmptyNode(),
        newTree(nnkRecList,
          ident_defs
        )
      )
    )
  )

make_test_type(
  auto, bool, catch, char, class, compl, const_cast, default, delete, double,
  dynamic_cast, explicit, extern, false, float, friend, goto, int, long,
  mutable, namespace, new, operator, private, protected, public, register,
  reinterpret_cast, restrict, short, signed, sizeof, static_cast, struct, switch,
  this, throw, true, typedef, typeid, typeof, typename, union, packed, unsigned,
  virtual, void, volatile, wchar_t, alignas, alignof, constexpr, decltype, nullptr,
  noexcept, thread_local, static_assert, char16_t, char32_t
)

# Make sure the type makes it to codegen.
var test_instance: TestType
