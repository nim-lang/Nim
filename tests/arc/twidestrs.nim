discard """
  cmd: '''nim c --gc:orc -d:release $file'''
  output: '''pipeName inside loop [\\.\pipe\LOCAL\chronos\0]
pipeName inside loop [\\.\pipe\LOCAL\chronos\1]
pipeName inside loop [\\.\pipe\LOCAL\chronos\2]
pipeName inside loop [\\.\pipe\LOCAL\chronos\3]
pipeName inside loop [\\.\pipe\LOCAL\chronos\4]
pipeName inside loop [\\.\pipe\LOCAL\chronos\5]
pipeName inside loop [\\.\pipe\LOCAL\chronos\6]
pipeName inside loop [\\.\pipe\LOCAL\chronos\7]
pipeName inside loop [\\.\pipe\LOCAL\chronos\8]
pipeName inside loop [\\.\pipe\LOCAL\chronos\9]
pipeName after loop [\\.\pipe\LOCAL\chronos\9]'''
"""

const pipeHeaderName = r"\\.\pipe\LOCAL\chronos\"

proc main =
  var pipeName: WideCString
  var uniq = 0
  while true:
    pipename = newWideCString(pipeHeaderName & $uniq)
    inc(uniq)
    echo "pipeName inside loop [", $pipename, "]"
    if uniq == 10:
      break
  echo "pipeName after loop [", pipeName, "]"

main()
