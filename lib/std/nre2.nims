if getCommand() == "doc":
  const NimbleDir = "build/deps"
  # std/nre2 requires nim-regex and it requires nim-unicodedb
  exec("nimble --nimbleDir:" & NimbleDir & " install unicodedb@#head")
  exec("nimble --nimbleDir:" & NimbleDir & " install regex@#head")

  switch("nimblePath", NimbleDir & "/pkgs2")
