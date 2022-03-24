mode = ScriptMode.Verbose
proc build() =
  echo "building nim... "
  exec "sleep 10"
  echo getCurrentDir()

echo "hello"
build()
