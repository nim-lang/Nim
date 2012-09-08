The cross platform calculator illustrates how to use Nimrod to create a backend
called by different native user interfaces.

Since the purpose of the example is to show how the cross platform code
interacts with Nimrod the actual backend code is just a simple addition proc.
By keeping your program logic in Nimrod you can easily reuse it in different
platforms.

To avoid duplication of code, the backend code lies in a separate directory and
each platform compiles it with a different custom build process, usually
generating C code in a temporary build directory.
