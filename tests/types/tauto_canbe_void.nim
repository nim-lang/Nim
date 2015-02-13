
import future

template tempo(s: expr) =
  s("arg")

tempo((s: string)->auto => echo(s))
tempo((s: string) => echo(s))

