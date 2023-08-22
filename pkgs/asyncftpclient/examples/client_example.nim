import asyncftpclient, asyncdispatch

var ftp = newAsyncFtpClient("example.com", user = "test", pass = "test")
proc main(ftp: AsyncFtpClient) {.async.} =
  await ftp.connect()
  echo await ftp.pwd()
  echo await ftp.listDirs()
  await ftp.store("payload.jpg", "payload.jpg")
  await ftp.retrFile("payload.jpg", "payload2.jpg")
  await ftp.rename("payload.jpg", "payload_renamed.jpg")
  await ftp.store("payload.jpg", "payload_remove.jpg")
  await ftp.removeFile("payload_remove.jpg")
  await ftp.createDir("deleteme")
  await ftp.removeDir("deleteme")
  echo("Finished")

waitFor main(ftp)
