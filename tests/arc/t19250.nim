type
  Bar[T] = object
    err: proc(): string

  Foo[T] = object
    run: proc(): Bar[T]

proc bar[T](err: proc(): string): Bar[T] =
  doAssert not err.isNil
  Bar[T](err: err)

proc foo*(): Foo[char] = 
  result.run = proc(): Bar[char] =
    
    # works
    # result = Bar[char](err: proc(): string = "x")
    
    # not work
    result = bar[char](proc(): string = "x")

proc bug*[T](fs: Foo[T]): Foo[T] =
  result.run = proc(): Bar[T] =
    let res = fs.run()
    
    # works
    # var errors = @[res.err] 
    
    # not work
    var errors: seq[proc(): string]
    errors.add res.err
    
    return bar[T] do () -> string:
      for err in errors:
        result.add res.err()

doAssert bug(foo()).run().err() == "x"
