discard """
  output: '''id 4'''
"""

import mcompiletime_counter

const intId = getUniqueId()

echo "id ", intId

#!EDIT!#

discard """
  output: '''id 4 5'''
"""

import mcompiletime_counter

const
  intId = getUniqueId()
  floatId = getUniqueId()

echo "id ", intId, " ", floatId

