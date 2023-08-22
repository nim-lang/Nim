import packagea

proc test*(): string =
  when defined(windows) or defined(macosx):
    $PackageA.test(6, 9)
  elif defined(unix):
    $packagea.test(6, 9)
  else:
    {.error: "Sorry, your platform is not supported.".}
