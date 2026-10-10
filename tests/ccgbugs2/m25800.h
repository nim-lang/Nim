/*TYPESECTION*/
struct CppRef {
  int* data;
  CppRef() : data(new int(42)) {}
  ~CppRef() { delete data; data = nullptr; }
  void reset() { delete data; data = nullptr; }
};