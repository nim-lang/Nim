discard """
  output: '''true'''
"""

# Just check that we can parse 'somesql' and render it without crashes.

import parsesql, streams, os

var tree = parseSql(newFileStream(parentDir(currentSourcePath) / "somesql.sql"), "somesql")
discard renderSql(tree)

echo "true"
