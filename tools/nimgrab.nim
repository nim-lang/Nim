import std/[os, httpclient]

proc syncDownload(url, file: string) =
  var client = newHttpClient()
  proc onProgressChanged(total, progress, speed: BiggestInt) =
    echo "Downloading " & url & " " & $(speed div 1000) & "kb/s"
    echo clamp(int(progress*100 div total), 0, 100), "%"

  client.onProgressChanged = onProgressChanged
  client.downloadFile(url, file)
  echo "100%"

if os.paramCount() != 2:
  quit "Usage: nimgrab <url> <file>"
else:
  syncDownload(os.paramStr(1), os.paramStr(2))
