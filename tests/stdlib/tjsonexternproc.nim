discard """
output: '''
{"data":[1]}
'''
"""

# Test case for https://github.com/nim-lang/Nim/issues/6385

import mjsonexternproc
# import json
foo(1)
