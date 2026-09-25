discard """
  description: '''IC preserves module-level localPassC options'''
"""

import mlocalpassc

doAssert localPassCAnswer() == 42
