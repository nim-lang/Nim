set args c /tmp/scratch.nim
source ~/gdb/nim-gdb.py

rbreak reprEnum

run

next
next
next

print n->kind

kill
quit
