discard """
# Since the tests for nre are all bundled together we treat failure in one test as an nre failure
# When running 'testament/tester' a failed check() in the test suite will cause the exit
# codes to differ and be reported as a failure
"""

import nre
import nre/init
import nre/captures
import nre/find
import nre/split
import nre/match
import nre/replace
import nre/escape
import nre/misc
