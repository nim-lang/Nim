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

static int ctorCalls = 0;
static int dtorCalls = 0;

struct Foo3 {
  Foo3() noexcept {
    ctorCalls = ctorCalls + 1;
    x = 10;
  }
  ~Foo3() {
    dtorCalls = dtorCalls + 1;
  }
  int x;
};
