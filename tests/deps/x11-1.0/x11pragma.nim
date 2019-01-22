# included from xlib bindings


when defined(use_pkg_config) or defined(use_pkg_config_static):
    {.pragma: libx11, cdecl, importc.}
    {.pragma: libx11c, cdecl.}
    when defined(use_pkg_config_static):
        {.passl: gorge("pkg-config x11 --static --libs").}
    else:
        {.passl: gorge("pkg-config x11 --libs").}
else:
    when defined(macosx):
        const
          libX11* = "libX11.dylib"
    else:
        const
          libX11* = "libX11.so(|.6)"

    {.pragma: libx11, cdecl, dynlib: libX11, importc.}
    {.pragma: libx11c, cdecl, dynlib: libX11.}
