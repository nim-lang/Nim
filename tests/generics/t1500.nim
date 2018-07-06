type
  TFtpBase*[SockType] = object
    job: TFTPJob[SockType]

  PFtpBase*[SockType] = ref TFtpBase[SockType]
  TFtpClient* = TFtpBase[string]
  TFTPJob[T] = object
