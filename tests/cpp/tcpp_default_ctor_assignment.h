#ifndef TCPP_DEFAULT_CTOR_ASSIGNMENT_H
#define TCPP_DEFAULT_CTOR_ASSIGNMENT_H

struct AmbiguousAssign {
  int x;
  const char* y;

  AmbiguousAssign(): x(0), y(nullptr) {}
  AmbiguousAssign(int x, const char* y): x(x), y(y) {}

  AmbiguousAssign& operator=(int v) {
    x = v;
    y = nullptr;
    return *this;
  }

  AmbiguousAssign& operator=(const char* s) {
    x = 0;
    y = s;
    return *this;
  }

  AmbiguousAssign& operator=(const AmbiguousAssign& other) {
    x = other.x;
    y = other.y;
    return *this;
  }
};

#endif