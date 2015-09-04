The cross platform calculator illustrates how to use Nim to create a backend
called by different native user interfaces.

Since the purpose of the example is to show how the cross platform code
interacts with Nimrod the actual backend code is just a simple addition proc.
By keeping your program logic in Nim you can easily reuse it in different
platforms.

To avoid duplication of code, the backend code lies in a separate directory and
each platform compiles it with a different custom build process, usually
generating C code in a temporary build directory.

For a more elaborate and useful example see the cross_todo example.
