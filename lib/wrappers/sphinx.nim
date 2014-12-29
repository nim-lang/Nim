#
# $Id: sphinxclient.h 2654 2011-01-31 01:20:58Z kevg $
#
#
# Copyright (c) 2001-2011, Andrew Aksyonoff
# Copyright (c) 2008-2011, Sphinx Technologies Inc
# All rights reserved
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Library General Public License. You should
# have received a copy of the LGPL license along with this program; if you
# did not, you can find it at http://www.gnu.org/
#

## Nim wrapper for ``sphinx``.

{.deadCodeElim: on.}
when defined(windows):
  const
    sphinxDll* = "spinx.dll"
elif defined(macosx):
  const
    sphinxDll* = "libspinx.dylib"
else:
  const
    sphinxDll* = "libspinxclient.so"

#/ known searchd status codes:
const
  SEARCHD_OK* = 0
  SEARCHD_ERROR* = 1
  SEARCHD_RETRY* = 2
  SEARCHD_WARNING* = 3

#/ known match modes

const
  SPH_MATCH_ALL* = 0
  SPH_MATCH_ANY* = 1
  SPH_MATCH_PHRASE* = 2
  SPH_MATCH_BOOLEAN* = 3
  SPH_MATCH_EXTENDED* = 4
  SPH_MATCH_FULLSCAN* = 5
  SPH_MATCH_EXTENDED2* = 6

#/ known ranking modes (ext2 only)

const
  SPH_RANK_PROXIMITY_BM25* = 0
  SPH_RANK_BM25* = 1
  SPH_RANK_NONE* = 2
  SPH_RANK_WORDCOUNT* = 3
  SPH_RANK_PROXIMITY* = 4
  SPH_RANK_MATCHANY* = 5
  SPH_RANK_FIELDMASK* = 6
  SPH_RANK_SPH04* = 7
  SPH_RANK_DEFAULT* = SPH_RANK_PROXIMITY_BM25

#/ known sort modes

const
  SPH_SORT_RELEVANCE* = 0
  SPH_SORT_ATTR_DESC* = 1
  SPH_SORT_ATTR_ASC* = 2
  SPH_SORT_TIME_SEGMENTS* = 3
  SPH_SORT_EXTENDED* = 4
  SPH_SORT_EXPR* = 5

#/ known filter types

const
  SPH_FILTER_VALUES* = 0
  SPH_FILTER_RANGE* = 1
  SPH_FILTER_FLOATRANGE* = 2

#/ known attribute types

const
  SPH_ATTR_INTEGER* = 1
  SPH_ATTR_TIMESTAMP* = 2
  SPH_ATTR_ORDINAL* = 3
  SPH_ATTR_BOOL* = 4
  SPH_ATTR_FLOAT* = 5
  SPH_ATTR_BIGINT* = 6
  SPH_ATTR_STRING* = 7
  SPH_ATTR_MULTI* = 0x40000000

#/ known grouping functions

const
  SPH_GROUPBY_DAY* = 0
  SPH_GROUPBY_WEEK* = 1
  SPH_GROUPBY_MONTH* = 2
  SPH_GROUPBY_YEAR* = 3
  SPH_GROUPBY_ATTR* = 4
  SPH_GROUPBY_ATTRPAIR* = 5

type
  TSphinxBool* {.size: sizeof(cint).} = enum
    SPH_FALSE = 0,
    SPH_TRUE = 1

  Tclient {.pure, final.} = object
  PClient* = ptr TClient
  Twordinfo*{.pure, final.} = object
    word*: cstring
    docs*: cint
    hits*: cint

  Tresult*{.pure, final.} = object
    error*: cstring
    warning*: cstring
    status*: cint
    num_fields*: cint
    fields*: cstringArray
    num_attrs*: cint
    attr_names*: cstringArray
    attr_types*: ptr array [0..100_000, cint]
    num_matches*: cint
    values_pool*: pointer
    total*: cint
    total_found*: cint
    time_msec*: cint
    num_words*: cint
    words*: ptr array [0..100_000, TWordinfo]

  Texcerpt_options*{.pure, final.} = object
    before_match*: cstring
    after_match*: cstring
    chunk_separator*: cstring
    html_strip_mode*: cstring
    passage_boundary*: cstring
    limit*: cint
    limit_passages*: cint
    limit_words*: cint
    around*: cint
    start_passage_id*: cint
    exact_phrase*: TSphinxBool
    single_passage*: TSphinxBool
    use_boundaries*: TSphinxBool
    weight_order*: TSphinxBool
    query_mode*: TSphinxBool
    force_all_words*: TSphinxBool
    load_files*: TSphinxBool
    allow_empty*: TSphinxBool
    emit_zones*: TSphinxBool

  Tkeyword_info*{.pure, final.} = object
    tokenized*: cstring
    normalized*: cstring
    num_docs*: cint
    num_hits*: cint


proc create*(copy_args: TSphinxBool): PClient{.cdecl, importc: "sphinx_create",
    dynlib: sphinxDll.}
proc cleanup*(client: PClient){.cdecl, importc: "sphinx_cleanup",
                                    dynlib: sphinxDll.}
proc destroy*(client: PClient){.cdecl, importc: "sphinx_destroy",
                                    dynlib: sphinxDll.}
proc error*(client: PClient): cstring{.cdecl, importc: "sphinx_error",
    dynlib: sphinxDll.}
proc warning*(client: PClient): cstring{.cdecl, importc: "sphinx_warning",
    dynlib: sphinxDll.}
proc set_server*(client: PClient, host: cstring, port: cint): TSphinxBool{.cdecl,
    importc: "sphinx_set_server", dynlib: sphinxDll.}
proc set_connect_timeout*(client: PClient, seconds: float32): TSphinxBool{.cdecl,
    importc: "sphinx_set_connect_timeout", dynlib: sphinxDll.}
proc open*(client: PClient): TSphinxBool{.cdecl, importc: "sphinx_open",
                                        dynlib: sphinxDll.}
proc close*(client: PClient): TSphinxBool{.cdecl, importc: "sphinx_close",
    dynlib: sphinxDll.}
proc set_limits*(client: PClient, offset: cint, limit: cint,
                 max_matches: cint, cutoff: cint): TSphinxBool{.cdecl,
    importc: "sphinx_set_limits", dynlib: sphinxDll.}
proc set_max_query_time*(client: PClient, max_query_time: cint): TSphinxBool{.
    cdecl, importc: "sphinx_set_max_query_time", dynlib: sphinxDll.}
proc set_match_mode*(client: PClient, mode: cint): TSphinxBool{.cdecl,
    importc: "sphinx_set_match_mode", dynlib: sphinxDll.}
proc set_ranking_mode*(client: PClient, ranker: cint): TSphinxBool{.cdecl,
    importc: "sphinx_set_ranking_mode", dynlib: sphinxDll.}
proc set_sort_mode*(client: PClient, mode: cint, sortby: cstring): TSphinxBool{.
    cdecl, importc: "sphinx_set_sort_mode", dynlib: sphinxDll.}
proc set_field_weights*(client: PClient, num_weights: cint,
                        field_names: cstringArray, field_weights: ptr cint): TSphinxBool{.
    cdecl, importc: "sphinx_set_field_weights", dynlib: sphinxDll.}
proc set_index_weights*(client: PClient, num_weights: cint,
                        index_names: cstringArray, index_weights: ptr cint): TSphinxBool{.
    cdecl, importc: "sphinx_set_index_weights", dynlib: sphinxDll.}
proc set_id_range*(client: PClient, minid: int64, maxid: int64): TSphinxBool{.
    cdecl, importc: "sphinx_set_id_range", dynlib: sphinxDll.}
proc add_filter*(client: PClient, attr: cstring, num_values: cint,
                 values: ptr int64, exclude: TSphinxBool): TSphinxBool{.cdecl,
    importc: "sphinx_add_filter", dynlib: sphinxDll.}
proc add_filter_range*(client: PClient, attr: cstring, umin: int64,
                       umax: int64, exclude: TSphinxBool): TSphinxBool{.cdecl,
    importc: "sphinx_add_filter_range", dynlib: sphinxDll.}
proc add_filter_float_range*(client: PClient, attr: cstring, fmin: float32,
                             fmax: float32, exclude: TSphinxBool): TSphinxBool{.cdecl,
    importc: "sphinx_add_filter_float_range", dynlib: sphinxDll.}
proc set_geoanchor*(client: PClient, attr_latitude: cstring,
                    attr_longitude: cstring, latitude: float32, longitude: float32): TSphinxBool{.
    cdecl, importc: "sphinx_set_geoanchor", dynlib: sphinxDll.}
proc set_groupby*(client: PClient, attr: cstring, groupby_func: cint,
                  group_sort: cstring): TSphinxBool{.cdecl,
    importc: "sphinx_set_groupby", dynlib: sphinxDll.}
proc set_groupby_distinct*(client: PClient, attr: cstring): TSphinxBool{.cdecl,
    importc: "sphinx_set_groupby_distinct", dynlib: sphinxDll.}
proc set_retries*(client: PClient, count: cint, delay: cint): TSphinxBool{.cdecl,
    importc: "sphinx_set_retries", dynlib: sphinxDll.}
proc add_override*(client: PClient, attr: cstring, docids: ptr int64,
                   num_values: cint, values: ptr cint): TSphinxBool{.cdecl,
    importc: "sphinx_add_override", dynlib: sphinxDll.}
proc set_select*(client: PClient, select_list: cstring): TSphinxBool{.cdecl,
    importc: "sphinx_set_select", dynlib: sphinxDll.}
proc reset_filters*(client: PClient){.cdecl,
    importc: "sphinx_reset_filters", dynlib: sphinxDll.}
proc reset_groupby*(client: PClient){.cdecl,
    importc: "sphinx_reset_groupby", dynlib: sphinxDll.}
proc query*(client: PClient, query: cstring, index_list: cstring,
            comment: cstring): ptr Tresult{.cdecl, importc: "sphinx_query",
    dynlib: sphinxDll.}
proc add_query*(client: PClient, query: cstring, index_list: cstring,
                comment: cstring): cint{.cdecl, importc: "sphinx_add_query",
    dynlib: sphinxDll.}
proc run_queries*(client: PClient): ptr Tresult{.cdecl,
    importc: "sphinx_run_queries", dynlib: sphinxDll.}
proc get_num_results*(client: PClient): cint{.cdecl,
    importc: "sphinx_get_num_results", dynlib: sphinxDll.}
proc get_id*(result: ptr Tresult, match: cint): int64{.cdecl,
    importc: "sphinx_get_id", dynlib: sphinxDll.}
proc get_weight*(result: ptr Tresult, match: cint): cint{.cdecl,
    importc: "sphinx_get_weight", dynlib: sphinxDll.}
proc get_int*(result: ptr Tresult, match: cint, attr: cint): int64{.cdecl,
    importc: "sphinx_get_int", dynlib: sphinxDll.}
proc get_float*(result: ptr Tresult, match: cint, attr: cint): float32{.cdecl,
    importc: "sphinx_get_float", dynlib: sphinxDll.}
proc get_mva*(result: ptr Tresult, match: cint, attr: cint): ptr cint{.
    cdecl, importc: "sphinx_get_mva", dynlib: sphinxDll.}
proc get_string*(result: ptr Tresult, match: cint, attr: cint): cstring{.cdecl,
    importc: "sphinx_get_string", dynlib: sphinxDll.}
proc init_excerpt_options*(opts: ptr Texcerpt_options){.cdecl,
    importc: "sphinx_init_excerpt_options", dynlib: sphinxDll.}
proc build_excerpts*(client: PClient, num_docs: cint, docs: cstringArray,
                     index: cstring, words: cstring, opts: ptr Texcerpt_options): cstringArray{.
    cdecl, importc: "sphinx_build_excerpts", dynlib: sphinxDll.}
proc update_attributes*(client: PClient, index: cstring, num_attrs: cint,
                        attrs: cstringArray, num_docs: cint,
                        docids: ptr int64, values: ptr int64): cint{.
    cdecl, importc: "sphinx_update_attributes", dynlib: sphinxDll.}
proc update_attributes_mva*(client: PClient, index: cstring, attr: cstring,
                            docid: int64, num_values: cint,
                            values: ptr cint): cint{.cdecl,
    importc: "sphinx_update_attributes_mva", dynlib: sphinxDll.}
proc build_keywords*(client: PClient, query: cstring, index: cstring,
                     hits: TSphinxBool, out_num_keywords: ptr cint): ptr Tkeyword_info{.
    cdecl, importc: "sphinx_build_keywords", dynlib: sphinxDll.}
proc status*(client: PClient, num_rows: ptr cint, num_cols: ptr cint): cstringArray{.
    cdecl, importc: "sphinx_status", dynlib: sphinxDll.}
proc status_destroy*(status: cstringArray, num_rows: cint, num_cols: cint){.
    cdecl, importc: "sphinx_status_destroy", dynlib: sphinxDll.}
