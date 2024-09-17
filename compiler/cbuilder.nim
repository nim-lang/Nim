type
  Snippet = string
  Builder = string

template newBuilder(s: string): Builder =
  s

proc addField(obj: var Builder; field: Snippet;) =
  obj.add field
  obj.add ";\n"


template withStruct(obj: var Builder; structOrUnion: string; name: string; inheritance: string; body: typed) =
  if inheritance.len > 0:
    obj.add "$1 $2 : public $1 {$n" % [structOrUnion, name, inheritance]
  else:
    obj.add "$1 $2 {$n" % [structOrUnion, name]
  body
  obj.add("};\n")
