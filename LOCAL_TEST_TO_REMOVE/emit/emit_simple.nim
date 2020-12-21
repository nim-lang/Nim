proc xx() =
  echo "xx"
  var x= 420
  {.emit: ["""printf("x from C : %i\n",""", x, ");"] .}

proc yy() =
  echo "yy"
  xx()

yy()
