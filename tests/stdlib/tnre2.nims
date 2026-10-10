# std/nre2 requires nim-regex and it requires nim-unicodedb
exec("nimble --nimbleDir:build/deps install unicodedb@#head")
exec("nimble --nimbleDir:build/deps install regex@#head")
