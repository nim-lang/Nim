{.deadCodeElim: on.}
import
  glib2, pango

proc split_file_list*(str: cstring): PPchar{.cdecl, dynlib: lib,
    importc: "pango_split_file_list".}
proc trim_string*(str: cstring): cstring{.cdecl, dynlib: lib,
    importc: "pango_trim_string".}
proc read_line*(stream: TFile, str: PGString): gint{.cdecl, dynlib: lib,
    importc: "pango_read_line".}
proc skip_space*(pos: PPchar): gboolean{.cdecl, dynlib: lib,
    importc: "pango_skip_space".}
proc scan_word*(pos: PPchar, OutStr: PGString): gboolean{.cdecl, dynlib: lib,
    importc: "pango_scan_word".}
proc scan_string*(pos: PPchar, OutStr: PGString): gboolean{.cdecl, dynlib: lib,
    importc: "pango_scan_string".}
proc scan_int*(pos: PPchar, OutInt: ptr int32): gboolean{.cdecl, dynlib: lib,
    importc: "pango_scan_int".}
proc config_key_get*(key: cstring): cstring{.cdecl, dynlib: lib,
    importc: "pango_config_key_get".}
proc lookup_aliases*(fontname: cstring, families: PPPchar, n_families: ptr int32){.
    cdecl, dynlib: lib, importc: "pango_lookup_aliases".}
proc parse_style*(str: cstring, style: PStyle, warn: gboolean): gboolean{.cdecl,
    dynlib: lib, importc: "pango_parse_style".}
proc parse_variant*(str: cstring, variant: PVariant, warn: gboolean): gboolean{.
    cdecl, dynlib: lib, importc: "pango_parse_variant".}
proc parse_weight*(str: cstring, weight: PWeight, warn: gboolean): gboolean{.
    cdecl, dynlib: lib, importc: "pango_parse_weight".}
proc parse_stretch*(str: cstring, stretch: PStretch, warn: gboolean): gboolean{.
    cdecl, dynlib: lib, importc: "pango_parse_stretch".}
proc get_sysconf_subdirectory*(): cstring{.cdecl, dynlib: lib,
    importc: "pango_get_sysconf_subdirectory".}
proc get_lib_subdirectory*(): cstring{.cdecl, dynlib: lib,
                                      importc: "pango_get_lib_subdirectory".}
proc log2vis_get_embedding_levels*(str: Pgunichar, len: int32,
                                   pbase_dir: PDirection,
                                   embedding_level_list: Pguint8): gboolean{.
    cdecl, dynlib: lib, importc: "pango_log2vis_get_embedding_levels".}
proc get_mirror_char*(ch: gunichar, mirrored_ch: Pgunichar): gboolean{.cdecl,
    dynlib: lib, importc: "pango_get_mirror_char".}
proc get_sample_string*(language: PLanguage): cstring{.cdecl,
    dynlib: lib, importc: "pango_language_get_sample_string".}
