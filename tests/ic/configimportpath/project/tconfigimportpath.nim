discard """
  output: '''ok'''
"""

static: doAssert forcedConfigImportValue == 42
echo "ok"
