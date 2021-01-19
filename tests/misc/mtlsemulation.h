#include <stdio.h>

struct Foo1 {
  /*
  uncommenting would give:
  error: initializer for thread-local variable must be a constant expression
  N_LIB_PRIVATE NIM_THREADVAR Foo1 g1__9brEZhPEldbVrNpdRGmWESA;
  */
  // Foo1() noexcept { }

  /*
  uncommenting would give:
  error: type of thread-local variable has non-trivial destruction
  */
  // ~Foo1() { }
  int x;
};

struct Foo2 {
  Foo2() noexcept { }
  ~Foo2() { }
  int x;
};
