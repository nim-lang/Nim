{.emit:"""
#include <stdbool.h>
void fun(bool a){}
""".}

proc fun(a: bool) {.importc.}
fun(true)
