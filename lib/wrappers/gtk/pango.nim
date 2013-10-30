{.deadCodeElim: on.}
import
  glib2

when defined(win32):
  const
    lib* = "libpango-1.0-0.dll"
elif defined(macosx):
  const
    lib* = "libpango-1.0.dylib"
else:
  const
    lib* = "libpango-1.0.so.0"
type
  TFont* {.pure, final.} = object
  PFont* = ptr TFont
  TFontFamily* {.pure, final.} = object
  PFontFamily* = ptr TFontFamily
  TFontSet* {.pure, final.} = object
  PFontset* = ptr TFontset
  TFontMetrics* {.pure, final.} = object
  PFontMetrics* = ptr TFontMetrics
  TFontFace* {.pure, final.} = object
  PFontFace* = ptr TFontFace
  TFontMap* {.pure, final.} = object
  PFontMap* = ptr TFontMap
  TFontsetClass {.pure, final.} = object
  PFontsetClass* = ptr TFontSetClass
  TFontFamilyClass* {.pure, final.} = object
  PFontFamilyClass* = ptr TFontFamilyClass
  TFontFaceClass* {.pure, final.} = object
  PFontFaceClass* = ptr TFontFaceClass
  TFontClass* {.pure, final.} = object
  PFontClass* = ptr TFontClass
  TFontMapClass* {.pure, final.} = object
  PFontMapClass* = ptr TFontMapClass
  PFontDescription* = ptr TFontDescription
  TFontDescription* {.pure, final.} = object
  PAttrList* = ptr TAttrList
  TAttrList* {.pure, final.} = object
  PAttrIterator* = ptr TAttrIterator
  TAttrIterator* {.pure, final.} = object
  PLayout* = ptr TLayout
  TLayout* {.pure, final.} = object
  PLayoutClass* = ptr TLayoutClass
  TLayoutClass* {.pure, final.} = object
  PLayoutIter* = ptr TLayoutIter
  TLayoutIter* {.pure, final.} = object
  PContext* = ptr TContext
  TContext* {.pure, final.} = object
  PContextClass* = ptr TContextClass
  TContextClass* {.pure, final.} = object
  PFontsetSimple* = ptr TFontsetSimple
  TFontsetSimple* {.pure, final.} = object
  PTabArray* = ptr TTabArray
  TTabArray* {.pure, final.} = object
  PGlyphString* = ptr TGlyphString
  PAnalysis* = ptr TAnalysis
  PItem* = ptr TItem
  PLanguage* = ptr TLanguage
  TLanguage* {.pure, final.} = object
  PGlyph* = ptr TGlyph
  TGlyph* = guint32
  PRectangle* = ptr TRectangle
  TRectangle*{.final, pure.} = object
    x*: int32
    y*: int32
    width*: int32
    height*: int32

  PDirection* = ptr TDirection
  TDirection* = enum
    DIRECTION_LTR, DIRECTION_RTL, DIRECTION_TTB_LTR, DIRECTION_TTB_RTL
  PColor* = ptr TColor
  TColor*{.final, pure.} = object
    red*: guint16
    green*: guint16
    blue*: guint16

  PAttrType* = ptr TAttrType
  TAttrType* = int32
  PUnderline* = ptr TUnderline
  TUnderline* = int32
  PAttribute* = ptr TAttribute
  PAttrClass* = ptr TAttrClass
  TAttribute*{.final, pure.} = object
    klass*: PAttrClass
    start_index*: int
    end_index*: int

  TAttrClass*{.final, pure.} = object
    `type`*: TAttrType
    copy*: proc (attr: PAttribute): PAttribute{.cdecl.}
    destroy*: proc (attr: PAttribute){.cdecl.}
    equal*: proc (attr1: PAttribute, attr2: PAttribute): gboolean{.cdecl.}

  PAttrString* = ptr TAttrString
  TAttrString*{.final, pure.} = object
    attr*: TAttribute
    value*: cstring

  PAttrLanguage* = ptr TAttrLanguage
  TAttrLanguage*{.final, pure.} = object
    attr*: TAttribute
    value*: PLanguage

  PAttrInt* = ptr TAttrInt
  TAttrInt*{.final, pure.} = object
    attr*: TAttribute
    value*: int32

  PAttrFloat* = ptr TAttrFloat
  TAttrFloat*{.final, pure.} = object
    attr*: TAttribute
    value*: gdouble

  PAttrColor* = ptr TAttrColor
  TAttrColor*{.final, pure.} = object
    attr*: TAttribute
    color*: TColor

  PAttrShape* = ptr TAttrShape
  TAttrShape*{.final, pure.} = object
    attr*: TAttribute
    ink_rect*: TRectangle
    logical_rect*: TRectangle

  PAttrFontDesc* = ptr TAttrFontDesc
  TAttrFontDesc*{.final, pure.} = object
    attr*: TAttribute
    desc*: PFontDescription

  PLogAttr* = ptr TLogAttr
  TLogAttr*{.final, pure.} = object
    flag0*: guint16

  PCoverageLevel* = ptr TCoverageLevel
  TCoverageLevel* = enum
    COVERAGE_NONE, COVERAGE_FALLBACK, COVERAGE_APPROXIMATE, COVERAGE_EXACT
  PBlockInfo* = ptr TBlockInfo
  TBlockInfo*{.final, pure.} = object
    data*: Pguchar
    level*: TCoverageLevel

  PCoverage* = ptr TCoverage
  TCoverage*{.final, pure.} = object
    ref_count*: int
    n_blocks*: int32
    data_size*: int32
    blocks*: PBlockInfo

  PEngineRange* = ptr TEngineRange
  TEngineRange*{.final, pure.} = object
    start*: int32
    theEnd*: int32
    langs*: cstring

  PEngineInfo* = ptr TEngineInfo
  TEngineInfo*{.final, pure.} = object
    id*: cstring
    engine_type*: cstring
    render_type*: cstring
    ranges*: PEngineRange
    n_ranges*: gint

  PEngine* = ptr TEngine
  TEngine*{.final, pure.} = object
    id*: cstring
    `type`*: cstring
    length*: gint

  TEngineLangScriptBreak* = proc (text: cstring, len: int32,
                                  analysis: PAnalysis, attrs: PLogAttr,
                                  attrs_len: int32){.cdecl.}
  PEngineLang* = ptr TEngineLang
  TEngineLang*{.final, pure.} = object
    engine*: TEngine
    script_break*: TEngineLangScriptBreak

  TEngineShapeScript* = proc (font: PFont, text: cstring, length: int32,
                              analysis: PAnalysis, glyphs: PGlyphString){.cdecl.}
  TEngineShapeGetCoverage* = proc (font: PFont, language: PLanguage): PCoverage{.
      cdecl.}
  PEngineShape* = ptr TEngineShape
  TEngineShape*{.final, pure.} = object
    engine*: TEngine
    script_shape*: TEngineShapeScript
    get_coverage*: TEngineShapeGetCoverage

  PStyle* = ptr TStyle
  TStyle* = gint
  PVariant* = ptr TVariant
  TVariant* = gint
  PWeight* = ptr TWeight
  TWeight* = gint
  PStretch* = ptr TStretch
  TStretch* = gint
  PFontMask* = ptr TFontMask
  TFontMask* = int32
  PGlyphUnit* = ptr TGlyphUnit
  TGlyphUnit* = gint32
  PGlyphGeometry* = ptr TGlyphGeometry
  TGlyphGeometry*{.final, pure.} = object
    width*: TGlyphUnit
    x_offset*: TGlyphUnit
    y_offset*: TGlyphUnit

  PGlyphVisAttr* = ptr TGlyphVisAttr
  TGlyphVisAttr*{.final, pure.} = object
    flag0*: int16

  PGlyphInfo* = ptr TGlyphInfo
  TGlyphInfo*{.final, pure.} = object
    glyph*: TGlyph
    geometry*: TGlyphGeometry
    attr*: TGlyphVisAttr

  TGlyphString*{.final, pure.} = object
    num_glyphs*: gint
    glyphs*: PGlyphInfo
    log_clusters*: Pgint
    space*: gint

  TAnalysis*{.final, pure.} = object
    shape_engine*: PEngineShape
    lang_engine*: PEngineLang
    font*: PFont
    level*: guint8
    language*: PLanguage
    extra_attrs*: PGSList

  TItem*{.final, pure.} = object
    offset*: gint
    length*: gint
    num_chars*: gint
    analysis*: TAnalysis

  PAlignment* = ptr TAlignment
  TAlignment* = enum
    ALIGN_LEFT, ALIGN_CENTER, ALIGN_RIGHT
  PWrapMode* = ptr TWrapMode
  TWrapMode* = enum
    WRAP_WORD, WRAP_CHAR
  PLayoutLine* = ptr TLayoutLine
  TLayoutLine*{.final, pure.} = object
    layout*: PLayout
    start_index*: gint
    length*: gint
    runs*: PGSList

  PLayoutRun* = ptr TLayoutRun
  TLayoutRun*{.final, pure.} = object
    item*: PItem
    glyphs*: PGlyphString

  PTabAlign* = ptr TTabAlign
  TTabAlign* = enum
    TAB_LEFT

const
  SCALE* = 1024

proc PIXELS*(d: int): int
proc ASCENT*(rect: TRectangle): int32
proc DESCENT*(rect: TRectangle): int32
proc LBEARING*(rect: TRectangle): int32
proc RBEARING*(rect: TRectangle): int32
proc TYPE_LANGUAGE*(): GType
proc language_get_type*(): GType{.cdecl, dynlib: lib,
                                  importc: "pango_language_get_type".}
proc language_from_string*(language: cstring): PLanguage{.cdecl, dynlib: lib,
    importc: "pango_language_from_string".}
proc to_string*(language: PLanguage): cstring
proc matches*(language: PLanguage, range_list: cstring): gboolean{.
    cdecl, dynlib: lib, importc: "pango_language_matches".}
const
  ATTR_INVALID* = 0
  ATTR_LANGUAGE* = 1
  ATTR_FAMILY* = 2
  ATTR_STYLE* = 3
  ATTR_WEIGHT* = 4
  ATTR_VARIANT* = 5
  ATTR_STRETCH* = 6
  ATTR_SIZE* = 7
  ATTR_FONT_DESC* = 8
  ATTR_FOREGROUND* = 9
  ATTR_BACKGROUND* = 10
  ATTR_UNDERLINE* = 11
  ATTR_STRIKETHROUGH* = 12
  ATTR_RISE* = 13
  ATTR_SHAPE* = 14
  ATTR_SCALE* = 15
  UNDERLINE_NONE* = 0
  UNDERLINE_SINGLE* = 1
  UNDERLINE_DOUBLE* = 2
  UNDERLINE_LOW* = 3

proc TYPE_COLOR*(): GType
proc color_get_type*(): GType{.cdecl, dynlib: lib,
                               importc: "pango_color_get_type".}
proc copy*(src: PColor): PColor{.cdecl, dynlib: lib,
                                       importc: "pango_color_copy".}
proc free*(color: PColor){.cdecl, dynlib: lib, importc: "pango_color_free".}
proc parse*(color: PColor, spec: cstring): gboolean{.cdecl, dynlib: lib,
    importc: "pango_color_parse".}
proc TYPE_ATTR_LIST*(): GType
proc attr_type_register*(name: cstring): TAttrType{.cdecl, dynlib: lib,
    importc: "pango_attr_type_register".}
proc copy*(attr: PAttribute): PAttribute{.cdecl, dynlib: lib,
    importc: "pango_attribute_copy".}
proc destroy*(attr: PAttribute){.cdecl, dynlib: lib,
    importc: "pango_attribute_destroy".}
proc equal*(attr1: PAttribute, attr2: PAttribute): gboolean{.cdecl,
    dynlib: lib, importc: "pango_attribute_equal".}
proc attr_language_new*(language: PLanguage): PAttribute{.cdecl, dynlib: lib,
    importc: "pango_attr_language_new".}
proc attr_family_new*(family: cstring): PAttribute{.cdecl, dynlib: lib,
    importc: "pango_attr_family_new".}
proc attr_foreground_new*(red: guint16, green: guint16, blue: guint16): PAttribute{.
    cdecl, dynlib: lib, importc: "pango_attr_foreground_new".}
proc attr_background_new*(red: guint16, green: guint16, blue: guint16): PAttribute{.
    cdecl, dynlib: lib, importc: "pango_attr_background_new".}
proc attr_size_new*(size: int32): PAttribute{.cdecl, dynlib: lib,
    importc: "pango_attr_size_new".}
proc attr_style_new*(style: TStyle): PAttribute{.cdecl, dynlib: lib,
    importc: "pango_attr_style_new".}
proc attr_weight_new*(weight: TWeight): PAttribute{.cdecl, dynlib: lib,
    importc: "pango_attr_weight_new".}
proc attr_variant_new*(variant: TVariant): PAttribute{.cdecl, dynlib: lib,
    importc: "pango_attr_variant_new".}
proc attr_stretch_new*(stretch: TStretch): PAttribute{.cdecl, dynlib: lib,
    importc: "pango_attr_stretch_new".}
proc attr_font_desc_new*(desc: PFontDescription): PAttribute{.cdecl,
    dynlib: lib, importc: "pango_attr_font_desc_new".}
proc attr_underline_new*(underline: TUnderline): PAttribute{.cdecl, dynlib: lib,
    importc: "pango_attr_underline_new".}
proc attr_strikethrough_new*(strikethrough: gboolean): PAttribute{.cdecl,
    dynlib: lib, importc: "pango_attr_strikethrough_new".}
proc attr_rise_new*(rise: int32): PAttribute{.cdecl, dynlib: lib,
    importc: "pango_attr_rise_new".}
proc attr_shape_new*(ink_rect: PRectangle, logical_rect: PRectangle): PAttribute{.
    cdecl, dynlib: lib, importc: "pango_attr_shape_new".}
proc attr_scale_new*(scale_factor: gdouble): PAttribute{.cdecl, dynlib: lib,
    importc: "pango_attr_scale_new".}
proc attr_list_get_type*(): GType{.cdecl, dynlib: lib,
                                   importc: "pango_attr_list_get_type".}
proc attr_list_new*(): PAttrList{.cdecl, dynlib: lib,
                                  importc: "pango_attr_list_new".}
proc reference*(list: PAttrList){.cdecl, dynlib: lib,
                                      importc: "pango_attr_list_ref".}
proc unref*(list: PAttrList){.cdecl, dynlib: lib,
                                        importc: "pango_attr_list_unref".}
proc copy*(list: PAttrList): PAttrList{.cdecl, dynlib: lib,
    importc: "pango_attr_list_copy".}
proc insert*(list: PAttrList, attr: PAttribute){.cdecl, dynlib: lib,
    importc: "pango_attr_list_insert".}
proc insert_before*(list: PAttrList, attr: PAttribute){.cdecl,
    dynlib: lib, importc: "pango_attr_list_insert_before".}
proc change*(list: PAttrList, attr: PAttribute){.cdecl, dynlib: lib,
    importc: "pango_attr_list_change".}
proc splice*(list: PAttrList, other: PAttrList, pos: gint, len: gint){.
    cdecl, dynlib: lib, importc: "pango_attr_list_splice".}
proc get_iterator*(list: PAttrList): PAttrIterator{.cdecl,
    dynlib: lib, importc: "pango_attr_list_get_iterator".}
proc attr_iterator_range*(`iterator`: PAttrIterator, start: Pgint, theEnd: Pgint){.
    cdecl, dynlib: lib, importc: "pango_attr_iterator_range".}
proc attr_iterator_next*(`iterator`: PAttrIterator): gboolean{.cdecl,
    dynlib: lib, importc: "pango_attr_iterator_next".}
proc attr_iterator_copy*(`iterator`: PAttrIterator): PAttrIterator{.cdecl,
    dynlib: lib, importc: "pango_attr_iterator_copy".}
proc attr_iterator_destroy*(`iterator`: PAttrIterator){.cdecl, dynlib: lib,
    importc: "pango_attr_iterator_destroy".}
proc attr_iterator_get*(`iterator`: PAttrIterator, `type`: TAttrType): PAttribute{.
    cdecl, dynlib: lib, importc: "pango_attr_iterator_get".}
proc attr_iterator_get_font*(`iterator`: PAttrIterator, desc: PFontDescription,
                             language: var PLanguage, extra_attrs: PPGSList){.
    cdecl, dynlib: lib, importc: "pango_attr_iterator_get_font".}
proc parse_markup*(markup_text: cstring, length: int32, accel_marker: gunichar,
                   attr_list: var PAttrList, text: PPchar,
                   accel_char: Pgunichar, error: pointer): gboolean{.cdecl,
    dynlib: lib, importc: "pango_parse_markup".}
const
  bm_TPangoLogAttr_is_line_break* = 0x0001'i16
  bp_TPangoLogAttr_is_line_break* = 0'i16
  bm_TPangoLogAttr_is_mandatory_break* = 0x0002'i16
  bp_TPangoLogAttr_is_mandatory_break* = 1'i16
  bm_TPangoLogAttr_is_char_break* = 0x0004'i16
  bp_TPangoLogAttr_is_char_break* = 2'i16
  bm_TPangoLogAttr_is_white* = 0x0008'i16
  bp_TPangoLogAttr_is_white* = 3'i16
  bm_TPangoLogAttr_is_cursor_position* = 0x0010'i16
  bp_TPangoLogAttr_is_cursor_position* = 4'i16
  bm_TPangoLogAttr_is_word_start* = 0x0020'i16
  bp_TPangoLogAttr_is_word_start* = 5'i16
  bm_TPangoLogAttr_is_word_end* = 0x0040'i16
  bp_TPangoLogAttr_is_word_end* = 6'i16
  bm_TPangoLogAttr_is_sentence_boundary* = 0x0080'i16
  bp_TPangoLogAttr_is_sentence_boundary* = 7'i16
  bm_TPangoLogAttr_is_sentence_start* = 0x0100'i16
  bp_TPangoLogAttr_is_sentence_start* = 8'i16
  bm_TPangoLogAttr_is_sentence_end* = 0x0200'i16
  bp_TPangoLogAttr_is_sentence_end* = 9'i16

proc is_line_break*(a: PLogAttr): guint
proc set_is_line_break*(a: PLogAttr, `is_line_break`: guint)
proc is_mandatory_break*(a: PLogAttr): guint
proc set_is_mandatory_break*(a: PLogAttr, `is_mandatory_break`: guint)
proc is_char_break*(a: PLogAttr): guint
proc set_is_char_break*(a: PLogAttr, `is_char_break`: guint)
proc is_white*(a: PLogAttr): guint
proc set_is_white*(a: PLogAttr, `is_white`: guint)
proc is_cursor_position*(a: PLogAttr): guint
proc set_is_cursor_position*(a: PLogAttr, `is_cursor_position`: guint)
proc is_word_start*(a: PLogAttr): guint
proc set_is_word_start*(a: PLogAttr, `is_word_start`: guint)
proc is_word_end*(a: PLogAttr): guint
proc set_is_word_end*(a: PLogAttr, `is_word_end`: guint)
proc is_sentence_boundary*(a: PLogAttr): guint
proc set_is_sentence_boundary*(a: PLogAttr, `is_sentence_boundary`: guint)
proc is_sentence_start*(a: PLogAttr): guint
proc set_is_sentence_start*(a: PLogAttr, `is_sentence_start`: guint)
proc is_sentence_end*(a: PLogAttr): guint
proc set_is_sentence_end*(a: PLogAttr, `is_sentence_end`: guint)
proc `break`*(text: cstring, length: int32, analysis: PAnalysis, attrs: PLogAttr,
            attrs_len: int32){.cdecl, dynlib: lib, importc: "pango_break".}
proc find_paragraph_boundary*(text: cstring, length: gint,
                              paragraph_delimiter_index: Pgint,
                              next_paragraph_start: Pgint){.cdecl, dynlib: lib,
    importc: "pango_find_paragraph_boundary".}
proc get_log_attrs*(text: cstring, length: int32, level: int32,
                    language: PLanguage, log_attrs: PLogAttr, attrs_len: int32){.
    cdecl, dynlib: lib, importc: "pango_get_log_attrs".}
proc TYPE_CONTEXT*(): GType
proc CONTEXT*(anObject: pointer): PContext
proc CONTEXT_CLASS*(klass: pointer): PContextClass
proc IS_CONTEXT*(anObject: pointer): bool
proc IS_CONTEXT_CLASS*(klass: pointer): bool
proc GET_CLASS*(obj: PContext): PContextClass
proc context_get_type*(): GType{.cdecl, dynlib: lib,
                                 importc: "pango_context_get_type".}
proc list_families*(context: PContext,
                            families: openarray[ptr PFontFamily]){.cdecl,
    dynlib: lib, importc: "pango_context_list_families".}
proc load_font*(context: PContext, desc: PFontDescription): PFont{.
    cdecl, dynlib: lib, importc: "pango_context_load_font".}
proc load_fontset*(context: PContext, desc: PFontDescription,
                           language: PLanguage): PFontset{.cdecl, dynlib: lib,
    importc: "pango_context_load_fontset".}
proc get_metrics*(context: PContext, desc: PFontDescription,
                          language: PLanguage): PFontMetrics{.cdecl,
    dynlib: lib, importc: "pango_context_get_metrics".}
proc set_font_description*(context: PContext, desc: PFontDescription){.
    cdecl, dynlib: lib, importc: "pango_context_set_font_description".}
proc get_font_description*(context: PContext): PFontDescription{.cdecl,
    dynlib: lib, importc: "pango_context_get_font_description".}
proc get_language*(context: PContext): PLanguage{.cdecl, dynlib: lib,
    importc: "pango_context_get_language".}
proc set_language*(context: PContext, language: PLanguage){.cdecl,
    dynlib: lib, importc: "pango_context_set_language".}
proc set_base_dir*(context: PContext, direction: TDirection){.cdecl,
    dynlib: lib, importc: "pango_context_set_base_dir".}
proc get_base_dir*(context: PContext): TDirection{.cdecl, dynlib: lib,
    importc: "pango_context_get_base_dir".}
proc itemize*(context: PContext, text: cstring, start_index: int32,
              length: int32, attrs: PAttrList, cached_iter: PAttrIterator): PGList{.
    cdecl, dynlib: lib, importc: "pango_itemize".}
proc coverage_new*(): PCoverage{.cdecl, dynlib: lib,
                                 importc: "pango_coverage_new".}
proc reference*(coverage: PCoverage): PCoverage{.cdecl, dynlib: lib,
    importc: "pango_coverage_ref".}
proc unref*(coverage: PCoverage){.cdecl, dynlib: lib,
    importc: "pango_coverage_unref".}
proc copy*(coverage: PCoverage): PCoverage{.cdecl, dynlib: lib,
    importc: "pango_coverage_copy".}
proc get*(coverage: PCoverage, index: int32): TCoverageLevel{.cdecl,
    dynlib: lib, importc: "pango_coverage_get".}
proc set*(coverage: PCoverage, index: int32, level: TCoverageLevel){.
    cdecl, dynlib: lib, importc: "pango_coverage_set".}
proc max*(coverage: PCoverage, other: PCoverage){.cdecl, dynlib: lib,
    importc: "pango_coverage_max".}
proc to_bytes*(coverage: PCoverage, bytes: PPguchar, n_bytes: var int32){.
    cdecl, dynlib: lib, importc: "pango_coverage_to_bytes".}
proc coverage_from_bytes*(bytes: Pguchar, n_bytes: int32): PCoverage{.cdecl,
    dynlib: lib, importc: "pango_coverage_from_bytes".}
proc TYPE_FONTSET*(): GType
proc FONTSET*(anObject: pointer): PFontset
proc IS_FONTSET*(anObject: pointer): bool
proc fontset_get_type*(): GType{.cdecl, dynlib: lib,
                                 importc: "pango_fontset_get_type".}
proc get_font*(fontset: PFontset, wc: guint): PFont{.cdecl, dynlib: lib,
    importc: "pango_fontset_get_font".}
proc get_metrics*(fontset: PFontset): PFontMetrics{.cdecl, dynlib: lib,
    importc: "pango_fontset_get_metrics".}
const
  STYLE_NORMAL* = 0
  STYLE_OBLIQUE* = 1
  STYLE_ITALIC* = 2
  VARIANT_NORMAL* = 0
  VARIANT_SMALL_CAPS* = 1
  WEIGHT_ULTRALIGHT* = 200
  WEIGHT_LIGHT* = 300
  WEIGHT_NORMAL* = 400
  WEIGHT_BOLD* = 700
  WEIGHT_ULTRABOLD* = 800
  WEIGHT_HEAVY* = 900
  STRETCH_ULTRA_CONDENSED* = 0
  STRETCH_EXTRA_CONDENSED* = 1
  STRETCH_CONDENSED* = 2
  STRETCH_SEMI_CONDENSED* = 3
  STRETCH_NORMAL* = 4
  STRETCH_SEMI_EXPANDED* = 5
  STRETCH_EXPANDED* = 6
  STRETCH_EXTRA_EXPANDED* = 7
  STRETCH_ULTRA_EXPANDED* = 8
  FONT_MASK_FAMILY* = 1 shl 0
  FONT_MASK_STYLE* = 1 shl 1
  FONT_MASK_VARIANT* = 1 shl 2
  FONT_MASK_WEIGHT* = 1 shl 3
  FONT_MASK_STRETCH* = 1 shl 4
  FONT_MASK_SIZE* = 1 shl 5
  SCALE_XX_SMALL* = 0.578704
  SCALE_X_SMALL* = 0.644444
  SCALE_SMALL* = 0.833333
  SCALE_MEDIUM* = 1.00000
  SCALE_LARGE* = 1.20000
  SCALE_X_LARGE* = 1.44000
  SCALE_XX_LARGE* = 1.72800

proc TYPE_FONT_DESCRIPTION*(): GType
proc font_description_get_type*(): GType{.cdecl, dynlib: lib,
    importc: "pango_font_description_get_type".}
proc font_description_new*(): PFontDescription{.cdecl, dynlib: lib,
    importc: "pango_font_description_new".}
proc copy*(desc: PFontDescription): PFontDescription{.cdecl,
    dynlib: lib, importc: "pango_font_description_copy".}
proc copy_static*(desc: PFontDescription): PFontDescription{.
    cdecl, dynlib: lib, importc: "pango_font_description_copy_static".}
proc hash*(desc: PFontDescription): guint{.cdecl, dynlib: lib,
    importc: "pango_font_description_hash".}
proc equal*(desc1: PFontDescription, desc2: PFontDescription): gboolean{.
    cdecl, dynlib: lib, importc: "pango_font_description_equal".}
proc free*(desc: PFontDescription){.cdecl, dynlib: lib,
    importc: "pango_font_description_free".}
proc font_descriptions_free*(descs: var PFontDescription, n_descs: int32){.
    cdecl, dynlib: lib, importc: "pango_font_descriptions_free".}
proc set_family*(desc: PFontDescription, family: cstring){.
    cdecl, dynlib: lib, importc: "pango_font_description_set_family".}
proc set_family_static*(desc: PFontDescription, family: cstring){.
    cdecl, dynlib: lib, importc: "pango_font_description_set_family_static".}
proc get_family*(desc: PFontDescription): cstring{.cdecl,
    dynlib: lib, importc: "pango_font_description_get_family".}
proc set_style*(desc: PFontDescription, style: TStyle){.cdecl,
    dynlib: lib, importc: "pango_font_description_set_style".}
proc get_style*(desc: PFontDescription): TStyle{.cdecl,
    dynlib: lib, importc: "pango_font_description_get_style".}
proc set_variant*(desc: PFontDescription, variant: TVariant){.
    cdecl, dynlib: lib, importc: "pango_font_description_set_variant".}
proc get_variant*(desc: PFontDescription): TVariant{.cdecl,
    dynlib: lib, importc: "pango_font_description_get_variant".}
proc set_weight*(desc: PFontDescription, weight: TWeight){.
    cdecl, dynlib: lib, importc: "pango_font_description_set_weight".}
proc get_weight*(desc: PFontDescription): TWeight{.cdecl,
    dynlib: lib, importc: "pango_font_description_get_weight".}
proc set_stretch*(desc: PFontDescription, stretch: TStretch){.
    cdecl, dynlib: lib, importc: "pango_font_description_set_stretch".}
proc get_stretch*(desc: PFontDescription): TStretch{.cdecl,
    dynlib: lib, importc: "pango_font_description_get_stretch".}
proc set_size*(desc: PFontDescription, size: gint){.cdecl,
    dynlib: lib, importc: "pango_font_description_set_size".}
proc get_size*(desc: PFontDescription): gint{.cdecl,
    dynlib: lib, importc: "pango_font_description_get_size".}
proc set_absolute_size*(desc: PFontDescription, size: float64){.
    cdecl, dynlib: lib, importc: "pango_font_description_set_absolute_size".}
proc get_size_is_absolute*(desc: PFontDescription,
    size: float64): gboolean{.cdecl, dynlib: lib, importc: "pango_font_description_get_size_is_absolute".}
proc get_set_fields*(desc: PFontDescription): TFontMask{.cdecl,
    dynlib: lib, importc: "pango_font_description_get_set_fields".}
proc unset_fields*(desc: PFontDescription, to_unset: TFontMask){.
    cdecl, dynlib: lib, importc: "pango_font_description_unset_fields".}
proc merge*(desc: PFontDescription,
                             desc_to_merge: PFontDescription,
                             replace_existing: gboolean){.cdecl, dynlib: lib,
    importc: "pango_font_description_merge".}
proc merge_static*(desc: PFontDescription,
                                    desc_to_merge: PFontDescription,
                                    replace_existing: gboolean){.cdecl,
    dynlib: lib, importc: "pango_font_description_merge_static".}
proc better_match*(desc: PFontDescription,
                                    old_match: PFontDescription,
                                    new_match: PFontDescription): gboolean{.
    cdecl, dynlib: lib, importc: "pango_font_description_better_match".}
proc font_description_from_string*(str: cstring): PFontDescription{.cdecl,
    dynlib: lib, importc: "pango_font_description_from_string".}
proc to_string*(desc: PFontDescription): cstring{.cdecl,
    dynlib: lib, importc: "pango_font_description_to_string".}
proc to_filename*(desc: PFontDescription): cstring{.cdecl,
    dynlib: lib, importc: "pango_font_description_to_filename".}
proc TYPE_FONT_METRICS*(): GType
proc font_metrics_get_type*(): GType{.cdecl, dynlib: lib,
                                      importc: "pango_font_metrics_get_type".}
proc reference*(metrics: PFontMetrics): PFontMetrics{.cdecl, dynlib: lib,
    importc: "pango_font_metrics_ref".}
proc unref*(metrics: PFontMetrics){.cdecl, dynlib: lib,
    importc: "pango_font_metrics_unref".}
proc get_ascent*(metrics: PFontMetrics): int32{.cdecl, dynlib: lib,
    importc: "pango_font_metrics_get_ascent".}
proc get_descent*(metrics: PFontMetrics): int32{.cdecl,
    dynlib: lib, importc: "pango_font_metrics_get_descent".}
proc get_approximate_char_width*(metrics: PFontMetrics): int32{.
    cdecl, dynlib: lib, importc: "pango_font_metrics_get_approximate_char_width".}
proc get_approximate_digit_width*(metrics: PFontMetrics): int32{.
    cdecl, dynlib: lib,
    importc: "pango_font_metrics_get_approximate_digit_width".}
proc TYPE_FONT_FAMILY*(): GType
proc FONT_FAMILY*(anObject: Pointer): PFontFamily
proc IS_FONT_FAMILY*(anObject: Pointer): bool
proc font_family_get_type*(): GType{.cdecl, dynlib: lib,
                                     importc: "pango_font_family_get_type".}
proc list_faces*(family: PFontFamily,
                             faces: var openarray[ptr PFontFace]){.cdecl,
    dynlib: lib, importc: "pango_font_family_list_faces".}
proc get_name*(family: PFontFamily): cstring{.cdecl, dynlib: lib,
    importc: "pango_font_family_get_name".}
proc TYPE_FONT_FACE*(): GType
proc FONT_FACE*(anObject: pointer): PFontFace
proc IS_FONT_FACE*(anObject: pointer): bool
proc font_face_get_type*(): GType{.cdecl, dynlib: lib,
                                   importc: "pango_font_face_get_type".}
proc describe*(face: PFontFace): PFontDescription{.cdecl, dynlib: lib,
    importc: "pango_font_face_describe".}
proc get_face_name*(face: PFontFace): cstring{.cdecl, dynlib: lib,
    importc: "pango_font_face_get_face_name".}
proc TYPE_FONT*(): GType
proc FONT*(anObject: pointer): PFont
proc IS_FONT*(anObject: pointer): bool
proc font_get_type*(): GType{.cdecl, dynlib: lib, importc: "pango_font_get_type".}
proc describe*(font: PFont): PFontDescription{.cdecl, dynlib: lib,
    importc: "pango_font_describe".}
proc get_coverage*(font: PFont, language: PLanguage): PCoverage{.cdecl,
    dynlib: lib, importc: "pango_font_get_coverage".}
proc find_shaper*(font: PFont, language: PLanguage, ch: guint32): PEngineShape{.
    cdecl, dynlib: lib, importc: "pango_font_find_shaper".}
proc get_metrics*(font: PFont, language: PLanguage): PFontMetrics{.cdecl,
    dynlib: lib, importc: "pango_font_get_metrics".}
proc get_glyph_extents*(font: PFont, glyph: TGlyph, ink_rect: PRectangle,
                             logical_rect: PRectangle){.cdecl, dynlib: lib,
    importc: "pango_font_get_glyph_extents".}
proc TYPE_FONT_MAP*(): GType
proc FONT_MAP*(anObject: pointer): PFontMap
proc IS_FONT_MAP*(anObject: pointer): bool
proc font_map_get_type*(): GType{.cdecl, dynlib: lib,
                                  importc: "pango_font_map_get_type".}
proc load_font*(fontmap: PFontMap, context: PContext,
                         desc: PFontDescription): PFont{.cdecl, dynlib: lib,
    importc: "pango_font_map_load_font".}
proc load_fontset*(fontmap: PFontMap, context: PContext,
                            desc: PFontDescription, language: PLanguage): PFontset{.
    cdecl, dynlib: lib, importc: "pango_font_map_load_fontset".}
proc list_families*(fontmap: PFontMap,
                             families: var openarray[ptr PFontFamily]){.cdecl,
    dynlib: lib, importc: "pango_font_map_list_families".}
const
  bm_TPangoGlyphVisAttr_is_cluster_start* = 0x0001'i16
  bp_TPangoGlyphVisAttr_is_cluster_start* = 0'i16

proc is_cluster_start*(a: PGlyphVisAttr): guint
proc set_is_cluster_start*(a: PGlyphVisAttr, `is_cluster_start`: guint)
proc TYPE_GLYPH_STRING*(): GType
proc glyph_string_new*(): PGlyphString{.cdecl, dynlib: lib,
                                        importc: "pango_glyph_string_new".}
proc glyph_string_set_size*(`string`: PGlyphString, new_len: gint){.cdecl,
    dynlib: lib, importc: "pango_glyph_string_set_size".}
proc glyph_string_get_type*(): GType{.cdecl, dynlib: lib,
                                      importc: "pango_glyph_string_get_type".}
proc glyph_string_copy*(`string`: PGlyphString): PGlyphString{.cdecl,
    dynlib: lib, importc: "pango_glyph_string_copy".}
proc glyph_string_free*(`string`: PGlyphString){.cdecl, dynlib: lib,
    importc: "pango_glyph_string_free".}
proc extents*(glyphs: PGlyphString, font: PFont,
                           ink_rect: PRectangle, logical_rect: PRectangle){.
    cdecl, dynlib: lib, importc: "pango_glyph_string_extents".}
proc extents_range*(glyphs: PGlyphString, start: int32,
                                 theEnd: int32, font: PFont,
                                 ink_rect: PRectangle, logical_rect: PRectangle){.
    cdecl, dynlib: lib, importc: "pango_glyph_string_extents_range".}
proc get_logical_widths*(glyphs: PGlyphString, text: cstring,
                                      length: int32, embedding_level: int32,
                                      logical_widths: var int32){.cdecl,
    dynlib: lib, importc: "pango_glyph_string_get_logical_widths".}
proc index_to_x*(glyphs: PGlyphString, text: cstring,
                              length: int32, analysis: PAnalysis, index: int32,
                              trailing: gboolean, x_pos: var int32){.cdecl,
    dynlib: lib, importc: "pango_glyph_string_index_to_x".}
proc x_to_index*(glyphs: PGlyphString, text: cstring,
                              length: int32, analysis: PAnalysis, x_pos: int32,
                              index, trailing: var int32){.cdecl, dynlib: lib,
    importc: "pango_glyph_string_x_to_index".}
proc shape*(text: cstring, length: gint, analysis: PAnalysis,
            glyphs: PGlyphString){.cdecl, dynlib: lib, importc: "pango_shape".}
proc reorder_items*(logical_items: PGList): PGList{.cdecl, dynlib: lib,
    importc: "pango_reorder_items".}
proc item_new*(): PItem{.cdecl, dynlib: lib, importc: "pango_item_new".}
proc copy*(item: PItem): PItem{.cdecl, dynlib: lib,
                                     importc: "pango_item_copy".}
proc free*(item: PItem){.cdecl, dynlib: lib, importc: "pango_item_free".}
proc split*(orig: PItem, split_index: int32, split_offset: int32): PItem{.
    cdecl, dynlib: lib, importc: "pango_item_split".}
proc TYPE_LAYOUT*(): GType
proc LAYOUT*(anObject: pointer): PLayout
proc LAYOUT_CLASS*(klass: pointer): PLayoutClass
proc IS_LAYOUT*(anObject: pointer): bool
proc IS_LAYOUT_CLASS*(klass: pointer): bool
proc GET_CLASS*(obj: PLayout): PLayoutClass
proc layout_get_type*(): GType{.cdecl, dynlib: lib,
                                importc: "pango_layout_get_type".}
proc layout_new*(context: PContext): PLayout{.cdecl, dynlib: lib,
    importc: "pango_layout_new".}
proc copy*(src: PLayout): PLayout{.cdecl, dynlib: lib,
    importc: "pango_layout_copy".}
proc get_context*(layout: PLayout): PContext{.cdecl, dynlib: lib,
    importc: "pango_layout_get_context".}
proc set_attributes*(layout: PLayout, attrs: PAttrList){.cdecl,
    dynlib: lib, importc: "pango_layout_set_attributes".}
proc get_attributes*(layout: PLayout): PAttrList{.cdecl, dynlib: lib,
    importc: "pango_layout_get_attributes".}
proc set_text*(layout: PLayout, text: cstring, length: int32){.cdecl,
    dynlib: lib, importc: "pango_layout_set_text".}
proc get_text*(layout: PLayout): cstring{.cdecl, dynlib: lib,
    importc: "pango_layout_get_text".}
proc set_markup*(layout: PLayout, markup: cstring, length: int32){.cdecl,
    dynlib: lib, importc: "pango_layout_set_markup".}
proc set_markup*(layout: PLayout, markup: cstring,
                                   length: int32, accel_marker: gunichar,
                                   accel_char: Pgunichar){.cdecl, dynlib: lib,
    importc: "pango_layout_set_markup_with_accel".}
proc set_font_description*(layout: PLayout, desc: PFontDescription){.
    cdecl, dynlib: lib, importc: "pango_layout_set_font_description".}
proc set_width*(layout: PLayout, width: int32){.cdecl, dynlib: lib,
    importc: "pango_layout_set_width".}
proc get_width*(layout: PLayout): int32{.cdecl, dynlib: lib,
    importc: "pango_layout_get_width".}
proc set_wrap*(layout: PLayout, wrap: TWrapMode){.cdecl, dynlib: lib,
    importc: "pango_layout_set_wrap".}
proc get_wrap*(layout: PLayout): TWrapMode{.cdecl, dynlib: lib,
    importc: "pango_layout_get_wrap".}
proc set_indent*(layout: PLayout, indent: int32){.cdecl, dynlib: lib,
    importc: "pango_layout_set_indent".}
proc get_indent*(layout: PLayout): int32{.cdecl, dynlib: lib,
    importc: "pango_layout_get_indent".}
proc set_spacing*(layout: PLayout, spacing: int32){.cdecl, dynlib: lib,
    importc: "pango_layout_set_spacing".}
proc get_spacing*(layout: PLayout): int32{.cdecl, dynlib: lib,
    importc: "pango_layout_get_spacing".}
proc set_justify*(layout: PLayout, justify: gboolean){.cdecl,
    dynlib: lib, importc: "pango_layout_set_justify".}
proc get_justify*(layout: PLayout): gboolean{.cdecl, dynlib: lib,
    importc: "pango_layout_get_justify".}
proc set_alignment*(layout: PLayout, alignment: TAlignment){.cdecl,
    dynlib: lib, importc: "pango_layout_set_alignment".}
proc get_alignment*(layout: PLayout): TAlignment{.cdecl, dynlib: lib,
    importc: "pango_layout_get_alignment".}
proc set_tabs*(layout: PLayout, tabs: PTabArray){.cdecl, dynlib: lib,
    importc: "pango_layout_set_tabs".}
proc get_tabs*(layout: PLayout): PTabArray{.cdecl, dynlib: lib,
    importc: "pango_layout_get_tabs".}
proc set_single_paragraph_mode*(layout: PLayout, setting: gboolean){.
    cdecl, dynlib: lib, importc: "pango_layout_set_single_paragraph_mode".}
proc get_single_paragraph_mode*(layout: PLayout): gboolean{.cdecl,
    dynlib: lib, importc: "pango_layout_get_single_paragraph_mode".}
proc context_changed*(layout: PLayout){.cdecl, dynlib: lib,
    importc: "pango_layout_context_changed".}
proc get_log_attrs*(layout: PLayout, attrs: var PLogAttr, n_attrs: Pgint){.
    cdecl, dynlib: lib, importc: "pango_layout_get_log_attrs".}
proc index_to_pos*(layout: PLayout, index: int32, pos: PRectangle){.
    cdecl, dynlib: lib, importc: "pango_layout_index_to_pos".}
proc get_cursor_pos*(layout: PLayout, index: int32,
                            strong_pos: PRectangle, weak_pos: PRectangle){.
    cdecl, dynlib: lib, importc: "pango_layout_get_cursor_pos".}
proc move_cursor_visually*(layout: PLayout, strong: gboolean,
                                  old_index: int32, old_trailing: int32,
                                  direction: int32,
                                  new_index, new_trailing: var int32){.cdecl,
    dynlib: lib, importc: "pango_layout_move_cursor_visually".}
proc xy_to_index*(layout: PLayout, x: int32, y: int32,
                         index, trailing: var int32): gboolean{.cdecl,
    dynlib: lib, importc: "pango_layout_xy_to_index".}
proc get_extents*(layout: PLayout, ink_rect: PRectangle,
                         logical_rect: PRectangle){.cdecl, dynlib: lib,
    importc: "pango_layout_get_extents".}
proc get_pixel_extents*(layout: PLayout, ink_rect: PRectangle,
                               logical_rect: PRectangle){.cdecl, dynlib: lib,
    importc: "pango_layout_get_pixel_extents".}
proc get_size*(layout: PLayout, width: var int32, height: var int32){.
    cdecl, dynlib: lib, importc: "pango_layout_get_size".}
proc get_pixel_size*(layout: PLayout, width: var int32, height: var int32){.
    cdecl, dynlib: lib, importc: "pango_layout_get_pixel_size".}
proc get_line_count*(layout: PLayout): int32{.cdecl, dynlib: lib,
    importc: "pango_layout_get_line_count".}
proc get_line*(layout: PLayout, line: int32): PLayoutLine{.cdecl,
    dynlib: lib, importc: "pango_layout_get_line".}
proc get_lines*(layout: PLayout): PGSList{.cdecl, dynlib: lib,
    importc: "pango_layout_get_lines".}
proc reference*(line: PLayoutLine){.cdecl, dynlib: lib,
    importc: "pango_layout_line_ref".}
proc unref*(line: PLayoutLine){.cdecl, dynlib: lib,
    importc: "pango_layout_line_unref".}
proc x_to_index*(line: PLayoutLine, x_pos: int32, index: var int32,
                             trailing: var int32): gboolean{.cdecl, dynlib: lib,
    importc: "pango_layout_line_x_to_index".}
proc index_to_x*(line: PLayoutLine, index: int32,
                             trailing: gboolean, x_pos: var int32){.cdecl,
    dynlib: lib, importc: "pango_layout_line_index_to_x".}
proc get_extents*(line: PLayoutLine, ink_rect: PRectangle,
                              logical_rect: PRectangle){.cdecl, dynlib: lib,
    importc: "pango_layout_line_get_extents".}
proc get_pixel_extents*(layout_line: PLayoutLine,
                                    ink_rect: PRectangle,
                                    logical_rect: PRectangle){.cdecl,
    dynlib: lib, importc: "pango_layout_line_get_pixel_extents".}
proc get_iter*(layout: PLayout): PLayoutIter{.cdecl, dynlib: lib,
    importc: "pango_layout_get_iter".}
proc free*(iter: PLayoutIter){.cdecl, dynlib: lib,
    importc: "pango_layout_iter_free".}
proc get_index*(iter: PLayoutIter): int32{.cdecl, dynlib: lib,
    importc: "pango_layout_iter_get_index".}
proc get_run*(iter: PLayoutIter): PLayoutRun{.cdecl, dynlib: lib,
    importc: "pango_layout_iter_get_run".}
proc get_line*(iter: PLayoutIter): PLayoutLine{.cdecl, dynlib: lib,
    importc: "pango_layout_iter_get_line".}
proc at_last_line*(iter: PLayoutIter): gboolean{.cdecl, dynlib: lib,
    importc: "pango_layout_iter_at_last_line".}
proc next_char*(iter: PLayoutIter): gboolean{.cdecl, dynlib: lib,
    importc: "pango_layout_iter_next_char".}
proc next_cluster*(iter: PLayoutIter): gboolean{.cdecl, dynlib: lib,
    importc: "pango_layout_iter_next_cluster".}
proc next_run*(iter: PLayoutIter): gboolean{.cdecl, dynlib: lib,
    importc: "pango_layout_iter_next_run".}
proc next_line*(iter: PLayoutIter): gboolean{.cdecl, dynlib: lib,
    importc: "pango_layout_iter_next_line".}
proc get_char_extents*(iter: PLayoutIter, logical_rect: PRectangle){.
    cdecl, dynlib: lib, importc: "pango_layout_iter_get_char_extents".}
proc get_cluster_extents*(iter: PLayoutIter, ink_rect: PRectangle,
                                      logical_rect: PRectangle){.cdecl,
    dynlib: lib, importc: "pango_layout_iter_get_cluster_extents".}
proc get_run_extents*(iter: PLayoutIter, ink_rect: PRectangle,
                                  logical_rect: PRectangle){.cdecl, dynlib: lib,
    importc: "pango_layout_iter_get_run_extents".}
proc get_line_extents*(iter: PLayoutIter, ink_rect: PRectangle,
                                   logical_rect: PRectangle){.cdecl,
    dynlib: lib, importc: "pango_layout_iter_get_line_extents".}
proc get_line_yrange*(iter: PLayoutIter, y0: var int32,
                                  y1: var int32){.cdecl, dynlib: lib,
    importc: "pango_layout_iter_get_line_yrange".}
proc get_layout_extents*(iter: PLayoutIter, ink_rect: PRectangle,
                                     logical_rect: PRectangle){.cdecl,
    dynlib: lib, importc: "pango_layout_iter_get_layout_extents".}
proc get_baseline*(iter: PLayoutIter): int32{.cdecl, dynlib: lib,
    importc: "pango_layout_iter_get_baseline".}
proc TYPE_TAB_ARRAY*(): GType
proc tab_array_new*(initial_size: gint, positions_in_pixels: gboolean): PTabArray{.
    cdecl, dynlib: lib, importc: "pango_tab_array_new".}
proc tab_array_get_type*(): GType{.cdecl, dynlib: lib,
                                   importc: "pango_tab_array_get_type".}
proc copy*(src: PTabArray): PTabArray{.cdecl, dynlib: lib,
    importc: "pango_tab_array_copy".}
proc free*(tab_array: PTabArray){.cdecl, dynlib: lib,
    importc: "pango_tab_array_free".}
proc get_size*(tab_array: PTabArray): gint{.cdecl, dynlib: lib,
    importc: "pango_tab_array_get_size".}
proc resize*(tab_array: PTabArray, new_size: gint){.cdecl,
    dynlib: lib, importc: "pango_tab_array_resize".}
proc set_tab*(tab_array: PTabArray, tab_index: gint,
                        alignment: TTabAlign, location: gint){.cdecl,
    dynlib: lib, importc: "pango_tab_array_set_tab".}
proc get_tab*(tab_array: PTabArray, tab_index: gint,
                        alignment: PTabAlign, location: Pgint){.cdecl,
    dynlib: lib, importc: "pango_tab_array_get_tab".}
proc get_positions_in_pixels*(tab_array: PTabArray): gboolean{.cdecl,
    dynlib: lib, importc: "pango_tab_array_get_positions_in_pixels".}
proc ASCENT*(rect: TRectangle): int32 =
  result = -rect.y

proc DESCENT*(rect: TRectangle): int32 =
  result = (rect.y) + (rect.height)

proc LBEARING*(rect: TRectangle): int32 =
  result = rect.x

proc RBEARING*(rect: TRectangle): int32 =
  result = (rect.x) + (rect.width)

proc TYPE_LANGUAGE*(): GType =
  result = language_get_type()

proc to_string*(language: PLanguage): cstring =
  result = cast[cstring](language)

proc PIXELS*(d: int): int =
  if d >= 0:
    result = (d + (SCALE div 2)) div SCALE
  else:
    result = (d - (SCALE div 2)) div SCALE

proc TYPE_COLOR*(): GType =
  result = color_get_type()

proc TYPE_ATTR_LIST*(): GType =
  result = attr_list_get_type()

proc is_line_break*(a: PLogAttr): guint =
  result = (a.flag0 and bm_TPangoLogAttr_is_line_break) shr
      bp_TPangoLogAttr_is_line_break

proc set_is_line_break*(a: PLogAttr, `is_line_break`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_line_break` shl bp_TPangoLogAttr_is_line_break) and
      bm_TPangoLogAttr_is_line_break)

proc is_mandatory_break*(a: PLogAttr): guint =
  result = (a.flag0 and bm_TPangoLogAttr_is_mandatory_break) shr
      bp_TPangoLogAttr_is_mandatory_break

proc set_is_mandatory_break*(a: PLogAttr, `is_mandatory_break`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_mandatory_break` shl bp_TPangoLogAttr_is_mandatory_break) and
      bm_TPangoLogAttr_is_mandatory_break)

proc is_char_break*(a: PLogAttr): guint =
  result = (a.flag0 and bm_TPangoLogAttr_is_char_break) shr
      bp_TPangoLogAttr_is_char_break

proc set_is_char_break*(a: PLogAttr, `is_char_break`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_char_break` shl bp_TPangoLogAttr_is_char_break) and
      bm_TPangoLogAttr_is_char_break)

proc is_white*(a: PLogAttr): guint =
  result = (a.flag0 and bm_TPangoLogAttr_is_white) shr
      bp_TPangoLogAttr_is_white

proc set_is_white*(a: PLogAttr, `is_white`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_white` shl bp_TPangoLogAttr_is_white) and
      bm_TPangoLogAttr_is_white)

proc is_cursor_position*(a: PLogAttr): guint =
  result = (a.flag0 and bm_TPangoLogAttr_is_cursor_position) shr
      bp_TPangoLogAttr_is_cursor_position

proc set_is_cursor_position*(a: PLogAttr, `is_cursor_position`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_cursor_position` shl bp_TPangoLogAttr_is_cursor_position) and
      bm_TPangoLogAttr_is_cursor_position)

proc is_word_start*(a: PLogAttr): guint =
  result = (a.flag0 and bm_TPangoLogAttr_is_word_start) shr
      bp_TPangoLogAttr_is_word_start

proc set_is_word_start*(a: PLogAttr, `is_word_start`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_word_start` shl bp_TPangoLogAttr_is_word_start) and
      bm_TPangoLogAttr_is_word_start)

proc is_word_end*(a: PLogAttr): guint =
  result = (a.flag0 and bm_TPangoLogAttr_is_word_end) shr
      bp_TPangoLogAttr_is_word_end

proc set_is_word_end*(a: PLogAttr, `is_word_end`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_word_end` shl bp_TPangoLogAttr_is_word_end) and
      bm_TPangoLogAttr_is_word_end)

proc is_sentence_boundary*(a: PLogAttr): guint =
  result = (a.flag0 and bm_TPangoLogAttr_is_sentence_boundary) shr
      bp_TPangoLogAttr_is_sentence_boundary

proc set_is_sentence_boundary*(a: PLogAttr, `is_sentence_boundary`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_sentence_boundary` shl bp_TPangoLogAttr_is_sentence_boundary) and
      bm_TPangoLogAttr_is_sentence_boundary)

proc is_sentence_start*(a: PLogAttr): guint =
  result = (a.flag0 and bm_TPangoLogAttr_is_sentence_start) shr
      bp_TPangoLogAttr_is_sentence_start

proc set_is_sentence_start*(a: PLogAttr, `is_sentence_start`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_sentence_start` shl bp_TPangoLogAttr_is_sentence_start) and
      bm_TPangoLogAttr_is_sentence_start)

proc is_sentence_end*(a: PLogAttr): guint =
  result = (a.flag0 and bm_TPangoLogAttr_is_sentence_end) shr
      bp_TPangoLogAttr_is_sentence_end

proc set_is_sentence_end*(a: PLogAttr, `is_sentence_end`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_sentence_end` shl bp_TPangoLogAttr_is_sentence_end) and
      bm_TPangoLogAttr_is_sentence_end)

proc TYPE_CONTEXT*(): GType =
  result = context_get_type()

proc CONTEXT*(anObject: pointer): PContext =
  result = cast[PContext](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_CONTEXT()))

proc CONTEXT_CLASS*(klass: pointer): PContextClass =
  result = cast[PContextClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_CONTEXT()))

proc IS_CONTEXT*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_CONTEXT())

proc IS_CONTEXT_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_CONTEXT())

proc GET_CLASS*(obj: PContext): PContextClass =
  result = cast[PContextClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_CONTEXT()))

proc TYPE_FONTSET*(): GType =
  result = fontset_get_type()

proc FONTSET*(anObject: pointer): PFontset =
  result = cast[PFontset](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_FONTSET()))

proc IS_FONTSET*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_FONTSET())

proc FONTSET_CLASS*(klass: pointer): PFontsetClass =
  result = cast[PFontsetClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_FONTSET()))

proc IS_FONTSET_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_FONTSET())

proc GET_CLASS*(obj: PFontset): PFontsetClass =
  result = cast[PFontsetClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_FONTSET()))

proc fontset_simple_get_type(): GType{.importc: "pango_fontset_simple_get_type",
                                       cdecl, dynlib: lib.}
proc TYPE_FONTSET_SIMPLE*(): GType =
  result = fontset_simple_get_type()

proc FONTSET_SIMPLE*(anObject: pointer): PFontsetSimple =
  result = cast[PFontsetSimple](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      TYPE_FONTSET_SIMPLE()))

proc IS_FONTSET_SIMPLE*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_FONTSET_SIMPLE())

proc TYPE_FONT_DESCRIPTION*(): GType =
  result = font_description_get_type()

proc TYPE_FONT_METRICS*(): GType =
  result = font_metrics_get_type()

proc TYPE_FONT_FAMILY*(): GType =
  result = font_family_get_type()

proc FONT_FAMILY*(anObject: pointer): PFontFamily =
  result = cast[PFontFamily](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      TYPE_FONT_FAMILY()))

proc IS_FONT_FAMILY*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_FONT_FAMILY())

proc FONT_FAMILY_CLASS*(klass: Pointer): PFontFamilyClass =
  result = cast[PFontFamilyClass](G_TYPE_CHECK_CLASS_CAST(klass,
      TYPE_FONT_FAMILY()))

proc IS_FONT_FAMILY_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_FONT_FAMILY())

proc GET_CLASS*(obj: PFontFamily): PFontFamilyClass =
  result = cast[PFontFamilyClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      TYPE_FONT_FAMILY()))

proc TYPE_FONT_FACE*(): GType =
  result = font_face_get_type()

proc FONT_FACE*(anObject: Pointer): PFontFace =
  result = cast[PFontFace](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_FONT_FACE()))

proc IS_FONT_FACE*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_FONT_FACE())

proc FONT_FACE_CLASS*(klass: Pointer): PFontFaceClass =
  result = cast[PFontFaceClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_FONT_FACE()))

proc IS_FONT_FACE_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_FONT_FACE())

proc FONT_FACE_GET_CLASS*(obj: Pointer): PFontFaceClass =
  result = cast[PFontFaceClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_FONT_FACE()))

proc TYPE_FONT*(): GType =
  result = font_get_type()

proc FONT*(anObject: Pointer): PFont =
  result = cast[PFont](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_FONT()))

proc IS_FONT*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_FONT())

proc FONT_CLASS*(klass: Pointer): PFontClass =
  result = cast[PFontClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_FONT()))

proc IS_FONT_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_FONT())

proc GET_CLASS*(obj: PFont): PFontClass =
  result = cast[PFontClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_FONT()))

proc TYPE_FONT_MAP*(): GType =
  result = font_map_get_type()

proc FONT_MAP*(anObject: pointer): PFontmap =
  result = cast[PFontmap](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_FONT_MAP()))

proc IS_FONT_MAP*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_FONT_MAP())

proc FONT_MAP_CLASS*(klass: pointer): PFontMapClass =
  result = cast[PFontMapClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_FONT_MAP()))

proc IS_FONT_MAP_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_FONT_MAP())

proc GET_CLASS*(obj: PFontMap): PFontMapClass =
  result = cast[PFontMapClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_FONT_MAP()))

proc is_cluster_start*(a: PGlyphVisAttr): guint =
  result = (a.flag0 and bm_TPangoGlyphVisAttr_is_cluster_start) shr
      bp_TPangoGlyphVisAttr_is_cluster_start

proc set_is_cluster_start*(a: PGlyphVisAttr, `is_cluster_start`: guint) =
  a.flag0 = a.flag0 or
      (int16(`is_cluster_start` shl bp_TPangoGlyphVisAttr_is_cluster_start) and
      bm_TPangoGlyphVisAttr_is_cluster_start)

proc TYPE_GLYPH_STRING*(): GType =
  result = glyph_string_get_type()

proc TYPE_LAYOUT*(): GType =
  result = layout_get_type()

proc LAYOUT*(anObject: pointer): PLayout =
  result = cast[PLayout](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_LAYOUT()))

proc LAYOUT_CLASS*(klass: pointer): PLayoutClass =
  result = cast[PLayoutClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_LAYOUT()))

proc IS_LAYOUT*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_LAYOUT())

proc IS_LAYOUT_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_LAYOUT())

proc GET_CLASS*(obj: PLayout): PLayoutClass =
  result = cast[PLayoutClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_LAYOUT()))

proc TYPE_TAB_ARRAY*(): GType =
  result = tab_array_get_type()
