import options
converter option2val*[T](val: Option[T]): T =
  return val.get()
