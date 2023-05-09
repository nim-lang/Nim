## Coroutine detection logic

template coroutinesSupportedPlatform(): bool =
  when defined(sparc) or defined(ELATE) or defined(boehmgc) or defined(gogc) or
    defined(nogc) or defined(gcRegions) or defined(gcMarkAndSweep):
    false
  else:
    true

when defined(nimCoroutines):
  # Explicit opt-in.
  when not coroutinesSupportedPlatform():
    {.error: "Coroutines are not supported on this architecture and/or garbage collector.".}
  const nimCoroutines* = true
elif defined(noNimCoroutines):
  # Explicit opt-out.
  const nimCoroutines* = false
else:
  # Autodetect coroutine support.
  const nimCoroutines* = false
