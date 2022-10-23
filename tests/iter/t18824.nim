discard """
  output: '''trying
exception caught
finally block
'''


"""











iterator tryFinally() {.closure.} =
  block route:
    try:
      echo "trying"
      raise
    except:
      echo "exception caught"
      break route
    finally:
      echo "finally block"

var x = tryFinally
x()
