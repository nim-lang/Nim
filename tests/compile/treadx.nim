
when not defined(windows):
  import posix

  var inp = ""
  var buf: array[0..10, char]
  while true:
    var r = read(0, addr(buf), sizeof(buf)-1)
    add inp, $buf
    if r != sizeof(buf)-1: break

  echo inp
  #dafkladskölklödsaf ölksdakölfölksfklwe4iojr389wr 89uweokf sdlkf jweklr jweflksdj fioewjfsdlfsd

