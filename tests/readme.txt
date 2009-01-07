This directory contains the test cases.
Each test must have a filename of the form: ``t*.nim``

The testcases may contain the directives ``#ERROR``, ``#ERROR_IN``, 
``#ERROR_MSG`` or ``#OUT``.
``#ERROR`` is used to indicate that the compiler should report
an error in the marked line (the line that contains the ``#ERROR``
directive.)
The format for ``#ERROR_IN`` is::

     #ERROR_IN filename linenumber

You can omit the extension of the filename (``.nim`` is then assumed).
The format for ``#ERROR_MSG`` is::

     #ERROR_MSG message

This directive specifies the error message Nimrod shall produce.

Tests which contain none of the ``#ERROR*`` directives should compile. 
Thus they are executed after successful compilation and their output 
is compared to the expected results (specified with the ``#OUT`` 
directive). Tests which require user interaction are currently not 
possible.
