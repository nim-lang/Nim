This directory contains the nim backend code for the todo cross platform
example.

Unlike the cross platform calculator example, this backend features more code,
using an sqlite database for storage. Also a basic test module is provided, not
to be included with the final program but to test the exported functionality.
The test is not embedded directly in the backend.nim file to avoid being able
to access internal data types and procs not exported and replicate the
environment of client code.

In a bigger project with several people you could run `nim doc backend.nim`
(or use the doc2 command for a whole project) and provide the generated html
documentation to another programer for her to implement an interface without
having to look at the source code.
