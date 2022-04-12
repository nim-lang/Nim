discard """
  output: '''true'''
"""

# Just check that we can parse 'somesql' and render it without crashes.

import parsesql, streams, os

var tree = parseSQL(newFileStream(parentDir(currentSourcePath) / "somesql.sql"), "somesql")
discard renderSQL(tree)

echo "true"
