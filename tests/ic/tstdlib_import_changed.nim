discard """
  output: '''yes'''
"""

echo "yes"

#!EDIT!#

discard """
  output: '''yes2'''
"""

import std / [monotimes]
#discard getMonoTime()
echo "yes2"
