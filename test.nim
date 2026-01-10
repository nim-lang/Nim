proc fff() {.raises: [].} =
  {.cast(raises: ValueError).}:
    echo "hello"
