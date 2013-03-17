# Example to embed Python into your application

import python

# IMPORTANT: Python on Windows does not like CR characters, so
# we use only \L here.

Py_Initialize()
discard PyRun_SimpleString("from time import time,ctime\L" &
                           "print 'Today is',ctime(time())\L")
Py_Finalize()
