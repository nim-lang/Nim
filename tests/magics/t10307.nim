discard """
  cmd: "nim c -d:useGcAssert $file"
  output: '''running someProc(true)
res: yes
yes
running someProc(false)
<<<<<<< HEAD
res:
=======
res: 

>>>>>>> upstream/devel
'''
"""

proc someProc(x:bool):cstring =
  var res:string = ""
  if x:
    res = "yes"
  echo "res: ", res
  GC_ref(res)
  result = res

echo "running someProc(true)"
echo someProc(true)

echo "running someProc(false)"
<<<<<<< HEAD
echo someProc(false)
=======
echo someProc(false)
>>>>>>> upstream/devel
