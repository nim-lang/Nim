import db_common


template dbFormatImpl*(formatstr: SqlQuery, dbQuote: proc (s: string): string, args: varargs[string]): string =
  var res = ""
  var a = 0
  for c in items(string(formatstr)):
    if c == '?':
      if a == args.len:
        dbError("""The number of "?" given exceeds the number of parameters present in the query.""")
      add(res, dbQuote(args[a]))
      inc(a)
    else:
      add(res, c)
  res
