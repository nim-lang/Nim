import 
  glib2

{.define: PANGO_ENABLE_ENGINE.}
{.define: PANGO_ENABLE_BACKEND.}
when defined(win32): 
  {.define: pangowin.}
  const 
    pangolib* = "libpango-1.0-0.dll"
else: 
  const 
    pangolib* = "libpango-1.0.so.0"
type 
  PPangoFont* = pointer
  PPangoFontFamily* = pointer
  PPangoFontset* = pointer
  PPangoFontMetrics* = pointer
  PPangoFontFace* = pointer 
  PPangoFontMap* = pointer
  PPangoFontsetClass* = pointer
  PPangoFontFamilyClass* = pointer
  PPangoFontFaceClass* = pointer
  PPangoFontClass* = pointer
  PPangoFontMapClass* = pointer
  PPangoFontDescription* = ptr TPangoFontDescription
  TPangoFontDescription* = pointer
  PPangoAttrList* = ptr TPangoAttrList
  TPangoAttrList* = pointer
  PPangoAttrIterator* = ptr TPangoAttrIterator
  TPangoAttrIterator* = pointer
  PPangoLayout* = ptr TPangoLayout
  TPangoLayout* = pointer
  PPangoLayoutClass* = ptr TPangoLayoutClass
  TPangoLayoutClass* = pointer
  PPangoLayoutIter* = ptr TPangoLayoutIter
  TPangoLayoutIter* = pointer
  PPangoContext* = ptr TPangoContext
  TPangoContext* = pointer
  PPangoContextClass* = ptr TPangoContextClass
  TPangoContextClass* = pointer
  PPangoFontsetSimple* = ptr TPangoFontsetSimple
  TPangoFontsetSimple* = pointer
  PPangoTabArray* = ptr TPangoTabArray
  TPangoTabArray* = pointer
  PPangoGlyphString* = ptr TPangoGlyphString
  PPangoAnalysis* = ptr TPangoAnalysis
  PPangoItem* = ptr TPangoItem
  PPangoLanguage* = ptr TPangoLanguage
  TPangoLanguage* = pointer
  PPangoGlyph* = ptr TPangoGlyph
  TPangoGlyph* = guint32
  PPangoRectangle* = ptr TPangoRectangle
  TPangoRectangle* {.final.} = object 
    x*: int32
    y*: int32
    width*: int32
    height*: int32

  PPangoDirection* = ptr TPangoDirection
  TPangoDirection* = enum 
    PANGO_DIRECTION_LTR, PANGO_DIRECTION_RTL, PANGO_DIRECTION_TTB_LTR, 
    PANGO_DIRECTION_TTB_RTL
  PPangoColor* = ptr TPangoColor
  TPangoColor* {.final.} = object 
    red*: guint16
    green*: guint16
    blue*: guint16

  PPangoAttrType* = ptr TPangoAttrType
  TPangoAttrType* = int32
  PPangoUnderline* = ptr TPangoUnderline
  TPangoUnderline* = int32
  PPangoAttribute* = ptr TPangoAttribute
  PPangoAttrClass* = ptr TPangoAttrClass
  TPangoAttribute* {.final.} = object 
    klass*: PPangoAttrClass
    start_index*: int
    end_index*: int

  TPangoAttrClass* {.final.} = object 
    `type`*: TPangoAttrType
    copy*: proc (attr: PPangoAttribute): PPangoAttribute{.cdecl.}
    destroy*: proc (attr: PPangoAttribute){.cdecl.}
    equal*: proc (attr1: PPangoAttribute, attr2: PPangoAttribute): gboolean{.
        cdecl.}

  PPangoAttrString* = ptr TPangoAttrString
  TPangoAttrString* {.final.} = object 
    attr*: TPangoAttribute
    value*: cstring

  PPangoAttrLanguage* = ptr TPangoAttrLanguage
  TPangoAttrLanguage* {.final.} = object 
    attr*: TPangoAttribute
    value*: PPangoLanguage

  PPangoAttrInt* = ptr TPangoAttrInt
  TPangoAttrInt* {.final.} = object 
    attr*: TPangoAttribute
    value*: int32

  PPangoAttrFloat* = ptr TPangoAttrFloat
  TPangoAttrFloat* {.final.} = object 
    attr*: TPangoAttribute
    value*: gdouble

  PPangoAttrColor* = ptr TPangoAttrColor
  TPangoAttrColor* {.final.} = object 
    attr*: TPangoAttribute
    color*: TPangoColor

  PPangoAttrShape* = ptr TPangoAttrShape
  TPangoAttrShape* {.final.} = object 
    attr*: TPangoAttribute
    ink_rect*: TPangoRectangle
    logical_rect*: TPangoRectangle

  PPangoAttrFontDesc* = ptr TPangoAttrFontDesc
  TPangoAttrFontDesc* {.final.} = object 
    attr*: TPangoAttribute
    desc*: PPangoFontDescription

  PPangoLogAttr* = ptr TPangoLogAttr
  TPangoLogAttr* {.final.} = object 
    flag0*: guint16

  PPangoCoverageLevel* = ptr TPangoCoverageLevel
  TPangoCoverageLevel* = enum 
    PANGO_COVERAGE_NONE, PANGO_COVERAGE_FALLBACK, PANGO_COVERAGE_APPROXIMATE, 
    PANGO_COVERAGE_EXACT
  PPangoBlockInfo* = ptr TPangoBlockInfo
  TPangoBlockInfo* {.final.} = object 
    data*: Pguchar
    level*: TPangoCoverageLevel

  PPangoCoverage* = ptr TPangoCoverage
  TPangoCoverage* {.final.} = object 
    ref_count*: int
    n_blocks*: int32
    data_size*: int32
    blocks*: PPangoBlockInfo

  PPangoEngineRange* = ptr TPangoEngineRange
  TPangoEngineRange* {.final.} = object 
    start*: int32
    theEnd*: int32
    langs*: cstring

  PPangoEngineInfo* = ptr TPangoEngineInfo
  TPangoEngineInfo* {.final.} = object 
    id*: cstring
    engine_type*: cstring
    render_type*: cstring
    ranges*: PPangoEngineRange
    n_ranges*: gint

  PPangoEngine* = ptr TPangoEngine
  TPangoEngine* {.final.} = object 
    id*: cstring
    `type`*: cstring
    length*: gint

  TPangoEngineLangScriptBreak* = proc (text: cstring, len: int32, 
                                       analysis: PPangoAnalysis, 
                                       attrs: PPangoLogAttr, attrs_len: int32){.
      cdecl.}
  PPangoEngineLang* = ptr TPangoEngineLang
  TPangoEngineLang* {.final.} = object 
    engine*: TPangoEngine
    script_break*: TPangoEngineLangScriptBreak

  TPangoEngineShapeScript* = proc (font: PPangoFont, text: cstring, 
                                   length: int32, analysis: PPangoAnalysis, 
                                   glyphs: PPangoGlyphString){.cdecl.}
  TPangoEngineShapeGetCoverage* = proc (font: PPangoFont, 
                                        language: PPangoLanguage): PPangoCoverage{.
      cdecl.}
  PPangoEngineShape* = ptr TPangoEngineShape
  TPangoEngineShape* {.final.} = object 
    engine*: TPangoEngine
    script_shape*: TPangoEngineShapeScript
    get_coverage*: TPangoEngineShapeGetCoverage

  PPangoStyle* = ptr TPangoStyle
  TPangoStyle* = gint
  PPangoVariant* = ptr TPangoVariant
  TPangoVariant* = gint
  PPangoWeight* = ptr TPangoWeight
  TPangoWeight* = gint
  PPangoStretch* = ptr TPangoStretch
  TPangoStretch* = gint
  PPangoFontMask* = ptr TPangoFontMask
  TPangoFontMask* = int32
  PPangoGlyphUnit* = ptr TPangoGlyphUnit
  TPangoGlyphUnit* = gint32
  PPangoGlyphGeometry* = ptr TPangoGlyphGeometry
  TPangoGlyphGeometry* {.final.} = object 
    width*: TPangoGlyphUnit
    x_offset*: TPangoGlyphUnit
    y_offset*: TPangoGlyphUnit

  PPangoGlyphVisAttr* = ptr TPangoGlyphVisAttr
  TPangoGlyphVisAttr* {.final.} = object 
    flag0*: int16

  PPangoGlyphInfo* = ptr TPangoGlyphInfo
  TPangoGlyphInfo* {.final.} = object 
    glyph*: TPangoGlyph
    geometry*: TPangoGlyphGeometry
    attr*: TPangoGlyphVisAttr

  TPangoGlyphString* {.final.} = object 
    num_glyphs*: gint
    glyphs*: PPangoGlyphInfo
    log_clusters*: Pgint
    space*: gint

  TPangoAnalysis* {.final.} = object 
    shape_engine*: PPangoEngineShape
    lang_engine*: PPangoEngineLang
    font*: PPangoFont
    level*: guint8
    language*: PPangoLanguage
    extra_attrs*: PGSList

  TPangoItem* {.final.} = object 
    offset*: gint
    length*: gint
    num_chars*: gint
    analysis*: TPangoAnalysis

  PPangoAlignment* = ptr TPangoAlignment
  TPangoAlignment* = enum 
    PANGO_ALIGN_LEFT, PANGO_ALIGN_CENTER, PANGO_ALIGN_RIGHT
  PPangoWrapMode* = ptr TPangoWrapMode
  TPangoWrapMode* = enum 
    PANGO_WRAP_WORD, PANGO_WRAP_CHAR
  PPangoLayoutLine* = ptr TPangoLayoutLine
  TPangoLayoutLine* {.final.} = object 
    layout*: PPangoLayout
    start_index*: gint
    length*: gint
    runs*: PGSList

  PPangoLayoutRun* = ptr TPangoLayoutRun
  TPangoLayoutRun* {.final.} = object 
    item*: PPangoItem
    glyphs*: PPangoGlyphString

  PPangoTabAlign* = ptr TPangoTabAlign
  TPangoTabAlign* = enum 
    PANGO_TAB_LEFT

const 
  PANGO_SCALE* = 1024

proc PANGO_PIXELS*(d: int): int
proc PANGO_ASCENT*(rect: TPangoRectangle): int32
proc PANGO_DESCENT*(rect: TPangoRectangle): int32
proc PANGO_LBEARING*(rect: TPangoRectangle): int32
proc PANGO_RBEARING*(rect: TPangoRectangle): int32
proc PANGO_TYPE_LANGUAGE*(): GType
proc pango_language_get_type*(): GType{.cdecl, dynlib: pangolib, 
                                        importc: "pango_language_get_type".}
proc pango_language_from_string*(language: cstring): PPangoLanguage{.cdecl, 
    dynlib: pangolib, importc: "pango_language_from_string".}
proc pango_language_to_string*(language: PPangoLanguage): cstring
proc pango_language_matches*(language: PPangoLanguage, range_list: cstring): gboolean{.
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
proc pango_color_copy*(src: PPangoColor): PPangoColor{.cdecl, dynlib: pangolib, 
    importc: "pango_color_copy".}
proc pango_color_free*(color: PPangoColor){.cdecl, dynlib: pangolib, 
    importc: "pango_color_free".}
proc pango_color_parse*(color: PPangoColor, spec: cstring): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_color_parse".}
proc PANGO_TYPE_ATTR_LIST*(): GType
proc pango_attr_type_register*(name: cstring): TPangoAttrType{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_type_register".}
proc pango_attribute_copy*(attr: PPangoAttribute): PPangoAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attribute_copy".}
proc pango_attribute_destroy*(attr: PPangoAttribute){.cdecl, dynlib: pangolib, 
    importc: "pango_attribute_destroy".}
proc pango_attribute_equal*(attr1: PPangoAttribute, attr2: PPangoAttribute): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_attribute_equal".}
proc pango_attr_language_new*(language: PPangoLanguage): PPangoAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_language_new".}
proc pango_attr_family_new*(family: cstring): PPangoAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_family_new".}
proc pango_attr_foreground_new*(red: guint16, green: guint16, blue: guint16): PPangoAttribute{.
    cdecl, dynlib: pangolib, importc: "pango_attr_foreground_new".}
proc pango_attr_background_new*(red: guint16, green: guint16, blue: guint16): PPangoAttribute{.
    cdecl, dynlib: pangolib, importc: "pango_attr_background_new".}
proc pango_attr_size_new*(size: int32): PPangoAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_size_new".}
proc pango_attr_style_new*(style: TPangoStyle): PPangoAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_style_new".}
proc pango_attr_weight_new*(weight: TPangoWeight): PPangoAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_weight_new".}
proc pango_attr_variant_new*(variant: TPangoVariant): PPangoAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_variant_new".}
proc pango_attr_stretch_new*(stretch: TPangoStretch): PPangoAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_stretch_new".}
proc pango_attr_font_desc_new*(desc: PPangoFontDescription): PPangoAttribute{.
    cdecl, dynlib: pangolib, importc: "pango_attr_font_desc_new".}
proc pango_attr_underline_new*(underline: TPangoUnderline): PPangoAttribute{.
    cdecl, dynlib: pangolib, importc: "pango_attr_underline_new".}
proc pango_attr_strikethrough_new*(strikethrough: gboolean): PPangoAttribute{.
    cdecl, dynlib: pangolib, importc: "pango_attr_strikethrough_new".}
proc pango_attr_rise_new*(rise: int32): PPangoAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_rise_new".}
proc pango_attr_shape_new*(ink_rect: PPangoRectangle, 
                           logical_rect: PPangoRectangle): PPangoAttribute{.
    cdecl, dynlib: pangolib, importc: "pango_attr_shape_new".}
proc pango_attr_scale_new*(scale_factor: gdouble): PPangoAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_scale_new".}
proc pango_attr_list_get_type*(): GType{.cdecl, dynlib: pangolib, 
    importc: "pango_attr_list_get_type".}
proc pango_attr_list_new*(): PPangoAttrList{.cdecl, dynlib: pangolib, 
    importc: "pango_attr_list_new".}
proc pango_attr_list_ref*(list: PPangoAttrList){.cdecl, dynlib: pangolib, 
    importc: "pango_attr_list_ref".}
proc pango_attr_list_unref*(list: PPangoAttrList){.cdecl, dynlib: pangolib, 
    importc: "pango_attr_list_unref".}
proc pango_attr_list_copy*(list: PPangoAttrList): PPangoAttrList{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_list_copy".}
proc pango_attr_list_insert*(list: PPangoAttrList, attr: PPangoAttribute){.
    cdecl, dynlib: pangolib, importc: "pango_attr_list_insert".}
proc pango_attr_list_insert_before*(list: PPangoAttrList, attr: PPangoAttribute){.
    cdecl, dynlib: pangolib, importc: "pango_attr_list_insert_before".}
proc pango_attr_list_change*(list: PPangoAttrList, attr: PPangoAttribute){.
    cdecl, dynlib: pangolib, importc: "pango_attr_list_change".}
proc pango_attr_list_splice*(list: PPangoAttrList, other: PPangoAttrList, 
                             pos: gint, len: gint){.cdecl, dynlib: pangolib, 
    importc: "pango_attr_list_splice".}
proc pango_attr_list_get_iterator*(list: PPangoAttrList): PPangoAttrIterator{.
    cdecl, dynlib: pangolib, importc: "pango_attr_list_get_iterator".}
proc pango_attr_iterator_range*(`iterator`: PPangoAttrIterator, start: Pgint, 
                                theEnd: Pgint){.cdecl, dynlib: pangolib, 
    importc: "pango_attr_iterator_range".}
proc pango_attr_iterator_next*(`iterator`: PPangoAttrIterator): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_iterator_next".}
proc pango_attr_iterator_copy*(`iterator`: PPangoAttrIterator): PPangoAttrIterator{.
    cdecl, dynlib: pangolib, importc: "pango_attr_iterator_copy".}
proc pango_attr_iterator_destroy*(`iterator`: PPangoAttrIterator){.cdecl, 
    dynlib: pangolib, importc: "pango_attr_iterator_destroy".}
proc pango_attr_iterator_get*(`iterator`: PPangoAttrIterator, 
                              `type`: TPangoAttrType): PPangoAttribute{.cdecl, 
    dynlib: pangolib, importc: "pango_attr_iterator_get".}
proc pango_attr_iterator_get_font*(`iterator`: PPangoAttrIterator, 
                                   desc: PPangoFontDescription, 
                                   language: var PPangoLanguage, 
                                   extra_attrs: PPGSList){.cdecl, 
    dynlib: pangolib, importc: "pango_attr_iterator_get_font".}
proc pango_parse_markup*(markup_text: cstring, length: int32, 
                         accel_marker: gunichar, attr_list: var PPangoAttrList, 
                         text: PPchar, accel_char: Pgunichar, error: pointer): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_parse_markup".}
const 
  bm_TPangoLogAttr_is_line_break* = 0x00000001
  bp_TPangoLogAttr_is_line_break* = 0
  bm_TPangoLogAttr_is_mandatory_break* = 0x00000002
  bp_TPangoLogAttr_is_mandatory_break* = 1
  bm_TPangoLogAttr_is_char_break* = 0x00000004
  bp_TPangoLogAttr_is_char_break* = 2
  bm_TPangoLogAttr_is_white* = 0x00000008
  bp_TPangoLogAttr_is_white* = 3
  bm_TPangoLogAttr_is_cursor_position* = 0x00000010
  bp_TPangoLogAttr_is_cursor_position* = 4
  bm_TPangoLogAttr_is_word_start* = 0x00000020
  bp_TPangoLogAttr_is_word_start* = 5
  bm_TPangoLogAttr_is_word_end* = 0x00000040
  bp_TPangoLogAttr_is_word_end* = 6
  bm_TPangoLogAttr_is_sentence_boundary* = 0x00000080
  bp_TPangoLogAttr_is_sentence_boundary* = 7
  bm_TPangoLogAttr_is_sentence_start* = 0x00000100
  bp_TPangoLogAttr_is_sentence_start* = 8
  bm_TPangoLogAttr_is_sentence_end* = 0x00000200
  bp_TPangoLogAttr_is_sentence_end* = 9

proc is_line_break*(a: var TPangoLogAttr): guint
proc set_is_line_break*(a: var TPangoLogAttr, `is_line_break`: guint)
proc is_mandatory_break*(a: var TPangoLogAttr): guint
proc set_is_mandatory_break*(a: var TPangoLogAttr, `is_mandatory_break`: guint)
proc is_char_break*(a: var TPangoLogAttr): guint
proc set_is_char_break*(a: var TPangoLogAttr, `is_char_break`: guint)
proc is_white*(a: var TPangoLogAttr): guint
proc set_is_white*(a: var TPangoLogAttr, `is_white`: guint)
proc is_cursor_position*(a: var TPangoLogAttr): guint
proc set_is_cursor_position*(a: var TPangoLogAttr, `is_cursor_position`: guint)
proc is_word_start*(a: var TPangoLogAttr): guint
proc set_is_word_start*(a: var TPangoLogAttr, `is_word_start`: guint)
proc is_word_end*(a: var TPangoLogAttr): guint
proc set_is_word_end*(a: var TPangoLogAttr, `is_word_end`: guint)
proc is_sentence_boundary*(a: var TPangoLogAttr): guint
proc set_is_sentence_boundary*(a: var TPangoLogAttr, 
                               `is_sentence_boundary`: guint)
proc is_sentence_start*(a: var TPangoLogAttr): guint
proc set_is_sentence_start*(a: var TPangoLogAttr, `is_sentence_start`: guint)
proc is_sentence_end*(a: var TPangoLogAttr): guint
proc set_is_sentence_end*(a: var TPangoLogAttr, `is_sentence_end`: guint)
proc pango_break*(text: cstring, length: int32, analysis: PPangoAnalysis, 
                  attrs: PPangoLogAttr, attrs_len: int32){.cdecl, 
    dynlib: pangolib, importc: "pango_break".}
proc pango_find_paragraph_boundary*(text: cstring, length: gint, 
                                    paragraph_delimiter_index: Pgint, 
                                    next_paragraph_start: Pgint){.cdecl, 
    dynlib: pangolib, importc: "pango_find_paragraph_boundary".}
proc pango_get_log_attrs*(text: cstring, length: int32, level: int32, 
                          language: PPangoLanguage, log_attrs: PPangoLogAttr, 
                          attrs_len: int32){.cdecl, dynlib: pangolib, 
    importc: "pango_get_log_attrs".}
proc PANGO_TYPE_CONTEXT*(): GType
proc PANGO_CONTEXT*(anObject: pointer): PPangoContext
proc PANGO_CONTEXT_CLASS*(klass: pointer): PPangoContextClass
proc PANGO_IS_CONTEXT*(anObject: pointer): bool
proc PANGO_IS_CONTEXT_CLASS*(klass: pointer): bool
proc PANGO_CONTEXT_GET_CLASS*(obj: PPangoContext): PPangoContextClass
proc pango_context_get_type*(): GType{.cdecl, dynlib: pangolib, 
                                       importc: "pango_context_get_type".}
proc pango_context_list_families*(context: PPangoContext, 
                                  families: openarray[ptr PPangoFontFamily]){.cdecl, 
    dynlib: pangolib, importc: "pango_context_list_families".}
proc pango_context_load_font*(context: PPangoContext, 
                              desc: PPangoFontDescription): PPangoFont{.cdecl, 
    dynlib: pangolib, importc: "pango_context_load_font".}
proc pango_context_load_fontset*(context: PPangoContext, 
                                 desc: PPangoFontDescription, 
                                 language: PPangoLanguage): PPangoFontset{.
    cdecl, dynlib: pangolib, importc: "pango_context_load_fontset".}
proc pango_context_get_metrics*(context: PPangoContext, 
                                desc: PPangoFontDescription, 
                                language: PPangoLanguage): PPangoFontMetrics{.
    cdecl, dynlib: pangolib, importc: "pango_context_get_metrics".}
proc pango_context_set_font_description*(context: PPangoContext, 
    desc: PPangoFontDescription){.cdecl, dynlib: pangolib, 
                                  importc: "pango_context_set_font_description".}
proc pango_context_get_font_description*(context: PPangoContext): PPangoFontDescription{.
    cdecl, dynlib: pangolib, importc: "pango_context_get_font_description".}
proc pango_context_get_language*(context: PPangoContext): PPangoLanguage{.cdecl, 
    dynlib: pangolib, importc: "pango_context_get_language".}
proc pango_context_set_language*(context: PPangoContext, 
                                 language: PPangoLanguage){.cdecl, 
    dynlib: pangolib, importc: "pango_context_set_language".}
proc pango_context_set_base_dir*(context: PPangoContext, 
                                 direction: TPangoDirection){.cdecl, 
    dynlib: pangolib, importc: "pango_context_set_base_dir".}
proc pango_context_get_base_dir*(context: PPangoContext): TPangoDirection{.
    cdecl, dynlib: pangolib, importc: "pango_context_get_base_dir".}
proc pango_itemize*(context: PPangoContext, text: cstring, start_index: int32, 
                    length: int32, attrs: PPangoAttrList, 
                    cached_iter: PPangoAttrIterator): PGList{.cdecl, 
    dynlib: pangolib, importc: "pango_itemize".}
proc pango_coverage_new*(): PPangoCoverage{.cdecl, dynlib: pangolib, 
    importc: "pango_coverage_new".}
proc pango_coverage_ref*(coverage: PPangoCoverage): PPangoCoverage{.cdecl, 
    dynlib: pangolib, importc: "pango_coverage_ref".}
proc pango_coverage_unref*(coverage: PPangoCoverage){.cdecl, dynlib: pangolib, 
    importc: "pango_coverage_unref".}
proc pango_coverage_copy*(coverage: PPangoCoverage): PPangoCoverage{.cdecl, 
    dynlib: pangolib, importc: "pango_coverage_copy".}
proc pango_coverage_get*(coverage: PPangoCoverage, index: int32): TPangoCoverageLevel{.
    cdecl, dynlib: pangolib, importc: "pango_coverage_get".}
proc pango_coverage_set*(coverage: PPangoCoverage, index: int32, 
                         level: TPangoCoverageLevel){.cdecl, dynlib: pangolib, 
    importc: "pango_coverage_set".}
proc pango_coverage_max*(coverage: PPangoCoverage, other: PPangoCoverage){.
    cdecl, dynlib: pangolib, importc: "pango_coverage_max".}
proc pango_coverage_to_bytes*(coverage: PPangoCoverage, bytes: PPguchar, 
                              n_bytes: var int32){.cdecl, dynlib: pangolib, 
    importc: "pango_coverage_to_bytes".}
proc pango_coverage_from_bytes*(bytes: Pguchar, n_bytes: int32): PPangoCoverage{.
    cdecl, dynlib: pangolib, importc: "pango_coverage_from_bytes".}
proc PANGO_TYPE_FONTSET*(): GType
proc PANGO_FONTSET*(anObject: pointer): PPangoFontset
proc PANGO_IS_FONTSET*(anObject: pointer): bool
proc pango_fontset_get_type*(): GType{.cdecl, dynlib: pangolib, 
                                       importc: "pango_fontset_get_type".}
proc pango_fontset_get_font*(fontset: PPangoFontset, wc: guint): PPangoFont{.
    cdecl, dynlib: pangolib, importc: "pango_fontset_get_font".}
proc pango_fontset_get_metrics*(fontset: PPangoFontset): PPangoFontMetrics{.
    cdecl, dynlib: pangolib, importc: "pango_fontset_get_metrics".}
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
  PANGO_SCALE_XX_SMALL* = 0.5787037037036999
  PANGO_SCALE_X_SMALL* = 0.6444444444443999
  PANGO_SCALE_SMALL* = 0.8333333333332999
  PANGO_SCALE_MEDIUM* = 1.0
  PANGO_SCALE_LARGE* = 1.2
  PANGO_SCALE_X_LARGE* = 1.4399999999999
  PANGO_SCALE_XX_LARGE* = 1.728

proc PANGO_TYPE_FONT_DESCRIPTION*(): GType
proc pango_font_description_get_type*(): GType{.cdecl, dynlib: pangolib, 
    importc: "pango_font_description_get_type".}
proc pango_font_description_new*(): PPangoFontDescription{.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_new".}
proc pango_font_description_copy*(desc: PPangoFontDescription): PPangoFontDescription{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_copy".}
proc pango_font_description_copy_static*(desc: PPangoFontDescription): PPangoFontDescription{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_copy_static".}
proc pango_font_description_hash*(desc: PPangoFontDescription): guint{.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_hash".}
proc pango_font_description_equal*(desc1: PPangoFontDescription, 
                                   desc2: PPangoFontDescription): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_equal".}
proc pango_font_description_free*(desc: PPangoFontDescription){.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_free".}
proc pango_font_descriptions_free*(descs: var PPangoFontDescription, 
                                   n_descs: int32){.cdecl, dynlib: pangolib, 
    importc: "pango_font_descriptions_free".}
proc pango_font_description_set_family*(desc: PPangoFontDescription, 
                                        family: cstring){.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_set_family".}
proc pango_font_description_set_family_static*(desc: PPangoFontDescription, 
    family: cstring){.cdecl, dynlib: pangolib, 
                      importc: "pango_font_description_set_family_static".}
proc pango_font_description_get_family*(desc: PPangoFontDescription): cstring{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_get_family".}
proc pango_font_description_set_style*(desc: PPangoFontDescription, 
                                       style: TPangoStyle){.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_set_style".}
proc pango_font_description_get_style*(desc: PPangoFontDescription): TPangoStyle{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_get_style".}
proc pango_font_description_set_variant*(desc: PPangoFontDescription, 
    variant: TPangoVariant){.cdecl, dynlib: pangolib, 
                             importc: "pango_font_description_set_variant".}
proc pango_font_description_get_variant*(desc: PPangoFontDescription): TPangoVariant{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_get_variant".}
proc pango_font_description_set_weight*(desc: PPangoFontDescription, 
                                        weight: TPangoWeight){.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_set_weight".}
proc pango_font_description_get_weight*(desc: PPangoFontDescription): TPangoWeight{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_get_weight".}
proc pango_font_description_set_stretch*(desc: PPangoFontDescription, 
    stretch: TPangoStretch){.cdecl, dynlib: pangolib, 
                             importc: "pango_font_description_set_stretch".}
proc pango_font_description_get_stretch*(desc: PPangoFontDescription): TPangoStretch{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_get_stretch".}
proc pango_font_description_set_size*(desc: PPangoFontDescription, size: gint){.
    cdecl, dynlib: pangolib, importc: "pango_font_description_set_size".}
proc pango_font_description_get_size*(desc: PPangoFontDescription): gint{.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_get_size".}
proc pango_font_description_set_absolute_size*(desc: PPangoFontDescription, 
    size: float64){.cdecl, dynlib: pangolib, 
                    importc: "pango_font_description_set_absolute_size".}
proc pango_font_description_get_size_is_absolute*(desc: PPangoFontDescription, 
    size: float64): gboolean{.cdecl, dynlib: pangolib, importc: "pango_font_description_get_size_is_absolute".}
proc pango_font_description_get_set_fields*(desc: PPangoFontDescription): TPangoFontMask{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_get_set_fields".}
proc pango_font_description_unset_fields*(desc: PPangoFontDescription, 
    to_unset: TPangoFontMask){.cdecl, dynlib: pangolib, 
                               importc: "pango_font_description_unset_fields".}
proc pango_font_description_merge*(desc: PPangoFontDescription, 
                                   desc_to_merge: PPangoFontDescription, 
                                   replace_existing: gboolean){.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_merge".}
proc pango_font_description_merge_static*(desc: PPangoFontDescription, 
    desc_to_merge: PPangoFontDescription, replace_existing: gboolean){.cdecl, 
    dynlib: pangolib, importc: "pango_font_description_merge_static".}
proc pango_font_description_better_match*(desc: PPangoFontDescription, 
    old_match: PPangoFontDescription, new_match: PPangoFontDescription): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_better_match".}
proc pango_font_description_from_string*(str: cstring): PPangoFontDescription{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_from_string".}
proc pango_font_description_to_string*(desc: PPangoFontDescription): cstring{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_to_string".}
proc pango_font_description_to_filename*(desc: PPangoFontDescription): cstring{.
    cdecl, dynlib: pangolib, importc: "pango_font_description_to_filename".}
proc PANGO_TYPE_FONT_METRICS*(): GType
proc pango_font_metrics_get_type*(): GType{.cdecl, dynlib: pangolib, 
    importc: "pango_font_metrics_get_type".}
proc pango_font_metrics_ref*(metrics: PPangoFontMetrics): PPangoFontMetrics{.
    cdecl, dynlib: pangolib, importc: "pango_font_metrics_ref".}
proc pango_font_metrics_unref*(metrics: PPangoFontMetrics){.cdecl, 
    dynlib: pangolib, importc: "pango_font_metrics_unref".}
proc pango_font_metrics_get_ascent*(metrics: PPangoFontMetrics): int32{.cdecl, 
    dynlib: pangolib, importc: "pango_font_metrics_get_ascent".}
proc pango_font_metrics_get_descent*(metrics: PPangoFontMetrics): int32{.cdecl, 
    dynlib: pangolib, importc: "pango_font_metrics_get_descent".}
proc pango_font_metrics_get_approximate_char_width*(metrics: PPangoFontMetrics): int32{.
    cdecl, dynlib: pangolib, 
    importc: "pango_font_metrics_get_approximate_char_width".}
proc pango_font_metrics_get_approximate_digit_width*(metrics: PPangoFontMetrics): int32{.
    cdecl, dynlib: pangolib, 
    importc: "pango_font_metrics_get_approximate_digit_width".}
proc PANGO_TYPE_FONT_FAMILY*(): GType
proc PANGO_FONT_FAMILY*(anObject: Pointer): PPangoFontFamily
proc PANGO_IS_FONT_FAMILY*(anObject: Pointer): bool
proc pango_font_family_get_type*(): GType{.cdecl, dynlib: pangolib, 
    importc: "pango_font_family_get_type".}
proc pango_font_family_list_faces*(family: PPangoFontFamily, 
                                   faces: var openarray[ptr PPangoFontFace]){.
    cdecl, dynlib: pangolib, importc: "pango_font_family_list_faces".}
proc pango_font_family_get_name*(family: PPangoFontFamily): cstring{.cdecl, 
    dynlib: pangolib, importc: "pango_font_family_get_name".}
proc PANGO_TYPE_FONT_FACE*(): GType
proc PANGO_FONT_FACE*(anObject: pointer): PPangoFontFace
proc PANGO_IS_FONT_FACE*(anObject: pointer): bool
proc pango_font_face_get_type*(): GType{.cdecl, dynlib: pangolib, 
    importc: "pango_font_face_get_type".}
proc pango_font_face_describe*(face: PPangoFontFace): PPangoFontDescription{.
    cdecl, dynlib: pangolib, importc: "pango_font_face_describe".}
proc pango_font_face_get_face_name*(face: PPangoFontFace): cstring{.cdecl, 
    dynlib: pangolib, importc: "pango_font_face_get_face_name".}
proc PANGO_TYPE_FONT*(): GType
proc PANGO_FONT*(anObject: pointer): PPangoFont
proc PANGO_IS_FONT*(anObject: pointer): bool
proc pango_font_get_type*(): GType{.cdecl, dynlib: pangolib, 
                                    importc: "pango_font_get_type".}
proc pango_font_describe*(font: PPangoFont): PPangoFontDescription{.cdecl, 
    dynlib: pangolib, importc: "pango_font_describe".}
proc pango_font_get_coverage*(font: PPangoFont, language: PPangoLanguage): PPangoCoverage{.
    cdecl, dynlib: pangolib, importc: "pango_font_get_coverage".}
proc pango_font_find_shaper*(font: PPangoFont, language: PPangoLanguage, 
                             ch: guint32): PPangoEngineShape{.cdecl, 
    dynlib: pangolib, importc: "pango_font_find_shaper".}
proc pango_font_get_metrics*(font: PPangoFont, language: PPangoLanguage): PPangoFontMetrics{.
    cdecl, dynlib: pangolib, importc: "pango_font_get_metrics".}
proc pango_font_get_glyph_extents*(font: PPangoFont, glyph: TPangoGlyph, 
                                   ink_rect: PPangoRectangle, 
                                   logical_rect: PPangoRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_font_get_glyph_extents".}
proc PANGO_TYPE_FONT_MAP*(): GType
proc PANGO_FONT_MAP*(anObject: pointer): PPangoFontMap
proc PANGO_IS_FONT_MAP*(anObject: pointer): bool
proc pango_font_map_get_type*(): GType{.cdecl, dynlib: pangolib, 
                                        importc: "pango_font_map_get_type".}
proc pango_font_map_load_font*(fontmap: PPangoFontMap, context: PPangoContext, 
                               desc: PPangoFontDescription): PPangoFont{.cdecl, 
    dynlib: pangolib, importc: "pango_font_map_load_font".}
proc pango_font_map_load_fontset*(fontmap: PPangoFontMap, 
                                  context: PPangoContext, 
                                  desc: PPangoFontDescription, 
                                  language: PPangoLanguage): PPangoFontset{.
    cdecl, dynlib: pangolib, importc: "pango_font_map_load_fontset".}
proc pango_font_map_list_families*(fontmap: PPangoFontMap, 
                                   families: var openarray[ptr PPangoFontFamily]){.cdecl, 
    dynlib: pangolib, importc: "pango_font_map_list_families".}
const 
  bm_TPangoGlyphVisAttr_is_cluster_start* = 0x00000001
  bp_TPangoGlyphVisAttr_is_cluster_start* = 0

proc is_cluster_start*(a: var TPangoGlyphVisAttr): guint
proc set_is_cluster_start*(a: var TPangoGlyphVisAttr, `is_cluster_start`: guint)
proc PANGO_TYPE_GLYPH_STRING*(): GType
proc pango_glyph_string_new*(): PPangoGlyphString{.cdecl, dynlib: pangolib, 
    importc: "pango_glyph_string_new".}
proc pango_glyph_string_set_size*(`string`: PPangoGlyphString, new_len: gint){.
    cdecl, dynlib: pangolib, importc: "pango_glyph_string_set_size".}
proc pango_glyph_string_get_type*(): GType{.cdecl, dynlib: pangolib, 
    importc: "pango_glyph_string_get_type".}
proc pango_glyph_string_copy*(`string`: PPangoGlyphString): PPangoGlyphString{.
    cdecl, dynlib: pangolib, importc: "pango_glyph_string_copy".}
proc pango_glyph_string_free*(`string`: PPangoGlyphString){.cdecl, 
    dynlib: pangolib, importc: "pango_glyph_string_free".}
proc pango_glyph_string_extents*(glyphs: PPangoGlyphString, font: PPangoFont, 
                                 ink_rect: PPangoRectangle, 
                                 logical_rect: PPangoRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_glyph_string_extents".}
proc pango_glyph_string_extents_range*(glyphs: PPangoGlyphString, start: int32, 
                                       theEnd: int32, font: PPangoFont, 
                                       ink_rect: PPangoRectangle, 
                                       logical_rect: PPangoRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_glyph_string_extents_range".}
proc pango_glyph_string_get_logical_widths*(glyphs: PPangoGlyphString, 
    text: cstring, length: int32, embedding_level: int32, 
    logical_widths: var int32){.cdecl, dynlib: pangolib, 
                               importc: "pango_glyph_string_get_logical_widths".}
proc pango_glyph_string_index_to_x*(glyphs: PPangoGlyphString, text: cstring, 
                                    length: int32, analysis: PPangoAnalysis, 
                                    index: int32, trailing: gboolean, 
                                    x_pos: var int32){.cdecl, dynlib: pangolib, 
    importc: "pango_glyph_string_index_to_x".}
proc pango_glyph_string_x_to_index*(glyphs: PPangoGlyphString, text: cstring, 
                                    length: int32, analysis: PPangoAnalysis, 
                                    x_pos: int32, index, 
                                    trailing: var int32){.cdecl, 
    dynlib: pangolib, importc: "pango_glyph_string_x_to_index".}
proc pango_shape*(text: cstring, length: gint, analysis: PPangoAnalysis, 
                  glyphs: PPangoGlyphString){.cdecl, dynlib: pangolib, 
    importc: "pango_shape".}
proc pango_reorder_items*(logical_items: PGList): PGList{.cdecl, 
    dynlib: pangolib, importc: "pango_reorder_items".}
proc pango_item_new*(): PPangoItem{.cdecl, dynlib: pangolib, 
                                    importc: "pango_item_new".}
proc pango_item_copy*(item: PPangoItem): PPangoItem{.cdecl, dynlib: pangolib, 
    importc: "pango_item_copy".}
proc pango_item_free*(item: PPangoItem){.cdecl, dynlib: pangolib, 
    importc: "pango_item_free".}
proc pango_item_split*(orig: PPangoItem, split_index: int32, split_offset: int32): PPangoItem{.
    cdecl, dynlib: pangolib, importc: "pango_item_split".}
proc PANGO_TYPE_LAYOUT*(): GType
proc PANGO_LAYOUT*(anObject: pointer): PPangoLayout
proc PANGO_LAYOUT_CLASS*(klass: pointer): PPangoLayoutClass
proc PANGO_IS_LAYOUT*(anObject: pointer): bool
proc PANGO_IS_LAYOUT_CLASS*(klass: pointer): bool
proc PANGO_LAYOUT_GET_CLASS*(obj: PPangoLayout): PPangoLayoutClass
proc pango_layout_get_type*(): GType{.cdecl, dynlib: pangolib, 
                                      importc: "pango_layout_get_type".}
proc pango_layout_new*(context: PPangoContext): PPangoLayout{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_new".}
proc pango_layout_copy*(src: PPangoLayout): PPangoLayout{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_copy".}
proc pango_layout_get_context*(layout: PPangoLayout): PPangoContext{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_context".}
proc pango_layout_set_attributes*(layout: PPangoLayout, attrs: PPangoAttrList){.
    cdecl, dynlib: pangolib, importc: "pango_layout_set_attributes".}
proc pango_layout_get_attributes*(layout: PPangoLayout): PPangoAttrList{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_attributes".}
proc pango_layout_set_text*(layout: PPangoLayout, text: cstring, length: int32){.
    cdecl, dynlib: pangolib, importc: "pango_layout_set_text".}
proc pango_layout_get_text*(layout: PPangoLayout): cstring{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_text".}
proc pango_layout_set_markup*(layout: PPangoLayout, markup: cstring, 
                              length: int32){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_set_markup".}
proc pango_layout_set_markup_with_accel*(layout: PPangoLayout, markup: cstring, 
    length: int32, accel_marker: gunichar, accel_char: Pgunichar){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_markup_with_accel".}
proc pango_layout_set_font_description*(layout: PPangoLayout, 
                                        desc: PPangoFontDescription){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_font_description".}
proc pango_layout_set_width*(layout: PPangoLayout, width: int32){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_width".}
proc pango_layout_get_width*(layout: PPangoLayout): int32{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_width".}
proc pango_layout_set_wrap*(layout: PPangoLayout, wrap: TPangoWrapMode){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_wrap".}
proc pango_layout_get_wrap*(layout: PPangoLayout): TPangoWrapMode{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_wrap".}
proc pango_layout_set_indent*(layout: PPangoLayout, indent: int32){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_indent".}
proc pango_layout_get_indent*(layout: PPangoLayout): int32{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_indent".}
proc pango_layout_set_spacing*(layout: PPangoLayout, spacing: int32){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_spacing".}
proc pango_layout_get_spacing*(layout: PPangoLayout): int32{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_spacing".}
proc pango_layout_set_justify*(layout: PPangoLayout, justify: gboolean){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_justify".}
proc pango_layout_get_justify*(layout: PPangoLayout): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_justify".}
proc pango_layout_set_alignment*(layout: PPangoLayout, 
                                 alignment: TPangoAlignment){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_alignment".}
proc pango_layout_get_alignment*(layout: PPangoLayout): TPangoAlignment{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_alignment".}
proc pango_layout_set_tabs*(layout: PPangoLayout, tabs: PPangoTabArray){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_set_tabs".}
proc pango_layout_get_tabs*(layout: PPangoLayout): PPangoTabArray{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_tabs".}
proc pango_layout_set_single_paragraph_mode*(layout: PPangoLayout, 
    setting: gboolean){.cdecl, dynlib: pangolib, 
                        importc: "pango_layout_set_single_paragraph_mode".}
proc pango_layout_get_single_paragraph_mode*(layout: PPangoLayout): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_layout_get_single_paragraph_mode".}
proc pango_layout_context_changed*(layout: PPangoLayout){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_context_changed".}
proc pango_layout_get_log_attrs*(layout: PPangoLayout, attrs: var PPangoLogAttr, 
                                 n_attrs: Pgint){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_get_log_attrs".}
proc pango_layout_index_to_pos*(layout: PPangoLayout, index: int32, 
                                pos: PPangoRectangle){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_index_to_pos".}
proc pango_layout_get_cursor_pos*(layout: PPangoLayout, index: int32, 
                                  strong_pos: PPangoRectangle, 
                                  weak_pos: PPangoRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_cursor_pos".}
proc pango_layout_move_cursor_visually*(layout: PPangoLayout, strong: gboolean, 
                                        old_index: int32, old_trailing: int32, 
                                        direction: int32, new_index, 
                                        new_trailing: var int32){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_move_cursor_visually".}
proc pango_layout_xy_to_index*(layout: PPangoLayout, x: int32, y: int32, 
                               index, trailing: var int32): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_layout_xy_to_index".}
proc pango_layout_get_extents*(layout: PPangoLayout, ink_rect: PPangoRectangle, 
                               logical_rect: PPangoRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_extents".}
proc pango_layout_get_pixel_extents*(layout: PPangoLayout, 
                                     ink_rect: PPangoRectangle, 
                                     logical_rect: PPangoRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_pixel_extents".}
proc pango_layout_get_size*(layout: PPangoLayout, width: var int32, 
                            height: var int32){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_get_size".}
proc pango_layout_get_pixel_size*(layout: PPangoLayout, width: var int32, 
                                  height: var int32){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_get_pixel_size".}
proc pango_layout_get_line_count*(layout: PPangoLayout): int32{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_line_count".}
proc pango_layout_get_line*(layout: PPangoLayout, line: int32): PPangoLayoutLine{.
    cdecl, dynlib: pangolib, importc: "pango_layout_get_line".}
proc pango_layout_get_lines*(layout: PPangoLayout): PGSList{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_lines".}
proc pango_layout_line_ref*(line: PPangoLayoutLine){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_line_ref".}
proc pango_layout_line_unref*(line: PPangoLayoutLine){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_line_unref".}
proc pango_layout_line_x_to_index*(line: PPangoLayoutLine, x_pos: int32, 
                                   index: var int32, trailing: var int32): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_layout_line_x_to_index".}
proc pango_layout_line_index_to_x*(line: PPangoLayoutLine, index: int32, 
                                   trailing: gboolean, x_pos: var int32){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_line_index_to_x".}
proc pango_layout_line_get_extents*(line: PPangoLayoutLine, 
                                    ink_rect: PPangoRectangle, 
                                    logical_rect: PPangoRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_line_get_extents".}
proc pango_layout_line_get_pixel_extents*(layout_line: PPangoLayoutLine, 
    ink_rect: PPangoRectangle, logical_rect: PPangoRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_line_get_pixel_extents".}
proc pango_layout_get_iter*(layout: PPangoLayout): PPangoLayoutIter{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_get_iter".}
proc pango_layout_iter_free*(iter: PPangoLayoutIter){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_iter_free".}
proc pango_layout_iter_get_index*(iter: PPangoLayoutIter): int32{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_get_index".}
proc pango_layout_iter_get_run*(iter: PPangoLayoutIter): PPangoLayoutRun{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_get_run".}
proc pango_layout_iter_get_line*(iter: PPangoLayoutIter): PPangoLayoutLine{.
    cdecl, dynlib: pangolib, importc: "pango_layout_iter_get_line".}
proc pango_layout_iter_at_last_line*(iter: PPangoLayoutIter): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_at_last_line".}
proc pango_layout_iter_next_char*(iter: PPangoLayoutIter): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_next_char".}
proc pango_layout_iter_next_cluster*(iter: PPangoLayoutIter): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_next_cluster".}
proc pango_layout_iter_next_run*(iter: PPangoLayoutIter): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_next_run".}
proc pango_layout_iter_next_line*(iter: PPangoLayoutIter): gboolean{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_next_line".}
proc pango_layout_iter_get_char_extents*(iter: PPangoLayoutIter, 
    logical_rect: PPangoRectangle){.cdecl, dynlib: pangolib, importc: "pango_layout_iter_get_char_extents".}
proc pango_layout_iter_get_cluster_extents*(iter: PPangoLayoutIter, 
    ink_rect: PPangoRectangle, logical_rect: PPangoRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_get_cluster_extents".}
proc pango_layout_iter_get_run_extents*(iter: PPangoLayoutIter, 
                                        ink_rect: PPangoRectangle, 
                                        logical_rect: PPangoRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_get_run_extents".}
proc pango_layout_iter_get_line_extents*(iter: PPangoLayoutIter, 
    ink_rect: PPangoRectangle, logical_rect: PPangoRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_get_line_extents".}
proc pango_layout_iter_get_line_yrange*(iter: PPangoLayoutIter, y0: var int32, 
                                        y1: var int32){.cdecl, dynlib: pangolib, 
    importc: "pango_layout_iter_get_line_yrange".}
proc pango_layout_iter_get_layout_extents*(iter: PPangoLayoutIter, 
    ink_rect: PPangoRectangle, logical_rect: PPangoRectangle){.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_get_layout_extents".}
proc pango_layout_iter_get_baseline*(iter: PPangoLayoutIter): int32{.cdecl, 
    dynlib: pangolib, importc: "pango_layout_iter_get_baseline".}
proc PANGO_TYPE_TAB_ARRAY*(): GType
proc pango_tab_array_new*(initial_size: gint, positions_in_pixels: gboolean): PPangoTabArray{.
    cdecl, dynlib: pangolib, importc: "pango_tab_array_new".}
proc pango_tab_array_get_type*(): GType{.cdecl, dynlib: pangolib, 
    importc: "pango_tab_array_get_type".}
proc pango_tab_array_copy*(src: PPangoTabArray): PPangoTabArray{.cdecl, 
    dynlib: pangolib, importc: "pango_tab_array_copy".}
proc pango_tab_array_free*(tab_array: PPangoTabArray){.cdecl, dynlib: pangolib, 
    importc: "pango_tab_array_free".}
proc pango_tab_array_get_size*(tab_array: PPangoTabArray): gint{.cdecl, 
    dynlib: pangolib, importc: "pango_tab_array_get_size".}
proc pango_tab_array_resize*(tab_array: PPangoTabArray, new_size: gint){.cdecl, 
    dynlib: pangolib, importc: "pango_tab_array_resize".}
proc pango_tab_array_set_tab*(tab_array: PPangoTabArray, tab_index: gint, 
                              alignment: TPangoTabAlign, location: gint){.cdecl, 
    dynlib: pangolib, importc: "pango_tab_array_set_tab".}
proc pango_tab_array_get_tab*(tab_array: PPangoTabArray, tab_index: gint, 
                              alignment: PPangoTabAlign, location: Pgint){.
    cdecl, dynlib: pangolib, importc: "pango_tab_array_get_tab".}
proc pango_tab_array_get_positions_in_pixels*(tab_array: PPangoTabArray): gboolean{.
    cdecl, dynlib: pangolib, importc: "pango_tab_array_get_positions_in_pixels".}
proc PANGO_ASCENT*(rect: TPangoRectangle): int32 = 
  result = - int(rect.y)

proc PANGO_DESCENT*(rect: TPangoRectangle): int32 = 
  result = int(rect.y) + int(rect.height)

proc PANGO_LBEARING*(rect: TPangoRectangle): int32 = 
  result = rect.x

proc PANGO_RBEARING*(rect: TPangoRectangle): int32 = 
  result = int(rect.x) + (rect.width)

proc PANGO_TYPE_LANGUAGE*(): GType = 
  result = pango_language_get_type()

proc pango_language_to_string*(language: PPangoLanguage): cstring = 
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

proc is_line_break*(a: var TPangoLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_line_break) shr
      bp_TPangoLogAttr_is_line_break

proc set_is_line_break*(a: var TPangoLogAttr, `is_line_break`: guint) = 
  a.flag0 = a.flag0 or
      ((`is_line_break` shl bp_TPangoLogAttr_is_line_break) and
      bm_TPangoLogAttr_is_line_break)

proc is_mandatory_break*(a: var TPangoLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_mandatory_break) shr
      bp_TPangoLogAttr_is_mandatory_break

proc set_is_mandatory_break*(a: var TPangoLogAttr, `is_mandatory_break`: guint) = 
  a.flag0 = a.flag0 or
      ((`is_mandatory_break` shl bp_TPangoLogAttr_is_mandatory_break) and
      bm_TPangoLogAttr_is_mandatory_break)

proc is_char_break*(a: var TPangoLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_char_break) shr
      bp_TPangoLogAttr_is_char_break

proc set_is_char_break*(a: var TPangoLogAttr, `is_char_break`: guint) = 
  a.flag0 = a.flag0 or
      ((`is_char_break` shl bp_TPangoLogAttr_is_char_break) and
      bm_TPangoLogAttr_is_char_break)

proc is_white*(a: var TPangoLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_white) shr
      bp_TPangoLogAttr_is_white

proc set_is_white*(a: var TPangoLogAttr, `is_white`: guint) = 
  a.flag0 = a.flag0 or
      ((`is_white` shl bp_TPangoLogAttr_is_white) and
      bm_TPangoLogAttr_is_white)

proc is_cursor_position*(a: var TPangoLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_cursor_position) shr
      bp_TPangoLogAttr_is_cursor_position

proc set_is_cursor_position*(a: var TPangoLogAttr, `is_cursor_position`: guint) = 
  a.flag0 = a.flag0 or
      ((`is_cursor_position` shl bp_TPangoLogAttr_is_cursor_position) and
      bm_TPangoLogAttr_is_cursor_position)

proc is_word_start*(a: var TPangoLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_word_start) shr
      bp_TPangoLogAttr_is_word_start

proc set_is_word_start*(a: var TPangoLogAttr, `is_word_start`: guint) = 
  a.flag0 = a.flag0 or
      ((`is_word_start` shl bp_TPangoLogAttr_is_word_start) and
      bm_TPangoLogAttr_is_word_start)

proc is_word_end*(a: var TPangoLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_word_end) shr
      bp_TPangoLogAttr_is_word_end

proc set_is_word_end*(a: var TPangoLogAttr, `is_word_end`: guint) = 
  a.flag0 = a.flag0 or
      ((`is_word_end` shl bp_TPangoLogAttr_is_word_end) and
      bm_TPangoLogAttr_is_word_end)

proc is_sentence_boundary*(a: var TPangoLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_sentence_boundary) shr
      bp_TPangoLogAttr_is_sentence_boundary

proc set_is_sentence_boundary*(a: var TPangoLogAttr, 
                               `is_sentence_boundary`: guint) = 
  a.flag0 = a.flag0 or
      ((`is_sentence_boundary` shl bp_TPangoLogAttr_is_sentence_boundary) and
      bm_TPangoLogAttr_is_sentence_boundary)

proc is_sentence_start*(a: var TPangoLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_sentence_start) shr
      bp_TPangoLogAttr_is_sentence_start

proc set_is_sentence_start*(a: var TPangoLogAttr, `is_sentence_start`: guint) = 
  a.flag0 = a.flag0 or
      ((`is_sentence_start` shl bp_TPangoLogAttr_is_sentence_start) and
      bm_TPangoLogAttr_is_sentence_start)

proc is_sentence_end*(a: var TPangoLogAttr): guint = 
  result = (a.flag0 and bm_TPangoLogAttr_is_sentence_end) shr
      bp_TPangoLogAttr_is_sentence_end

proc set_is_sentence_end*(a: var TPangoLogAttr, `is_sentence_end`: guint) = 
  a.flag0 = a.flag0 or
      ((`is_sentence_end` shl bp_TPangoLogAttr_is_sentence_end) and
      bm_TPangoLogAttr_is_sentence_end)

proc PANGO_TYPE_CONTEXT*(): GType = 
  result = pango_context_get_type()

proc PANGO_CONTEXT*(anObject: pointer): PPangoContext = 
  result = cast[PPangoContext](G_TYPE_CHECK_INSTANCE_CAST(anObject, PANGO_TYPE_CONTEXT()))

proc PANGO_CONTEXT_CLASS*(klass: pointer): PPangoContextClass = 
  result = cast[PPangoContextClass](G_TYPE_CHECK_CLASS_CAST(klass, PANGO_TYPE_CONTEXT()))

proc PANGO_IS_CONTEXT*(anObject: pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_CONTEXT())

proc PANGO_IS_CONTEXT_CLASS*(klass: pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, PANGO_TYPE_CONTEXT())

proc PANGO_CONTEXT_GET_CLASS*(obj: PPangoContext): PPangoContextClass = 
  result = cast[PPangoContextClass](G_TYPE_INSTANCE_GET_CLASS(obj, PANGO_TYPE_CONTEXT()))

proc PANGO_TYPE_FONTSET*(): GType = 
  result = pango_fontset_get_type()

proc PANGO_FONTSET*(anObject: pointer): PPangoFontset = 
  result = cast[PPangoFontset](G_TYPE_CHECK_INSTANCE_CAST(anObject, PANGO_TYPE_FONTSET()))

proc PANGO_IS_FONTSET*(anObject: pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_FONTSET())

proc PANGO_FONTSET_CLASS*(klass: pointer): PPangoFontsetClass = 
  result = cast[PPangoFontsetClass](G_TYPE_CHECK_CLASS_CAST(klass, PANGO_TYPE_FONTSET()))

proc PANGO_IS_FONTSET_CLASS*(klass: pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, PANGO_TYPE_FONTSET())

proc PANGO_FONTSET_GET_CLASS*(obj: PPangoFontset): PPangoFontsetClass = 
  result = cast[PPangoFontsetClass](G_TYPE_INSTANCE_GET_CLASS(obj, PANGO_TYPE_FONTSET()))

proc pango_fontset_simple_get_type(): GType {.importc, cdecl, dynlib: pangolib.}

proc PANGO_TYPE_FONTSET_SIMPLE*(): GType = 
  result = pango_fontset_simple_get_type()

proc PANGO_FONTSET_SIMPLE*(anObject: pointer): PPangoFontsetSimple = 
  result = cast[PPangoFontsetSimple](G_TYPE_CHECK_INSTANCE_CAST(anObject, 
      PANGO_TYPE_FONTSET_SIMPLE()))

proc PANGO_IS_FONTSET_SIMPLE*(anObject: pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_FONTSET_SIMPLE())

proc PANGO_TYPE_FONT_DESCRIPTION*(): GType = 
  result = pango_font_description_get_type()

proc PANGO_TYPE_FONT_METRICS*(): GType = 
  result = pango_font_metrics_get_type()

proc PANGO_TYPE_FONT_FAMILY*(): GType = 
  result = pango_font_family_get_type()

proc PANGO_FONT_FAMILY*(anObject: pointer): PPangoFontFamily = 
  result = cast[PPangoFontFamily](G_TYPE_CHECK_INSTANCE_CAST(anObject, 
      PANGO_TYPE_FONT_FAMILY()))

proc PANGO_IS_FONT_FAMILY*(anObject: Pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_FONT_FAMILY())

proc PANGO_FONT_FAMILY_CLASS*(klass: Pointer): PPangoFontFamilyClass = 
  result = cast[PPangoFontFamilyClass](G_TYPE_CHECK_CLASS_CAST(klass, 
      PANGO_TYPE_FONT_FAMILY()))

proc PANGO_IS_FONT_FAMILY_CLASS*(klass: Pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, PANGO_TYPE_FONT_FAMILY())

proc PANGO_FONT_FAMILY_GET_CLASS*(obj: PPangoFontFamily): PPangoFontFamilyClass = 
  result = cast[PPangoFontFamilyClass](G_TYPE_INSTANCE_GET_CLASS(obj, 
      PANGO_TYPE_FONT_FAMILY()))

proc PANGO_TYPE_FONT_FACE*(): GType = 
  result = pango_font_face_get_type()

proc PANGO_FONT_FACE*(anObject: Pointer): PPangoFontFace = 
  result = cast[PPangoFontFace](G_TYPE_CHECK_INSTANCE_CAST(anObject, 
      PANGO_TYPE_FONT_FACE()))

proc PANGO_IS_FONT_FACE*(anObject: Pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_FONT_FACE())

proc PANGO_FONT_FACE_CLASS*(klass: Pointer): PPangoFontFaceClass = 
  result = cast[PPangoFontFaceClass](G_TYPE_CHECK_CLASS_CAST(klass, 
      PANGO_TYPE_FONT_FACE()))

proc PANGO_IS_FONT_FACE_CLASS*(klass: Pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, PANGO_TYPE_FONT_FACE())

proc PANGO_FONT_FACE_GET_CLASS*(obj: Pointer): PPangoFontFaceClass = 
  result = cast[PPangoFontFaceClass](G_TYPE_INSTANCE_GET_CLASS(obj, 
      PANGO_TYPE_FONT_FACE()))

proc PANGO_TYPE_FONT*(): GType = 
  result = pango_font_get_type()

proc PANGO_FONT*(anObject: Pointer): PPangoFont = 
  result = cast[PPangoFont](G_TYPE_CHECK_INSTANCE_CAST(anObject, PANGO_TYPE_FONT()))

proc PANGO_IS_FONT*(anObject: Pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_FONT())

proc PANGO_FONT_CLASS*(klass: Pointer): PPangoFontClass = 
  result = cast[PPangoFontClass](G_TYPE_CHECK_CLASS_CAST(klass, PANGO_TYPE_FONT()))

proc PANGO_IS_FONT_CLASS*(klass: Pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, PANGO_TYPE_FONT())

proc PANGO_FONT_GET_CLASS*(obj: PPangoFont): PPangoFontClass = 
  result = cast[PPangoFontClass](G_TYPE_INSTANCE_GET_CLASS(obj, PANGO_TYPE_FONT()))

proc PANGO_TYPE_FONT_MAP*(): GType = 
  result = pango_font_map_get_type()

proc PANGO_FONT_MAP*(anObject: pointer): PPangoFontmap = 
  result = cast[PPangoFontmap](G_TYPE_CHECK_INSTANCE_CAST(anObject, 
      PANGO_TYPE_FONT_MAP()))

proc PANGO_IS_FONT_MAP*(anObject: pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_FONT_MAP())

proc PANGO_FONT_MAP_CLASS*(klass: pointer): PPangoFontMapClass = 
  result = cast[PPangoFontMapClass](G_TYPE_CHECK_CLASS_CAST(klass, PANGO_TYPE_FONT_MAP()))

proc PANGO_IS_FONT_MAP_CLASS*(klass: pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, PANGO_TYPE_FONT_MAP())

proc PANGO_FONT_MAP_GET_CLASS*(obj: PPangoFontMap): PPangoFontMapClass = 
  result = cast[PPangoFontMapClass](G_TYPE_INSTANCE_GET_CLASS(obj, PANGO_TYPE_FONT_MAP()))

proc is_cluster_start*(a: var TPangoGlyphVisAttr): guint = 
  result = (a.flag0 and bm_TPangoGlyphVisAttr_is_cluster_start) shr
      bp_TPangoGlyphVisAttr_is_cluster_start

proc set_is_cluster_start*(a: var TPangoGlyphVisAttr, `is_cluster_start`: guint) = 
  a.flag0 = a.flag0 or
      ((`is_cluster_start` shl bp_TPangoGlyphVisAttr_is_cluster_start) and
      bm_TPangoGlyphVisAttr_is_cluster_start)

proc PANGO_TYPE_GLYPH_STRING*(): GType = 
  result = pango_glyph_string_get_type()

proc PANGO_TYPE_LAYOUT*(): GType = 
  result = pango_layout_get_type()

proc PANGO_LAYOUT*(anObject: pointer): PPangoLayout = 
  result = cast[PPangoLayout](G_TYPE_CHECK_INSTANCE_CAST(anObject, PANGO_TYPE_LAYOUT()))

proc PANGO_LAYOUT_CLASS*(klass: pointer): PPangoLayoutClass = 
  result = cast[PPangoLayoutClass](G_TYPE_CHECK_CLASS_CAST(klass, PANGO_TYPE_LAYOUT()))

proc PANGO_IS_LAYOUT*(anObject: pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, PANGO_TYPE_LAYOUT())

proc PANGO_IS_LAYOUT_CLASS*(klass: pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, PANGO_TYPE_LAYOUT())

proc PANGO_LAYOUT_GET_CLASS*(obj: PPangoLayout): PPangoLayoutClass = 
  result = cast[PPangoLayoutClass](G_TYPE_INSTANCE_GET_CLASS(obj, PANGO_TYPE_LAYOUT()))

proc PANGO_TYPE_TAB_ARRAY*(): GType = 
  result = pango_tab_array_get_type()
