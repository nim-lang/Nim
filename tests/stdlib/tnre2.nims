# std/nre2 requires nim-regex and it requires nim-unicodedb
exec("nimble install unicodedb@#head")
exec("nimble install regex@#head")
