{.deadCodeElim: on.}
import 
  glib2, pango

type 
  pint32* = ptr int32

proc pango_split_file_list*(str: cstring): PPchar{.cdecl, dynlib: pangolib, 
    importc: "pango_split_file_list".}
proc pango_trim_string*(str: cstring): cstring{.cdecl, dynlib: pangolib, 
    importc: "pango_trim_string".}
proc pango_read_line*(stream: TFile, str: PGString): gint{.cdecl, 
    dynlib: pangolib, importc: "pango_read_line".}
proc pango_skip_space*(pos: PPchar): gboolean{.cdecl, dynlib: pangolib, 
    importc: "pango_skip_space".}
proc pango_scan_word*(pos: PPchar, OutStr: PGString): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_scan_word".}
proc pango_scan_string*(pos: PPchar, OutStr: PGString): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_scan_string".}
proc pango_scan_int*(pos: PPchar, OutInt: pint32): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_scan_int".}
proc pango_config_key_get(key: cstring): cstring{.cdecl, dynlib: pangolib, 
    importc: "pango_config_key_get".}
proc pango_lookup_aliases(fontname: cstring, families: PPPchar, 
                          n_families: pint32){.cdecl, dynlib: pangolib, 
    importc: "pango_lookup_aliases".}
proc pango_parse_style*(str: cstring, style: PStyle, warn: gboolean): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_parse_style".}
proc pango_parse_variant*(str: cstring, variant: PVariant, warn: gboolean): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_parse_variant".}
proc pango_parse_weight*(str: cstring, weight: PWeight, warn: gboolean): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_parse_weight".}
proc pango_parse_stretch*(str: cstring, stretch: PStretch, warn: gboolean): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_parse_stretch".}
proc pango_get_sysconf_subdirectory(): cstring{.cdecl, dynlib: pangolib, 
    importc: "pango_get_sysconf_subdirectory".}
proc pango_get_lib_subdirectory(): cstring{.cdecl, dynlib: pangolib, 
    importc: "pango_get_lib_subdirectory".}
proc pango_log2vis_get_embedding_levels*(str: Pgunichar, len: int32, 
    pbase_dir: PDirection, embedding_level_list: Pguint8): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_log2vis_get_embedding_levels".}
proc pango_get_mirror_char*(ch: gunichar, mirrored_ch: Pgunichar): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_get_mirror_char".}
proc pango_language_get_sample_string*(language: PLanguage): cstring{.cdecl, 
    dynlib: pangolib, importc: "pango_language_get_sample_string".}