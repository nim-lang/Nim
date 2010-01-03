{.deadCodeElim: on.}
import 
  glib2

when defined(win32): 
  const 
    pangolib* = "libpango-1.0-0.dll"
else: 
  const 
    pangolib* = "libpango-1.0.so.0"
type 
  PFont* = pointer
  PFontFamily* = pointer
  PFontset* = pointer
  PFontMetrics* = pointer
  PFontFace* = pointer
  PFontMap* = pointer
  PFontsetClass* = pointer
  PFontFamilyClass* = pointer
  PFontFaceClass* = pointer
  PFontClass* = pointer
  PFontMapClass* = pointer
  PFontDescription* = ptr TFontDescription
  TFontDescription* = pointer
  PAttrList* = ptr TAttrList
  TAttrList* = pointer
  PAttrIterator* = ptr TAttrIterator
  TAttrIterator* = pointer
  PLayout* = ptr TLayout
  TLayout* = pointer
  PLayoutClass* = ptr TLayoutClass
  TLayoutClass* = pointer
  PLayoutIter* = ptr TLayoutIter
  TLayoutIter* = pointer
  PContext* = ptr TContext
  TContext* = pointer
  PContextClass* = ptr TContextClass
  TContextClass* = pointer
  PFontsetSimple* = ptr TFontsetSimple
  TFontsetSimple* = pointer
  PTabArray* = ptr TTabArray
  TTabArray* = pointer
  PGlyphString* = ptr TGlyphString
  PAnalysis* = ptr TAnalysis
  PItem* = ptr TItem
  PLanguage* = ptr TLanguage
  TLanguage* = pointer
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
    PANGO_DIRECTION_LTR, PANGO_DIRECTION_RTL, PANGO_DIRECTION_TTB_LTR, 
    PANGO_DIRECTION_TTB_RTL
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
    PANGO_COVERAGE_NONE, PANGO_COVERAGE_FALLBACK, PANGO_COVERAGE_APPROXIMATE, 
    PANGO_COVERAGE_EXACT
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
    PANGO_ALIGN_LEFT, PANGO_ALIGN_CENTER, PANGO_ALIGN_RIGHT
  PWrapMode* = ptr TWrapMode
  TWrapMode* = enum 
    PANGO_WRAP_WORD, PANGO_WRAP_CHAR
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
    PANGO_TAB_LEFT

const 
  PANGO_SCALE* = 1024

proc PANGO_PIXELS*(d: int): int
proc PANGO_ASCENT*(rect: TRectangle): int32
proc PANGO_DESCENT*(rect: TRectangle): int32
proc PANGO_LBEARING*(rect: TRectangle): int32
proc PANGO_RBEARING*(rect: TRectangle): int32
proc PANGO_TYPE_LANGUAGE*(): GType
proc pango_language_get_type*(): GType{.cdecl, dynlib: pangolib, 
                                        importc: "pango_language_get_type".}
proc pango_language_from_string*(language: cstring): PLanguage{.cdecl, 
    dynlib: pangolib, importc: "pango_language_from_string".}
proc pango_language_to_string*(language: PLanguage): cstring
proc pango_language_matches*(language: PLanguage, range_list: cstring): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_language_matches".}
const 
  PANGO_ATTR_INVALID* = 0
  PANGO_ATTR_LANGUAGE* = 1
  PANGO_ATTR_FAMILY* = 2
  PANGO_ATTR_STYLE* = 3
  PANGO_ATTR_WEIGHT* = 4
  PANGO_ATTR_VARIANT* = 5
  PANGO_ATTR_STRETCH* = 6
  PANGO_ATTR_SIZE* = 7
  PANGO_ATTR_FONT_DESC* = 8
  PANGO_ATTR_FOREGROUND* = 9
  PANGO_ATTR_BACKGROUND* = 10
  PANGO_ATTR_UNDERLINE* = 11
  PANGO_ATTR_STRIKETHROUGH* = 12
  PANGO_ATTR_RISE* = 13
  PANGO_ATTR_SHAPE* = 14
  PANGO_ATTR_SCALE* = 15
  PANGO_UNDERLINE_NONE* = 0
  PANGO_UNDERLINE_SINGLE* = 1
  PANGO_UNDERLINE_DOUBLE* = 2
  PANGO_UNDERLINE_LOW* = 3

proc PANGO_TYPE_COLOR*(): GType
proc pango_color_get_type*(): GType{.cdecl, dynlib: pangolib, 
                                     importc: "pango_color_get_type".}
proc pango_color_copy*(src: PColor): PColor{.cdecl, dynlib: pangolib, 
    importc: "pango_color_copy".}
proc pango_color_free*(color: PColor){.cdecl, dynlib: pangolib, 
                                       importc: "pango_color_free".}
proc pango_color_parse*(color: PColor, spec: cstring): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_color_parse".}
proc PANGO_TYPE_ATTR_LIST*(): GType
proc pango_attr_type_register*(name: cstring): TAttrType{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_type_register".}
proc pango_attribute_copy*(attr: PAttribute): PAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attribute_copy".}
proc pango_attribute_destroy*(attr: PAttribute){.cdecl, dynlib: pangolib, 
    importc: "pango_attribute_destroy".}
proc pango_attribute_equal*(attr1: PAttribute, attr2: PAttribute): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_attribute_equal".}
proc pango_attr_language_new*(language: PLanguage): PAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_language_new".}
proc pango_attr_family_new*(family: cstring): PAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_family_new".}
proc pango_attr_foreground_new*(red: guint16, green: guint16, blue: guint16): PAttribute{.
    cdecl, dynlib: pangolib, importc: "pango_attr_foreground_new".}
proc pango_attr_background_new*(red: guint16, green: guint16, blue: guint16): PAttribute{.
    cdecl, dynlib: pangolib, importc: "pango_attr_background_new".}
proc pango_attr_size_new*(size: int32): PAttribute{.cdecl, dynlib: pangolib, 
    importc: "pango_attr_size_new".}
proc pango_attr_style_new*(style: TStyle): PAttribute{.cdecl, dynlib: pangolib, 
    importc: "pango_attr_style_new".}
proc pango_attr_weight_new*(weight: TWeight): PAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_weight_new".}
proc pango_attr_variant_new*(variant: TVariant): PAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_variant_new".}
proc pango_attr_stretch_new*(stretch: TStretch): PAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_stretch_new".}
proc pango_attr_font_desc_new*(desc: PFontDescription): PAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_font_desc_new".}
proc pango_attr_underline_new*(underline: TUnderline): PAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_underline_new".}
proc pango_attr_strikethrough_new*(strikethrough: gboolean): PAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_strikethrough_new".}
proc pango_attr_rise_new*(rise: int32): PAttribute{.cdecl, dynlib: pangolib, 
    importc: "pango_attr_rise_new".}
proc pango_attr_shape_new*(ink_rect: PRectangle, logical_rect: PRectangle): PAttribute{.
    cdecl, dynlib: pangolib, importc: "pango_attr_shape_new".}
proc pango_attr_scale_new*(scale_factor: gdouble): PAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_scale_new".}
proc pango_attr_list_get_type*(): GType{.cdecl, dynlib: pangolib, 
    importc: "pango_attr_list_get_type".}
proc pango_attr_list_new*(): PAttrList{.cdecl, dynlib: pangolib, 
                                        importc: "pango_attr_list_new".}
proc pango_attr_list_ref*(list: PAttrList){.cdecl, dynlib: pangolib, 
    importc: "pango_attr_list_ref".}
proc pango_attr_list_unref*(list: PAttrList){.cdecl, dynlib: pangolib, 
    importc: "pango_attr_list_unref".}
proc pango_attr_list_copy*(list: PAttrList): PAttrList{.cdecl, dynlib: pangolib, 
    importc: "pango_attr_list_copy".}
proc pango_attr_list_insert*(list: PAttrList, attr: PAttribute){.cdecl, 
    dynlib: pangolib, importc: "pango_attr_list_insert".}
proc pango_attr_list_insert_before*(list: PAttrList, attr: PAttribute){.cdecl, 
    dynlib: pangolib, importc: "pango_attr_list_insert_before".}
proc pango_attr_list_change*(list: PAttrList, attr: PAttribute){.cdecl, 
    dynlib: pangolib, importc: "pango_attr_list_change".}
proc pango_attr_list_splice*(list: PAttrList, other: PAttrList, pos: gint, 
                             len: gint){.cdecl, dynlib: pangolib, 
    importc: "pango_attr_list_splice".}
proc pango_attr_list_get_iterator*(list: PAttrList): PAttrIterator{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_list_get_iterator".}
proc pango_attr_iterator_range*(`iterator`: PAttrIterator, start: Pgint, 
                                theEnd: Pgint){.cdecl, dynlib: pangolib, 
    importc: "pango_attr_iterator_range".}
proc pango_attr_iterator_next*(`iterator`: PAttrIterator): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_iterator_next".}
proc pango_attr_iterator_copy*(`iterator`: PAttrIterator): PAttrIterator{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_iterator_copy".}
proc pango_attr_iterator_destroy*(`iterator`: PAttrIterator){.cdecl, 
    dynlib: pangolib, importc: "pango_attr_iterator_destroy".}
proc pango_attr_iterator_get*(`iterator`: PAttrIterator, `type`: TAttrType): PAttribute{.
    cdecl, dynlib: pangolib, importc: "pango_attr_iterator_get".}
proc pango_attr_iterator_get_font*(`iterator`: PAttrIterator, 
                                   desc: PFontDescription, 
                                   language: var PLanguage, 
                                   extra_attrs: PPGSList){.cdecl, 
    dynlib: pangolib, importc: "pango_attr_iterator_get_font".}
proc pango_parse_markup*(markup_text: cstring, length: int32, 
                         accel_marker: gunichar, attr_list: var PAttrList, 
                         text: PPchar, accel_char: Pgunichar, error: pointer): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_parse_markup".}
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

proc is_line_break*(a: var TLogAttr): guint
proc set_is_line_break*(a: var TLogAttr, `is_line_break`: guint)
proc is_mandatory_break*(a: var TLogAttr): guint
proc set_is_mandatory_break*(a: var TLogAttr, `is_mandatory_break`: guint)
proc is_char_break*(a: var TLogAttr): guint
proc set_is_char_break*(a: var TLogAttr, `is_char_break`: guint)
proc is_white*(a: var TLogAttr): guint
proc set_is_white*(a: var TLogAttr, `is_white`: guint)
proc is_cursor_position*(a: var TLogAttr): guint
proc set_is_cursor_position*(a: var TLogAttr, `is_cursor_position`: guint)
proc is_word_start*(a: var TLogAttr): guint
proc set_is_word_start*(a: var TLogAttr, `is_word_start`: guint)
proc is_word_end*(a: var TLogAttr): guint
proc set_is_word_end*(a: var TLogAttr, `is_word_end`: guint)
proc is_sentence_boundary*(a: var TLogAttr): guint
proc set_is_sentence_boundary*(a: var TLogAttr, `is_sentence_boundary`: guint)
proc is_sentence_start*(a: var TLogAttr): guint
proc set_is_sentence_start*(a: var TLogAttr, `is_sentence_start`: guint)
proc is_sentence_end*(a: var TLogAttr): guint
proc set_is_sentence_end*(a: var TLogAttr, `is_sentence_end`: guint)
proc pango_break*(text: cstring, length: int32, analysis: PAnalysis, 
                  attrs: PLogAttr, attrs_len: int32){.cdecl, dynlib: pangolib, 
    importc: "pango_break".}
proc pango_find_paragraph_boundary*(text: cstring, length: gint, 
                                    paragraph_delimiter_index: Pgint, 
                                    next_paragraph_start: Pgint){.cdecl, 
    dynlib: pangolib, importc: "pango_find_paragraph_boundary".}
proc pango_get_log_attrs*(text: cstring, length: int32, level: int32, 
                          language: PLanguage, log_attrs: PLogAttr, 
                          attrs_len: int32){.cdecl, dynlib: pangolib, 
    importc: "pango_get_log_attrs".}
proc PANGO_TYPE_CONTEXT*(): GType
proc PANGO_CONTEXT*(anObject: pointer): PContext
proc PANGO_CONTEXT_CLASS*(klass: pointer): PContextClass
proc PANGO_IS_CONTEXT*(anObject: pointer): bool
proc PANGO_IS_CONTEXT_CLASS*(klass: pointer): bool
proc PANGO_CONTEXT_GET_CLASS*(obj: PContext): PContextClass
proc pango_context_get_type*(): GType{.cdecl, dynlib: pangolib, 
                                       importc: "pango_context_get_type".}
proc pango_context_list_families*(context: PContext, 
                                  families: openarray[ptr PFontFamily]){.cdecl, 
    dynlib: pangolib, importc: "pango_context_list_families".}
proc pango_context_load_font*(context: PContext, desc: PFontDescription): PFont{.
    cdecl, dynlib: pangolib, importc: "pango_context_load_font".}
proc pango_context_load_fontset*(context: PContext, desc: PFontDescription, 
                                 language: PLanguage): PFontset{.cdecl, 
    dynlib: pangolib, importc: "pango_context_load_fontset".}
proc pango_context_get_metrics*(context: PContext, desc: PFontDescription, 
                                language: PLanguage): PFontMetrics{.cdecl, 
    dynlib: pangolib, importc: "pango_context_get_metrics".}
proc pango_context_set_font_description*(context: PContext, 
    desc: PFontDescription){.cdecl, dynlib: pangolib, 
                             importc: "pango_context_set_font_description".}
proc pango_context_get_font_description*(context: PContext): PFontDescription{.
    cdecl, dynlib: pangolib, importc: "pango_context_get_font_description".}
proc pango_context_get_language*(context: PContext): PLanguage{.cdecl, 
    dynlib: pangolib, importc: "pango_context_get_language".}
proc pango_context_set_language*(context: PContext, language: PLanguage){.cdecl, 
    dynlib: pangolib, importc: "pango_context_set_language".}
proc pango_context_set_base_dir*(context: PContext, direction: TDirection){.
    cdecl, dynlib: pangolib, importc: "pango_context_set_base_dir".}
proc pango_context_get_base_dir*(context: PContext): TDirection{.cdecl, 
    dynlib: pangolib, importc: "pango_context_get_base_dir".}
proc pango_itemize*(context: PContext, text: cstring, start_index: int32, 
                    length: int32, attrs: PAttrList, cached_iter: PAttrIterator): PGList{.
    cdecl, dynlib: pangolib, importc: "pango_itemize".}
proc pango_coverage_new*(): PCoverage{.cdecl, dynlib: pangolib, 
                                       importc: "pango_coverage_new".}
proc pango_coverage_ref*(coverage: PCoverage): PCoverage{.cdecl, 
    dynlib: pangolib, importc: "pango_coverage_ref".}
proc pango_coverage_unref*(coverage: PCoverage){.cdecl, dynlib: pangolib, 
    importc: "pango_coverage_unref".}
proc pango_coverage_copy*(coverage: PCoverage): PCoverage{.cdecl, 
    dynlib: pangolib, importc: "pango_coverage_copy".}
proc pango_coverage_get*(coverage: PCoverage, index: int32): TCoverageLevel{.
    cdecl, dynlib: pangolib, importc: "pango_coverage_get".}
proc pango_coverage_set*(coverage: PCoverage, index: int32, 
                         level: TCoverageLevel){.cdecl, dynlib: pangolib, 
    importc: "pango_coverage_set".}
proc pango_coverage_max*(coverage: PCoverage, other: PCoverage){.cdecl, 
    dynlib: pangolib, importc: "pango_coverage_max".}
proc pango_coverage_to_bytes*(coverage: PCoverage, bytes: PPguchar, 
                              n_bytes: var int32){.cdecl, dynlib: pangolib, 
    importc: "pango_coverage_to_bytes".}
proc pango_coverage_from_bytes*(bytes: Pguchar, n_bytes: int32): PCoverage{.
    cdecl, dynlib: pangolib, importc: "pango_coverage_from_bytes".}
proc PANGO_TYPE_FONTSET*(): GType
proc PANGO_FONTSET*(anObject: pointer): PFontset
proc PANGO_IS_FONTSET*(anObject: pointer): bool
proc pango_fontset_get_type*(): GType{.cdecl, dynlib: pangolib, 
                                       importc: "pango_fontset_get_type".}
proc pango_fontset_get_font*(fontset: PFontset, wc: guint): PFont{.cdecl, 
    dynlib: pangolib, importc: "pango_fontset_get_font".}
proc pango_fontset_get_metrics*(fontset: PFontset): PFontMetrics{.cdecl, 
    dynlib: pangolib, importc: "pango_fontset_get_metrics".}
const 
  PANGO_STYLE_NORMAL* = 0
  PANGO_STYLE_OBLIQUE* = 1
  PANGO_STYLE_ITALIC* = 2
  PANGO_VARIANT_NORMAL* = 0
  PANGO_VARIANT_SMALL_CAPS* = 1
  PANGO_WEIGHT_ULTRALIGHT* = 200
  PANGO_WEIGHT_LIGHT* = 300
  PANGO_WEIGHT_NORMAL* = 400
  PANGO_WEIGHT_BOLD* = 700
  PANGO_WEIGHT_ULTRABOLD* = 800
  PANGO_WEIGHT_HEAVY* = 900
  PANGO_STRETCH_ULTRA_CONDENSED* = 0
  PANGO_STRETCH_EXTRA_CONDENSED* = 1
  PANGO_STRETCH_CONDENSED* = 2
  PANGO_STRETCH_SEMI_CONDENSED* = 3
  PANGO_STRETCH_NORMAL* = 4
  PANGO_STRETCH_SEMI_EXPANDED* = 5
  PANGO_STRETCH_EXPANDED* = 6
  PANGO_STRETCH_EXTRA_EXPANDED* = 7
  PANGO_STRETCH_ULTRA_EXPANDED* = 8
  PANGO_FONT_MASK_FAMILY* = 1 shl 0
  PANGO_FONT_MASK_STYLE* = 1 shl 1
  PANGO_FONT_MASK_VARIANT* = 1 shl 2
  PANGO_FONT_MASK_WEIGHT* = 1 shl 3
  PANGO_FONT_MASK_STRETCH* = 1 shl 4
  PANGO_FONT_MASK_SIZE* = 1 shl 5
  PANGO_SCALE_XX_SMALL* = 0.578704
  PANGO_SCALE_X_SMALL* = 0.644444
  PANGO_SCALE_SMALL* = 0.833333
  PANGO_SCALE_MEDIUM* = 1.00000
  PANGO_SCALE_LARGE* = 1.20000
  PANGO_SCALE_X_LARGE* = 1.44000
  PANGO_SCALE_XX_LARGE* = 1.72800

proc PANGO_TYPE_FONT_DESCRIPTION*(): GType
proc pango_font_description_get_type*(): GType{.cdecl, dynlib: pangolib, 
    importc: "pango_font_description_get_type".}
proc pango_font_description_new*(): PFontDescription{.cdecl, dynlib: pangolib, 
    importc: "pango_font_description_new".}
proc pango_font_description_copy*(desc: PFontDescription): PFontDescription{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_copy".}
proc pango_font_description_copy_static*(desc: PFontDescription): PFontDescription{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_copy_static".}
proc pango_font_description_hash*(desc: PFontDescription): guint{.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_hash".}
proc pango_font_description_equal*(desc1: PFontDescription, 
                                   desc2: PFontDescription): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_equal".}
proc pango_font_description_free*(desc: PFontDescription){.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_free".}
proc pango_font_descriptions_free*(descs: var PFontDescription, n_descs: int32){.
    cdecl, dynlib: pangolib, importc: "pango_font_descriptions_free".}
proc pango_font_description_set_family*(desc: PFontDescription, family: cstring){.
    cdecl, dynlib: pangolib, importc: "pango_font_description_set_family".}
proc pango_font_description_set_family_static*(desc: PFontDescription, 
    family: cstring){.cdecl, dynlib: pangolib, 
                      importc: "pango_font_description_set_family_static".}
proc pango_font_description_get_family*(desc: PFontDescription): cstring{.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_get_family".}
proc pango_font_description_set_style*(desc: PFontDescription, style: TStyle){.
    cdecl, dynlib: pangolib, importc: "pango_font_description_set_style".}
proc pango_font_description_get_style*(desc: PFontDescription): TStyle{.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_get_style".}
proc pango_font_description_set_variant*(desc: PFontDescription, 
    variant: TVariant){.cdecl, dynlib: pangolib, 
                        importc: "pango_font_description_set_variant".}
proc pango_font_description_get_variant*(desc: PFontDescription): TVariant{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_get_variant".}
proc pango_font_description_set_weight*(desc: PFontDescription, weight: TWeight){.
    cdecl, dynlib: pangolib, importc: "pango_font_description_set_weight".}
proc pango_font_description_get_weight*(desc: PFontDescription): TWeight{.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_get_weight".}
proc pango_font_description_set_stretch*(desc: PFontDescription, 
    stretch: TStretch){.cdecl, dynlib: pangolib, 
                        importc: "pango_font_description_set_stretch".}
proc pango_font_description_get_stretch*(desc: PFontDescription): TStretch{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_get_stretch".}
proc pango_font_description_set_size*(desc: PFontDescription, size: gint){.
    cdecl, dynlib: pangolib, importc: "pango_font_description_set_size".}
proc pango_font_description_get_size*(desc: PFontDescription): gint{.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_get_size".}
proc pango_font_description_set_absolute_size*(desc: PFontDescription, 
    size: float64){.cdecl, dynlib: pangolib, 
                    importc: "pango_font_description_set_absolute_size".}
proc pango_font_description_get_size_is_absolute*(desc: PFontDescription, 
    size: float64): gboolean{.cdecl, dynlib: pangolib, importc: "pango_font_description_get_size_is_absolute".}
proc pango_font_description_get_set_fields*(desc: PFontDescription): TFontMask{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_get_set_fields".}
proc pango_font_description_unset_fields*(desc: PFontDescription, 
    to_unset: TFontMask){.cdecl, dynlib: pangolib, 
                          importc: "pango_font_description_unset_fields".}
proc pango_font_description_merge*(desc: PFontDescription, 
                                   desc_to_merge: PFontDescription, 
                                   replace_existing: gboolean){.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_merge".}
proc pango_font_description_merge_static*(desc: PFontDescription, 
    desc_to_merge: PFontDescription, replace_existing: gboolean){.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_merge_static".}
proc pango_font_description_better_match*(desc: PFontDescription, 
    old_match: PFontDescription, new_match: PFontDescription): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_better_match".}
proc pango_font_description_from_string*(str: cstring): PFontDescription{.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_from_string".}
proc pango_font_description_to_string*(desc: PFontDescription): cstring{.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_to_string".}
proc pango_font_description_to_filename*(desc: PFontDescription): cstring{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_to_filename".}
proc PANGO_TYPE_FONT_METRICS*(): GType
proc pango_font_metrics_get_type*(): GType{.cdecl, dynlib: pangolib, 
    importc: "pango_font_metrics_get_type".}
proc pango_font_metrics_ref*(metrics: PFontMetrics): PFontMetrics{.cdecl, 
    dynlib: pangolib, importc: "pango_font_metrics_ref".}
proc pango_font_metrics_unref*(metrics: PFontMetrics){.cdecl, dynlib: pangolib, 
    importc: "pango_font_metrics_unref".}
proc pango_font_metrics_get_ascent*(metrics: PFontMetrics): int32{.cdecl, 
    dynlib: pangolib, importc: "pango_font_metrics_get_ascent".}
proc pango_font_metrics_get_descent*(metrics: PFontMetrics): int32{.cdecl, 
    dynlib: pangolib, importc: "pango_font_metrics_get_descent".}
proc pango_font_metrics_get_approximate_char_width*(metrics: PFontMetrics): int32{.
    cdecl, dynlib: pangolib, 
    importc: "pango_font_metrics_get_approximate_char_width".}
proc pango_font_metrics_get_approximate_digit_width*(metrics: PFontMetrics): int32{.
    cdecl, dynlib: pangolib, 
    importc: "pango_font_metrics_get_approximate_digit_width".}
proc PANGO_TYPE_FONT_FAMILY*(): GType
proc PANGO_FONT_FAMILY*(anObject: Pointer): PFontFamily
proc PANGO_IS_FONT_FAMILY*(anObject: Pointer): bool
proc pango_font_family_get_type*(): GType{.cdecl, dynlib: pangolib, 
    importc: "pango_font_family_get_type".}
proc pango_font_family_list_faces*(family: PFontFamily, 
                                   faces: var openarray[ptr PFontFace]){.cdecl, 
    dynlib: pangolib, importc: "pango_font_family_list_faces".}
proc pango_font_family_get_name*(family: PFontFamily): cstring{.cdecl, 
    dynlib: pangolib, importc: "pango_font_family_get_name".}
proc PANGO_TYPE_FONT_FACE*(): GType
proc PANGO_FONT_FACE*(anObject: pointer): PFontFace
proc PANGO_IS_FONT_FACE*(anObject: pointer): bool
proc pango_font_face_get_type*(): GType{.cdecl, dynlib: pangolib, 
    importc: "pango_font_face_get_type".}
proc pango_font_face_describe*(face: PFontFace): PFontDescription{.cdecl, 
    dynlib: pangolib, importc: "pango_font_face_describe".}
proc pango_font_face_get_face_name*(face: PFontFace): cstring{.cdecl, 
    dynlib: pangolib, importc: "pango_font_face_get_face_name".}
proc PANGO_TYPE_FONT*(): GType
proc PANGO_FONT*(anObject: pointer): PFont
proc PANGO_IS_FONT*(anObject: pointer): bool
proc pango_font_get_type*(): GType{.cdecl, dynlib: pangolib, 
                                    importc: "pango_font_get_type".}
proc pango_font_describe*(font: PFont): PFontDescription{.cdecl, 
    dynlib: pangolib, importc: "pango_font_describe".}
proc pango_font_get_coverage*(font: PFont, language: PLanguage): PCoverage{.
    cdecl, dynlib: pangolib, importc: "pango_font_get_coverage".}
proc pango_font_find_shaper*(font: PFont, language: PLanguage, ch: guint32): PEngineShape{.
    cdecl, dynlib: pangolib, importc: "pango_font_find_shaper".}
proc pango_font_get_metrics*(font: PFont, language: PLanguage): PFontMetrics{.
    cdecl, dynlib: pangolib, importc: "pango_font_get_metrics".}
proc pango_font_get_glyph_extents*(font: PFont, glyph: TGlyph, 
                                   ink_rect: PRectangle, 
                                   logical_rect: PRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_font_get_glyph_extents".}
proc PANGO_TYPE_FONT_MAP*(): GType
proc PANGO_FONT_MAP*(anObject: pointer): PFontMap
proc PANGO_IS_FONT_MAP*(anObject: pointer): bool
proc pango_font_map_get_type*(): GType{.cdecl, dynlib: pangolib, 
                                        importc: "pango_font_map_get_type".}
proc pango_font_map_load_font*(fontmap: PFontMap, context: PContext, 
                               desc: PFontDescription): PFont{.cdecl, 
    dynlib: pangolib, importc: "pango_font_map_load_font".}
proc pango_font_map_load_fontset*(fontmap: PFontMap, context: PContext, 
                                  desc: PFontDescription, language: PLanguage): PFontset{.
    cdecl, dynlib: pangolib, importc: "pango_font_map_load_fontset".}
proc pango_font_map_list_families*(fontmap: PFontMap, 
                                   families: var openarray[ptr PFontFamily]){.
    cdecl, dynlib: pangolib, importc: "pango_font_map_list_families".}
const 
  bm_TPangoGlyphVisAttr_is_cluster_start* = 0x0001'i16
  bp_TPangoGlyphVisAttr_is_cluster_start* = 0'i16

proc is_cluster_start*(a: var TGlyphVisAttr): guint
proc set_is_cluster_start*(a: var TGlyphVisAttr, `is_cluster_start`: guint)
proc PANGO_TYPE_GLYPH_STRING*(): GType
proc pango_glyph_string_new*(): PGlyphString{.cdecl, dynlib: pangolib, 
    importc: "pango_glyph_string_new".}
proc pango_glyph_string_set_size*(`string`: PGlyphString, new_len: gint){.cdecl, 
    dynlib: pangolib, importc: "pango_glyph_string_set_size".}
proc pango_glyph_string_get_type*(): GType{.cdecl, dynlib: pangolib, 
    importc: "pango_glyph_string_get_type".}
proc pango_glyph_string_copy*(`string`: PGlyphString): PGlyphString{.cdecl, 
    dynlib: pangolib, importc: "pango_glyph_string_copy".}
proc pango_glyph_string_free*(`string`: PGlyphString){.cdecl, dynlib: pangolib, 
    importc: "pango_glyph_string_free".}
proc pango_glyph_string_extents*(glyphs: PGlyphString, font: PFont, 
                                 ink_rect: PRectangle, logical_rect: PRectangle){.
    cdecl, dynlib: pangolib, importc: "pango_glyph_string_extents".}
proc pango_glyph_string_extents_range*(glyphs: PGlyphString, start: int32, 
                                       theEnd: int32, font: PFont, 
                                       ink_rect: PRectangle, 
                                       logical_rect: PRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_glyph_string_extents_range".}
proc pango_glyph_string_get_logical_widths*(glyphs: PGlyphString, text: cstring, 
    length: int32, embedding_level: int32, logical_widths: var int32){.cdecl, 
    dynlib: pangolib, importc: "pango_glyph_string_get_logical_widths".}
proc pango_glyph_string_index_to_x*(glyphs: PGlyphString, text: cstring, 
                                    length: int32, analysis: PAnalysis, 
                                    index: int32, trailing: gboolean, 
                                    x_pos: var int32){.cdecl, dynlib: pangolib, 
    importc: "pango_glyph_string_index_to_x".}
proc pango_glyph_string_x_to_index*(glyphs: PGlyphString, text: cstring, 
                                    length: int32, analysis: PAnalysis, 
                                    x_pos: int32, index, trailing: var int32){.
    cdecl, dynlib: pangolib, importc: "pango_glyph_string_x_to_index".}
proc pango_shape*(text: cstring, length: gint, analysis: PAnalysis, 
                  glyphs: PGlyphString){.cdecl, dynlib: pangolib, 
    importc: "pango_shape".}
proc pango_reorder_items*(logical_items: PGList): PGList{.cdecl, 
    dynlib: pangolib, importc: "pango_reorder_items".}
proc pango_item_new*(): PItem{.cdecl, dynlib: pangolib, 
                               importc: "pango_item_new".}
proc pango_item_copy*(item: PItem): PItem{.cdecl, dynlib: pangolib, 
    importc: "pango_item_copy".}
proc pango_item_free*(item: PItem){.cdecl, dynlib: pangolib, 
                                    importc: "pango_item_free".}
proc pango_item_split*(orig: PItem, split_index: int32, split_offset: int32): PItem{.
    cdecl, dynlib: pangolib, importc: "pango_item_split".}
proc PANGO_TYPE_LAYOUT*(): GType
proc PANGO_LAYOUT*(anObject: pointer): PLayout
proc PANGO_LAYOUT_CLASS*(klass: pointer): PLayoutClass
proc PANGO_IS_LAYOUT*(anObject: pointer): bool
proc PANGO_IS_LAYOUT_CLASS*(klass: pointer): bool
proc PANGO_LAYOUT_GET_CLASS*(obj: PLayout): PLayoutClass
proc pango_layout_get_type*(): GType{.cdecl, dynlib: pangolib, 
                                      importc: "pango_layout_get_type".}
proc pango_layout_new*(context: PContext): PLayout{.cdecl, dynlib: pangolib, 
    importc: "pango_layout_new".}
proc pango_layout_copy*(src: PLayout): PLayout{.cdecl, dynlib: pangolib, 
    importc: "pango_layout_copy".}
proc pango_layout_get_context*(layout: PLayout): PContext{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_context".}
proc pango_layout_set_attributes*(layout: PLayout, attrs: PAttrList){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_attributes".}
proc pango_layout_get_attributes*(layout: PLayout): PAttrList{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_attributes".}
proc pango_layout_set_text*(layout: PLayout, text: cstring, length: int32){.
    cdecl, dynlib: pangolib, importc: "pango_layout_set_text".}
proc pango_layout_get_text*(layout: PLayout): cstring{.cdecl, dynlib: pangolib, 
    importc: "pango_layout_get_text".}
proc pango_layout_set_markup*(layout: PLayout, markup: cstring, length: int32){.
    cdecl, dynlib: pangolib, importc: "pango_layout_set_markup".}
proc pango_layout_set_markup_with_accel*(layout: PLayout, markup: cstring, 
    length: int32, accel_marker: gunichar, accel_char: Pgunichar){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_markup_with_accel".}
proc pango_layout_set_font_description*(layout: PLayout, desc: PFontDescription){.
    cdecl, dynlib: pangolib, importc: "pango_layout_set_font_description".}
proc pango_layout_set_width*(layout: PLayout, width: int32){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_width".}
proc pango_layout_get_width*(layout: PLayout): int32{.cdecl, dynlib: pangolib, 
    importc: "pango_layout_get_width".}
proc pango_layout_set_wrap*(layout: PLayout, wrap: TWrapMode){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_wrap".}
proc pango_layout_get_wrap*(layout: PLayout): TWrapMode{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_wrap".}
proc pango_layout_set_indent*(layout: PLayout, indent: int32){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_indent".}
proc pango_layout_get_indent*(layout: PLayout): int32{.cdecl, dynlib: pangolib, 
    importc: "pango_layout_get_indent".}
proc pango_layout_set_spacing*(layout: PLayout, spacing: int32){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_spacing".}
proc pango_layout_get_spacing*(layout: PLayout): int32{.cdecl, dynlib: pangolib, 
    importc: "pango_layout_get_spacing".}
proc pango_layout_set_justify*(layout: PLayout, justify: gboolean){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_justify".}
proc pango_layout_get_justify*(layout: PLayout): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_justify".}
proc pango_layout_set_alignment*(layout: PLayout, alignment: TAlignment){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_alignment".}
proc pango_layout_get_alignment*(layout: PLayout): TAlignment{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_alignment".}
proc pango_layout_set_tabs*(layout: PLayout, tabs: PTabArray){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_tabs".}
proc pango_layout_get_tabs*(layout: PLayout): PTabArray{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_tabs".}
proc pango_layout_set_single_paragraph_mode*(layout: PLayout, setting: gboolean){.
    cdecl, dynlib: pangolib, importc: "pango_layout_set_single_paragraph_mode".}
proc pango_layout_get_single_paragraph_mode*(layout: PLayout): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_single_paragraph_mode".}
proc pango_layout_context_changed*(layout: PLayout){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_context_changed".}
proc pango_layout_get_log_attrs*(layout: PLayout, attrs: var PLogAttr, 
                                 n_attrs: Pgint){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_get_log_attrs".}
proc pango_layout_index_to_pos*(layout: PLayout, index: int32, pos: PRectangle){.
    cdecl, dynlib: pangolib, importc: "pango_layout_index_to_pos".}
proc pango_layout_get_cursor_pos*(layout: PLayout, index: int32, 
                                  strong_pos: PRectangle, weak_pos: PRectangle){.
    cdecl, dynlib: pangolib, importc: "pango_layout_get_cursor_pos".}
proc pango_layout_move_cursor_visually*(layout: PLayout, strong: gboolean, 
                                        old_index: int32, old_trailing: int32, 
                                        direction: int32, 
                                        new_index, new_trailing: var int32){.
    cdecl, dynlib: pangolib, importc: "pango_layout_move_cursor_visually".}
proc pango_layout_xy_to_index*(layout: PLayout, x: int32, y: int32, 
                               index, trailing: var int32): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_xy_to_index".}
proc pango_layout_get_extents*(layout: PLayout, ink_rect: PRectangle, 
                               logical_rect: PRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_extents".}
proc pango_layout_get_pixel_extents*(layout: PLayout, ink_rect: PRectangle, 
                                     logical_rect: PRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_pixel_extents".}
proc pango_layout_get_size*(layout: PLayout, width: var int32, height: var int32){.
    cdecl, dynlib: pangolib, importc: "pango_layout_get_size".}
proc pango_layout_get_pixel_size*(layout: PLayout, width: var int32, 
                                  height: var int32){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_get_pixel_size".}
proc pango_layout_get_line_count*(layout: PLayout): int32{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_line_count".}
proc pango_layout_get_line*(layout: PLayout, line: int32): PLayoutLine{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_line".}
proc pango_layout_get_lines*(layout: PLayout): PGSList{.cdecl, dynlib: pangolib, 
    importc: "pango_layout_get_lines".}
proc pango_layout_line_ref*(line: PLayoutLine){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_line_ref".}
proc pango_layout_line_unref*(line: PLayoutLine){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_line_unref".}
proc pango_layout_line_x_to_index*(line: PLayoutLine, x_pos: int32, 
                                   index: var int32, trailing: var int32): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_layout_line_x_to_index".}
proc pango_layout_line_index_to_x*(line: PLayoutLine, index: int32, 
                                   trailing: gboolean, x_pos: var int32){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_line_index_to_x".}
proc pango_layout_line_get_extents*(line: PLayoutLine, ink_rect: PRectangle, 
                                    logical_rect: PRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_line_get_extents".}
proc pango_layout_line_get_pixel_extents*(layout_line: PLayoutLine, 
    ink_rect: PRectangle, logical_rect: PRectangle){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_line_get_pixel_extents".}
proc pango_layout_get_iter*(layout: PLayout): PLayoutIter{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_iter".}
proc pango_layout_iter_free*(iter: PLayoutIter){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_iter_free".}
proc pango_layout_iter_get_index*(iter: PLayoutIter): int32{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_get_index".}
proc pango_layout_iter_get_run*(iter: PLayoutIter): PLayoutRun{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_get_run".}
proc pango_layout_iter_get_line*(iter: PLayoutIter): PLayoutLine{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_get_line".}
proc pango_layout_iter_at_last_line*(iter: PLayoutIter): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_at_last_line".}
proc pango_layout_iter_next_char*(iter: PLayoutIter): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_next_char".}
proc pango_layout_iter_next_cluster*(iter: PLayoutIter): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_next_cluster".}
proc pango_layout_iter_next_run*(iter: PLayoutIter): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_next_run".}
proc pango_layout_iter_next_line*(iter: PLayoutIter): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_next_line".}
proc pango_layout_iter_get_char_extents*(iter: PLayoutIter, 
    logical_rect: PRectangle){.cdecl, dynlib: pangolib, 
                               importc: "pango_layout_iter_get_char_extents".}
proc pango_layout_iter_get_cluster_extents*(iter: PLayoutIter, 
    ink_rect: PRectangle, logical_rect: PRectangle){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_iter_get_cluster_extents".}
proc pango_layout_iter_get_run_extents*(iter: PLayoutIter, ink_rect: PRectangle, 
                                        logical_rect: PRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_get_run_extents".}
proc pango_layout_iter_get_line_extents*(iter: PLayoutIter, 
    ink_rect: PRectangle, logical_rect: PRectangle){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_iter_get_line_extents".}
proc pango_layout_iter_get_line_yrange*(iter: PLayoutIter, y0: var int32, 
                                        y1: var int32){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_iter_get_line_yrange".}
proc pango_layout_iter_get_layout_extents*(iter: PLayoutIter, 
    ink_rect: PRectangle, logical_rect: PRectangle){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_iter_get_layout_extents".}
proc pango_layout_iter_get_baseline*(iter: PLayoutIter): int32{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_get_baseline".}
proc PANGO_TYPE_TAB_ARRAY*(): GType
proc pango_tab_array_new*(initial_size: gint, positions_in_pixels: gboolean): PTabArray{.
    cdecl, dynlib: pangolib, importc: "pango_tab_array_new".}
proc pango_tab_array_get_type*(): GType{.cdecl, dynlib: pangolib, 
    importc: "pango_tab_array_get_type".}
proc pango_tab_array_copy*(src: PTabArray): PTabArray{.cdecl, dynlib: pangolib, 
    importc: "pango_tab_array_copy".}
proc pango_tab_array_free*(tab_array: PTabArray){.cdecl, dynlib: pangolib, 
    importc: "pango_tab_array_free".}
proc pango_tab_array_get_size*(tab_array: PTabArray): gint{.cdecl, 
    dynlib: pangolib, importc: "pango_tab_array_get_size".}
proc pango_tab_array_resize*(tab_array: PTabArray, new_size: gint){.cdecl, 
    dynlib: pangolib, importc: "pango_tab_array_resize".}
proc pango_tab_array_set_tab*(tab_array: PTabArray, tab_index: gint, 
                              alignment: TTabAlign, location: gint){.cdecl, 
    dynlib: pangolib, importc: "pango_tab_array_set_tab".}
proc pango_tab_array_get_tab*(tab_array: PTabArray, tab_index: gint, 
                              alignment: PTabAlign, location: Pgint){.cdecl, 
    dynlib: pangolib, importc: "pango_tab_array_get_tab".}
proc pango_tab_array_get_positions_in_pixels*(tab_array: PTabArray): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_tab_array_get_positions_in_pixels".}
proc PANGO_ASCENT*(rect: TRectangle): int32 = 
  result = - int(rect.y)

proc PANGO_DESCENT*(rect: TRectangle): int32 = 
  result = int(rect.y) + int(rect.height)

proc PANGO_LBEARING*(rect: TRectangle): int32 = 
  result = rect.x

proc PANGO_RBEARING*(rect: TRectangle): int32 = 
  result = (rect.x) + (rect.width)

proc PANGO_TYPE_LANGUAGE*(): GType = 
  result = pango_language_get_type()

proc pango_language_to_string*(language: PLanguage): cstring = 
  result = cast[cstring](language)

proc PANGO_PIXELS*(d: int): int = 
  if d >= 0: 
    result = (d + (PANGO_SCALE div 2)) div PANGO_SCALE
  else: 
    result = (d - (PANGO_SCALE div 2)) div PANGO_SCALE

proc PANGO_TYPE_COLOR*(): GType = 
  result = pango_color_get_type()

proc PANGO_TYPE_ATTR_LIST*(): GType = 
  result = pango_attr_list_get_type()

proc is_line_break*(a: var TLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_line_break) shr
      bp_TPangoLogAttr_is_line_break

proc set_is_line_break*(a: var TLogAttr, `is_line_break`: guint) = 
  a.flag0 = a.flag0 or
      (int16(`is_line_break` shl bp_TPangoLogAttr_is_line_break) and
      bm_TPangoLogAttr_is_line_break)

proc is_mandatory_break*(a: var TLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_mandatory_break) shr
      bp_TPangoLogAttr_is_mandatory_break

proc set_is_mandatory_break*(a: var TLogAttr, `is_mandatory_break`: guint) = 
  a.flag0 = a.flag0 or
      (int16(`is_mandatory_break` shl bp_TPangoLogAttr_is_mandatory_break) and
      bm_TPangoLogAttr_is_mandatory_break)

proc is_char_break*(a: var TLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_char_break) shr
      bp_TPangoLogAttr_is_char_break

proc set_is_char_break*(a: var TLogAttr, `is_char_break`: guint) = 
  a.flag0 = a.flag0 or
      (int16(`is_char_break` shl bp_TPangoLogAttr_is_char_break) and
      bm_TPangoLogAttr_is_char_break)

proc is_white*(a: var TLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_white) shr
      bp_TPangoLogAttr_is_white

proc set_is_white*(a: var TLogAttr, `is_white`: guint) = 
  a.flag0 = a.flag0 or
      (int16(`is_white` shl bp_TPangoLogAttr_is_white) and
      bm_TPangoLogAttr_is_white)

proc is_cursor_position*(a: var TLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_cursor_position) shr
      bp_TPangoLogAttr_is_cursor_position

proc set_is_cursor_position*(a: var TLogAttr, `is_cursor_position`: guint) = 
  a.flag0 = a.flag0 or
      (int16(`is_cursor_position` shl bp_TPangoLogAttr_is_cursor_position) and
      bm_TPangoLogAttr_is_cursor_position)

proc is_word_start*(a: var TLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_word_start) shr
      bp_TPangoLogAttr_is_word_start

proc set_is_word_start*(a: var TLogAttr, `is_word_start`: guint) = 
  a.flag0 = a.flag0 or
      (int16(`is_word_start` shl bp_TPangoLogAttr_is_word_start) and
      bm_TPangoLogAttr_is_word_start)

proc is_word_end*(a: var TLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_word_end) shr
      bp_TPangoLogAttr_is_word_end

proc set_is_word_end*(a: var TLogAttr, `is_word_end`: guint) = 
  a.flag0 = a.flag0 or
      (int16(`is_word_end` shl bp_TPangoLogAttr_is_word_end) and
      bm_TPangoLogAttr_is_word_end)

proc is_sentence_boundary*(a: var TLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_sentence_boundary) shr
      bp_TPangoLogAttr_is_sentence_boundary

proc set_is_sentence_boundary*(a: var TLogAttr, `is_sentence_boundary`: guint) = 
  a.flag0 = a.flag0 or
      (int16(`is_sentence_boundary` shl bp_TPangoLogAttr_is_sentence_boundary) and
      bm_TPangoLogAttr_is_sentence_boundary)

proc is_sentence_start*(a: var TLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_sentence_start) shr
      bp_TPangoLogAttr_is_sentence_start

proc set_is_sentence_start*(a: var TLogAttr, `is_sentence_start`: guint) = 
  a.flag0 = a.flag0 or
      (int16(`is_sentence_start` shl bp_TPangoLogAttr_is_sentence_start) and
      bm_TPangoLogAttr_is_sentence_start)

proc is_sentence_end*(a: var TLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_sentence_end) shr
      bp_TPangoLogAttr_is_sentence_end

proc set_is_sentence_end*(a: var TLogAttr, `is_sentence_end`: guint) = 
  a.flag0 = a.flag0 or
      (int16(`is_sentence_end` shl bp_TPangoLogAttr_is_sentence_end) and
      bm_TPangoLogAttr_is_sentence_end)

proc PANGO_TYPE_CONTEXT*(): GType = 
  result = pango_context_get_type()

proc PANGO_CONTEXT*(anObject: pointer): PContext = 
  result = cast[PContext](G_TYPE_CHECK_INSTANCE_CAST(anObject, 
      PANGO_TYPE_CONTEXT()))

proc PANGO_CONTEXT_CLASS*(klass: pointer): PContextClass = 
  result = cast[PContextClass](G_TYPE_CHECK_CLASS_CAST(klass, 
      PANGO_TYPE_CONTEXT()))

proc PANGO_IS_CONTEXT*(anObject: pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_CONTEXT())

proc PANGO_IS_CONTEXT_CLASS*(klass: pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, PANGO_TYPE_CONTEXT())

proc PANGO_CONTEXT_GET_CLASS*(obj: PContext): PContextClass = 
  result = cast[PContextClass](G_TYPE_INSTANCE_GET_CLASS(obj, 
      PANGO_TYPE_CONTEXT()))

proc PANGO_TYPE_FONTSET*(): GType = 
  result = pango_fontset_get_type()

proc PANGO_FONTSET*(anObject: pointer): PFontset = 
  result = cast[PFontset](G_TYPE_CHECK_INSTANCE_CAST(anObject, 
      PANGO_TYPE_FONTSET()))

proc PANGO_IS_FONTSET*(anObject: pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_FONTSET())

proc PANGO_FONTSET_CLASS*(klass: pointer): PFontsetClass = 
  result = cast[PFontsetClass](G_TYPE_CHECK_CLASS_CAST(klass, 
      PANGO_TYPE_FONTSET()))

proc PANGO_IS_FONTSET_CLASS*(klass: pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, PANGO_TYPE_FONTSET())

proc PANGO_FONTSET_GET_CLASS*(obj: PFontset): PFontsetClass = 
  result = cast[PFontsetClass](G_TYPE_INSTANCE_GET_CLASS(obj, 
      PANGO_TYPE_FONTSET()))

proc pango_fontset_simple_get_type(): GType{.
    importc: "pango_fontset_simple_get_type", cdecl, dynlib: pangolib.}
proc PANGO_TYPE_FONTSET_SIMPLE*(): GType = 
  result = pango_fontset_simple_get_type()

proc PANGO_FONTSET_SIMPLE*(anObject: pointer): PFontsetSimple = 
  result = cast[PFontsetSimple](G_TYPE_CHECK_INSTANCE_CAST(anObject, 
      PANGO_TYPE_FONTSET_SIMPLE()))

proc PANGO_IS_FONTSET_SIMPLE*(anObject: pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_FONTSET_SIMPLE())

proc PANGO_TYPE_FONT_DESCRIPTION*(): GType = 
  result = pango_font_description_get_type()

proc PANGO_TYPE_FONT_METRICS*(): GType = 
  result = pango_font_metrics_get_type()

proc PANGO_TYPE_FONT_FAMILY*(): GType = 
  result = pango_font_family_get_type()

proc PANGO_FONT_FAMILY*(anObject: pointer): PFontFamily = 
  result = cast[PFontFamily](G_TYPE_CHECK_INSTANCE_CAST(anObject, 
      PANGO_TYPE_FONT_FAMILY()))

proc PANGO_IS_FONT_FAMILY*(anObject: Pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_FONT_FAMILY())

proc PANGO_FONT_FAMILY_CLASS*(klass: Pointer): PFontFamilyClass = 
  result = cast[PFontFamilyClass](G_TYPE_CHECK_CLASS_CAST(klass, 
      PANGO_TYPE_FONT_FAMILY()))

proc PANGO_IS_FONT_FAMILY_CLASS*(klass: Pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, PANGO_TYPE_FONT_FAMILY())

proc PANGO_FONT_FAMILY_GET_CLASS*(obj: PFontFamily): PFontFamilyClass = 
  result = cast[PFontFamilyClass](G_TYPE_INSTANCE_GET_CLASS(obj, 
      PANGO_TYPE_FONT_FAMILY()))

proc PANGO_TYPE_FONT_FACE*(): GType = 
  result = pango_font_face_get_type()

proc PANGO_FONT_FACE*(anObject: Pointer): PFontFace = 
  result = cast[PFontFace](G_TYPE_CHECK_INSTANCE_CAST(anObject, 
      PANGO_TYPE_FONT_FACE()))

proc PANGO_IS_FONT_FACE*(anObject: Pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_FONT_FACE())

proc PANGO_FONT_FACE_CLASS*(klass: Pointer): PFontFaceClass = 
  result = cast[PFontFaceClass](G_TYPE_CHECK_CLASS_CAST(klass, 
      PANGO_TYPE_FONT_FACE()))

proc PANGO_IS_FONT_FACE_CLASS*(klass: Pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, PANGO_TYPE_FONT_FACE())

proc PANGO_FONT_FACE_GET_CLASS*(obj: Pointer): PFontFaceClass = 
  result = cast[PFontFaceClass](G_TYPE_INSTANCE_GET_CLASS(obj, 
      PANGO_TYPE_FONT_FACE()))

proc PANGO_TYPE_FONT*(): GType = 
  result = pango_font_get_type()

proc PANGO_FONT*(anObject: Pointer): PFont = 
  result = cast[PFont](G_TYPE_CHECK_INSTANCE_CAST(anObject, PANGO_TYPE_FONT()))

proc PANGO_IS_FONT*(anObject: Pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_FONT())

proc PANGO_FONT_CLASS*(klass: Pointer): PFontClass = 
  result = cast[PFontClass](G_TYPE_CHECK_CLASS_CAST(klass, PANGO_TYPE_FONT()))

proc PANGO_IS_FONT_CLASS*(klass: Pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, PANGO_TYPE_FONT())

proc PANGO_FONT_GET_CLASS*(obj: PFont): PFontClass = 
  result = cast[PFontClass](G_TYPE_INSTANCE_GET_CLASS(obj, PANGO_TYPE_FONT()))

proc PANGO_TYPE_FONT_MAP*(): GType = 
  result = pango_font_map_get_type()

proc PANGO_FONT_MAP*(anObject: pointer): PFontmap = 
  result = cast[PFontmap](G_TYPE_CHECK_INSTANCE_CAST(anObject, 
      PANGO_TYPE_FONT_MAP()))

proc PANGO_IS_FONT_MAP*(anObject: pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_FONT_MAP())

proc PANGO_FONT_MAP_CLASS*(klass: pointer): PFontMapClass = 
  result = cast[PFontMapClass](G_TYPE_CHECK_CLASS_CAST(klass, 
      PANGO_TYPE_FONT_MAP()))

proc PANGO_IS_FONT_MAP_CLASS*(klass: pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, PANGO_TYPE_FONT_MAP())

proc PANGO_FONT_MAP_GET_CLASS*(obj: PFontMap): PFontMapClass = 
  result = cast[PFontMapClass](G_TYPE_INSTANCE_GET_CLASS(obj, 
      PANGO_TYPE_FONT_MAP()))

proc is_cluster_start*(a: var TGlyphVisAttr): guint = 
  result = (a.flag0 and bm_TPangoGlyphVisAttr_is_cluster_start) shr
      bp_TPangoGlyphVisAttr_is_cluster_start

proc set_is_cluster_start*(a: var TGlyphVisAttr, `is_cluster_start`: guint) = 
  a.flag0 = a.flag0 or
      (int16(`is_cluster_start` shl bp_TPangoGlyphVisAttr_is_cluster_start) and
      bm_TPangoGlyphVisAttr_is_cluster_start)

proc PANGO_TYPE_GLYPH_STRING*(): GType = 
  result = pango_glyph_string_get_type()

proc PANGO_TYPE_LAYOUT*(): GType = 
  result = pango_layout_get_type()

proc PANGO_LAYOUT*(anObject: pointer): PLayout = 
  result = cast[PLayout](G_TYPE_CHECK_INSTANCE_CAST(anObject, 
      PANGO_TYPE_LAYOUT()))

proc PANGO_LAYOUT_CLASS*(klass: pointer): PLayoutClass = 
  result = cast[PLayoutClass](G_TYPE_CHECK_CLASS_CAST(klass, PANGO_TYPE_LAYOUT()))

proc PANGO_IS_LAYOUT*(anObject: pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_LAYOUT())

proc PANGO_IS_LAYOUT_CLASS*(klass: pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, PANGO_TYPE_LAYOUT())

proc PANGO_LAYOUT_GET_CLASS*(obj: PLayout): PLayoutClass = 
  result = cast[PLayoutClass](G_TYPE_INSTANCE_GET_CLASS(obj, PANGO_TYPE_LAYOUT()))

proc PANGO_TYPE_TAB_ARRAY*(): GType = 
  result = pango_tab_array_get_type()
