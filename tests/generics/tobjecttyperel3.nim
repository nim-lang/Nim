discard """
  output: '''OK'''
"""
#bug #5632
type
  Option*[T] = object
  
proc point*[A](v: A, t: typedesc[Option[A]]): Option[A] =
  discard
  
discard point(1, Option)
echo "OK"