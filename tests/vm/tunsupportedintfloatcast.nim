static:
  echo cast[int32](12.0) #[tt.Error
       ^ VM does not support 'cast' from tyFloat with size 8 to tyInt32 with size 4 due to different sizes]#
