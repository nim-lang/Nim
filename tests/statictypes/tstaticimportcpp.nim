discard """
targets: "cpp"
"""

{.emit:[ """

template <int N>
struct CppType {
  int data[N];
};


"""].}

type
  CppType {.importcpp: "CppType<'0>".} [N: static[int]] = object
  
  CppType4 = CppType[4]

let c = CppType4()

