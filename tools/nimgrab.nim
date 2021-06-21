

when defined(windows):
  import os, urldownloader

  proc syncDownload(url, file: string) =
    proc progress(status: DownloadStatus, progress: uint, total: uint,
                  message: string) {.gcsafe.} =
      echo "Downloading " & url
      let t = total.BiggestInt
      if t != 0:
        echo clamp(int(progress.BiggestInt*100 div t), 0, 100), "%"
      else:
        echo "0%"

    downloadToFile(url, file, {optUseCache}, progress)
    echo "100%"

else:
  import os, asyncdispatch, httpclient

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
