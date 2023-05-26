import std/[os, httpclient]

proc syncDownload(url, file: string) =
  let client = newHttpClient()
  proc onProgressChanged(total, progress, speed: BiggestInt) =
    var message = "Downloading "
    message.add url
    message.add ' '
    message.addInt speed div 1000
    message.add "kb/s\n"
    message.add $clamp(int(progress * 100 div total), 0, 100)
    message.add '%'
    echo message

  client.onProgressChanged = onProgressChanged
  client.downloadFile(url, file)
  client.close()
  echo "100%"

if os.paramCount() != 2:
  quit "Usage: nimgrab <url> <file>"
else:
  syncDownload(os.paramStr(1), os.paramStr(2))
