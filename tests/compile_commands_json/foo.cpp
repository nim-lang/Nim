#include <iostream>

#ifdef ENABLE_FOO
extern "C" void foo() {
    std::cout << "hello world\n";
}
#endif
