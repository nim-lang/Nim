discard """
  action: "run"
  output: '''
caught
index out of bounds, the container is empty
'''
"""

proc fun() =
  var z: seq[string]
  discard z[4]

proc main()=
  try:
    fun()
  except Exception as e:
    echo "caught"
    echo getCurrentExceptionMsg()

main()