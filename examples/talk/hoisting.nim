type
  Regex = distinct string

const maxSubpatterns = 10

proc re(x: string): Regex =
  result = Regex(x)

proc match(s: string, pattern: Regex, captures: var openArray[string]): bool =
  true

template optRe{re(x)}(x: string{lit}): Regex =
  var g {.global.} = re(x)
  g

template `=~`(s: string, pattern: Regex): bool =
  when not declaredInScope(matches):
    var matches {.inject.}: array[maxSubPatterns, string]
  match(s, pattern, matches)

for line in lines("input.txt"):
  if line =~ re"(\w+)=(\w+)":
    echo "key-value pair; key: ", matches[0], " value: ", matches[1]
