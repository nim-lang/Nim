discard """
  nimout: '''
(true, true)
ok1
ok5
done
'''
  output: '''
(false, true)
ok2
ok4
ok6
done
'''
"""

proc main()=
  let a1 = nimvmRunning
  const a2 = nimvmRunning
  echo (a1, a2)
  if nimvmRunning and true:
    echo "ok1"
  else:
    echo "ok2"
  if not nimvmRunning:
    echo "ok4"
  when nimvm:
    echo "ok5"
  else:
    echo"ok6"
  echo "done"

static: main()
main()
