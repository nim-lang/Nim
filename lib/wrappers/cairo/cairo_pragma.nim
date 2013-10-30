# included by cairo bindings

when defined(use_pkg_config) or defined(use_pkg_config_static):
    {.pragma: libcairo, cdecl.}
    when defined(use_pkg_config_static):
        {.passl: gorge("pkg-config cairo --libs --static").}
    else:
        {.passl: gorge("pkg-config cairo --libs").}
else:
    when defined(windows):
      const LIB_CAIRO* = "libcairo-2.dll"
    elif defined(macosx):
      const LIB_CAIRO* = "libcairo.dylib"
    else:
      const LIB_CAIRO* = "libcairo.so(|.2)"
    {.pragma: libcairo, cdecl, dynlib: LIB_CAIRO.}
