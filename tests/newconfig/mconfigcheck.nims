mode = ScriptMode.Verbose
proc build() =
  echo "building nim... "
  exec "sleep 10"
  exec "nonexistant command"
  echo getCurrentDir()

echo "hello"
build()
