proc foo[T: proc](x: T) =
  # old error here:
  let y = x
  # invalid type: 'typeof(nil)' for let

foo(nil) #[tt.Error
   ^ type mismatch: got <typeof(nil)>]#
