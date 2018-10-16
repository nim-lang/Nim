
import sugar

template tempo(s) =
  s("arg")

tempo((s: string)->auto => echo(s))
tempo((s: string) => echo(s))

