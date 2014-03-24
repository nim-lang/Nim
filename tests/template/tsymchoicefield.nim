type Foo = object
  len: int

var f = Foo(len: 40)

template getLen(f: Foo): expr = f.len

echo f.getLen
# This fails, because `len` gets the nkOpenSymChoice
# treatment inside the template early pass and then
# it can't be recognized as a field anymore

