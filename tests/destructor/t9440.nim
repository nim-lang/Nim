discard """
  matrix: "--gc:refc; --gc:orc; --gc:arc"
  output: '''
()
Destroyed
()
Destroyed
()
Destroyed
end
-------------------------
()
Destroyed
end
'''

"""

# bug #9440
block:
  type
    X = object

  proc `=destroy`(x: var X) =
    echo "Destroyed"

  proc main() =
    for x in 0 .. 2:
      var obj = X()
      echo obj
    # The destructor call is invoked after "end" is printed
    echo "end"

  main()

echo "-------------------------"

block:
  type
    X = object

  proc `=destroy`(x: var X) =
    echo "Destroyed"

  proc main() =
    block:
      var obj = X()
      echo obj
      # The destructor is not called when obj goes out of scope
    echo "end"

  main()
