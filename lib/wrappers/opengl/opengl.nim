#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module is a wrapper around `opengl`:idx:. If you define the symbol
## ``useGlew`` this wrapper does not use Nimrod's ``dynlib`` mechanism,
## but `glew`:idx: instead. However, this shouldn't be necessary anymore; even
## extension loading for the different operating systems is handled here.
##
## You need to call ``loadExtensions`` after a rendering context has been
## created to load any extension proc that your code uses.

when defined(linux):
  import X, XLib, XUtil
elif defined(windows):
  import winlean, os

when defined(windows):
  const
    ogldll* = "OpenGL32.dll"
    gludll* = "GLU32.dll"
elif defined(macosx):
  const
    ogldll* = "libGL.dylib"
    gludll* = "libGLU.dylib"
else:
  const
    ogldll* = "libGL.so.1"
    gludll* = "libGLU.so.1"

when defined(useGlew):
  {.pragma: ogl, header: "<GL/glew.h>".}
  {.pragma: oglx, header: "<GL/glxew.h>".}
  {.pragma: wgl, header: "<GL/wglew.h>".}
  {.pragma: glu, dynlib: gludll.}
else:
  # quite complex ... thanks to extension support for various platforms:
  import dynlib

  let oglHandle = LoadLib(ogldll)
  if isNil(oglHandle): quit("could not load: " & ogldll)

  when defined(windows):
    var wglGetProcAddress = cast[proc (s: cstring): pointer {.stdcall.}](
      symAddr(oglHandle, "wglGetProcAddress"))
  elif defined(linux):
    var glXGetProcAddress = cast[proc (s: cstring): pointer {.cdecl.}](
      symAddr(oglHandle, "glXGetProcAddress"))
    var glXGetProcAddressARB = cast[proc (s: cstring): pointer {.cdecl.}](
      symAddr(oglHandle, "glXGetProcAddressARB"))

  proc glGetProc(h: TLibHandle; procName: cstring): pointer =
    when defined(windows):
      result = symAddr(h, procname)
      if result != nil: return
      if not isNil(wglGetProcAddress): result = wglGetProcAddress(ProcName)
    elif defined(linux):
      if not isNil(glXGetProcAddress): result = glXGetProcAddress(ProcName)
      if result != nil: return
      if not isNil(glXGetProcAddressARB):
        result = glXGetProcAddressARB(ProcName)
        if result != nil: return
      result = symAddr(h, procname)
    else:
      result = symAddr(h, procName)
    if result == nil: raiseInvalidLibrary(procName)

  var gluHandle: TLibHandle

  proc gluGetProc(procname: cstring): pointer =
    if gluHandle == nil:
      gluHandle = LoadLib(gludll)
      if gluHandle == nil: quit("could not load: " & gludll)
    result = glGetProc(gluHandle, procname)

  # undocumented 'dynlib' feature: the string literal is replaced by
  # the imported proc name:
  {.pragma: ogl, dynlib: glGetProc(oglHandle, "0").}
  {.pragma: oglx, dynlib: glGetProc(oglHandle, "0").}
  {.pragma: wgl, dynlib: glGetProc(oglHandle, "0").}
  {.pragma: glu, dynlib: gluGetProc("").}

  proc nimLoadProcs0() {.importc.}

  template loadExtensions*() =
    ## call this after your rendering context has been setup if you use
    ## extensions.
    bind nimLoadProcs0
    nimLoadProcs0()

#==============================================================================
#
#       OpenGL 4.2 - Headertranslation
#       Version 4.2a
#       Date : 26.11.2011
#
#       Works with :
#        - Delphi 3 and up
#        - FreePascal (1.9.3 and up)
#
#==============================================================================
#
#       Containts the translations of glext.h, gl_1_1.h, glu.h and weglext.h.
#       It also contains some helperfunctions that were inspired by those
#       found in Mike Lischke's OpenGL12.pas.
#
#       Copyright (C) DGL-OpenGL2-Portteam
#       All Rights Reserved
#
#       Obtained through:
#       Delphi OpenGL Community(DGL) - www.delphigl.com
#
#       Converted and maintained by DGL's GL2.0-Team :
#         - Sascha Willems             - http://www.saschawillems.de
#         - Steffen Xonna (Lossy eX)   - http://www.dev-center.de
#       Additional input :
#         - Andrey Gruzdev (Mac OS X patch for XE2 / FPC)
#         - Lars Middendorf
#         - Martin Waldegger (Mars)
#         - Benjamin Rosseaux (BeRo)   - http://www.0ok.de
#       Additional thanks:
#           sigsegv (libdl.so)
#
#
#==============================================================================
# You may retrieve the latest version of this file at the Delphi OpenGL
# Community home page, located at http://www.delphigl.com/
#
# The contents of this file are used with permission, subject to
# the Mozilla Public License Version 1.1 (the "License"); you may
# not use this file except in compliance with the License. You may
# obtain a copy of the License at
# http://www.mozilla.org/MPL/MPL-1.1.html
#
# Software distributed under the License is distributed on an
# "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
#
#==============================================================================
# History :
# Version 1.0    Initial Release
# Version 1.1    Added PPointer in Tpyessection for compatiblity with Delphi
#                versions lower than 7                                    (SW)
#                Added a function named RaiseLastOSError including a comment
#                on how to make it run under Delphi versions lower than 7 (SW)
#                Added some data types according to the GL-Syntax         (SW)
# Version 1.2    Fixed some problems with getting the addresses of some
#                Extensions (e.g. glTexImage3D) where the EXT/ARB did work
#                but not the core-functions                               (SW)
# Version 1.3    A second call to ReadimplementationProperties won't
#                revert to the default libs anymore                       (MW)
#                Libraries now will be released if necessary              (MW)
# Version 1.3a   Small fixes for glSlang-functions                        (SW)
# Version 1.3b   Fixed a small bug with GL_ARB_shader_objects, that lead
#                lead to that extension not loaded correctly              (SW)
# Version 1.3c   more GL 1.5 compliance by FOG_COORD_xx and
#                ARB less VBO and occlusion query routines                (MW)
# Version 1.3d   Fixed linebreaks (should now be corrected under D5)      (SW)
# Version 1.4    Changed header to correspond to the OpenGL-Shading
#                Language specification 1.10 :
#                - Added new GL_SAMPLER*-Constants
#                - Added Constant GL_SHADING_LANGUAGE_VERSION_ARB
#                - Added Constant GL_FRAGMENT_SHADER_DERIVATIVE_HINT_ARB
#                - Added Constant GL_MAX_FRAGMENT_UNIFORM_COMPONENTS_ARB  (SW)
# Version 1.4a   Fixed a missing stdcall for glBindAttribLocationARB      (SW)
# Version 1.4b   Fixed declaration for glUniform*(f/i)vARB (added count)  (MW)
#                glCompileShaderARB changed from function to procedure    (MW)
# Version 1.5    Added support for FreePascal                             (BR)
#                Added type TGLVectorf3/TGLVector3f                       (SW)
# Version 1.6    Added Extension GL_EXT_framebuffer_object                (SX)
# Version 1.7    Added Extension GL_ARB_fragment_program_shadow           (SX)
#                Added Extension GL_ARB_draw_buffers                      (SX)
#                Added Extension GL_ARB_texture_rectangle                 (SX)
#                Added Extension GL_ARB_color_buffer_float                (SX)
#                Added Extension GL_ARB_half_float_pixel                  (SX)
#                Added Extension GL_ARB_texture_float                     (SX)
#                Added Extension GL_ARB_pixel_buffer_object               (SX)
#                Added Extension GL_EXT_depth_bounds_test                 (SX)
#                Added Extension GL_EXT_texture_mirror_clamp              (SX)
#                Added Extension GL_EXT_blend_equation_separate           (SX)
#                Added Extension GL_EXT_pixel_buffer_object               (SX)
#                Added Extension GL_EXT_texture_compression_dxt1          (SX)
#                Added Extension GL_NV_fragment_program_option            (SX)
#                Added Extension GL_NV_fragment_program2                  (SX)
#                Added Extension GL_NV_vertex_program2_option             (SX)
#                Added Extension GL_NV_vertex_program3                    (SX)
# Version 1.8    Added explicit delegate type definitions                 (LM)
#                Added .Net 1.1 Support                                   (LM)
#                Added .Net overloaded functions                          (LM)
#                Added delayed extension loading and stubs                (LM)
#                Added automatic InitOpenGL call in CreateRenderingContext(LM)
#                Added extra Read* function                              (LM)
# Version 2.0    fixed some Problem with version string and damn drivers.
#                String 1.15 identified as OpenGL 1.5 not as OpenGL 1.1   (SX)
#                Removed unexisting extension GL_ARB_texture_mirror_repeat(SX)
#                Added Extension WGL_ARB_pixel_format_float               (SX)
#                Added Extension GL_EXT_stencil_clear_tag                 (SX)
#                Added Extension GL_EXT_texture_rectangle                 (SX)
#                Added Extension GL_EXT_texture_edge_clamp                (SX)
#                Some 1.5 Core Consts added (now completed)               (SX)
#                gluProject need pointer for not .net                     (SX)
#                gluUnProject need pointer for not .net                   (SX)
#                wglUseFontOutlines* need pointer for not .net            (SX)
#                wglSwapMultipleBuffers need pointer for not .net         (SX)
#                Bug with wglGetExtensionsStringEXT removed
#                different type for .net                                  (SX)
#                Added OpenGL 2.0 Core                                    (SX)
# Version 2.0.1  fixed some problems with glGetActiveAttrib in 2.0 Core   (SX)
#                fixes some problems with gluProject                      (SX)
#                fixes some problems with gluUnProject                    (SX)
#                fixes some problems with gluTessVertex                   (SX)
#                fixes some problems with gluLoadSamplingMatrices         (SX)
# Version 2.1    Removed .NET Support                                     (SX)
#                Better support for Linux                                 (SX)
#                Better Codeformation                                     (SX)
#                Added some more Vector/Matrix types                      (SX)
#                Added OpenGL 2.1 Core                                    (SX)
#                Added Extension GL_EXT_packed_depth_stencil              (SX)
#                Added Extension GL_EXT_texture_sRGB                      (SX)
#                Added Extension GL_EXT_framebuffer_blit                  (SX)
#                Added Extension GL_EXT_framebuffer_multisample           (SX)
#                Added Extension GL_EXT_timer_query                       (SX)
#                Added Extension GL_EXT_gpu_program_parameters            (SX)
#                Added Extension GL_EXT_bindable_uniform                  (SX)
#                Added Extension GL_EXT_draw_buffers2                     (SX)
#                Added Extension GL_EXT_draw_instanced                    (SX)
#                Added Extension GL_EXT_framebuffer_sRGB                  (SX)
#                Added Extension GL_EXT_geometry_shader4                  (SX)
#                Added Extension GL_EXT_gpu_shader4                       (SX)
#                Added Extension GL_EXT_packed_float                      (SX)
#                Added Extension GL_EXT_texture_array                     (SX)
#                Added Extension GL_EXT_texture_buffer_object             (SX)
#                Added Extension GL_EXT_texture_compression_latc          (SX)
#                Added Extension GL_EXT_texture_compression_rgtc          (SX)
#                Added Extension GL_EXT_texture_integer                   (SX)
#                Added Extension GL_EXT_texture_shared_exponent           (SX)
#                Added Extension GL_NV_depth_buffer_float                 (SX)
#                Added Extension GL_NV_fragment_program4                  (SX)
#                Added Extension GL_NV_framebuffer_multisample_coverage   (SX)
#                Added Extension GL_NV_geometry_program4                  (SX)
#                Added Extension GL_NV_gpu_program4                       (SX)
#                Added Extension GL_NV_parameter_buffer_object            (SX)
#                Added Extension GL_NV_transform_feedback                 (SX)
#                Added Extension GL_NV_vertex_program4                    (SX)
# Version 3.0    fixed some const of GL_EXT_texture_shared_exponent       (SX)
#                possible better support for mac                          (SX)
#                Added OpenGL 3.0 Core                                    (SX)
#                Added Extension GL_ARB_depth_buffer_float                (SX)
#                Added Extension GL_ARB_draw_instanced                    (SX)
#                Added Extension GL_ARB_framebuffer_object                (SX)
#                Added Extension GL_ARB_framebuffer_sRGB                  (SX)
#                Added Extension GL_ARB_geometry_shader4                  (SX)
#                Added Extension GL_ARB_half_float_vertex                 (SX)
#                Added Extension GL_ARB_instanced_arrays                  (SX)
#                Added Extension GL_ARB_map_buffer_range                  (SX)
#                Added Extension GL_ARB_texture_buffer_object             (SX)
#                Added Extension GL_ARB_texture_compression_rgtc          (SX)
#                Added Extension GL_ARB_texture_rg                        (SX)
#                Added Extension GL_ARB_vertex_array_object               (SX)
#                Added Extension GL_NV_conditional_render                 (SX)
#                Added Extension GL_NV_present_video                      (SX)
#                Added Extension GL_EXT_transform_feedback                (SX)
#                Added Extension GL_EXT_direct_state_access               (SX)
#                Added Extension GL_EXT_vertex_array_bgra                 (SX)
#                Added Extension GL_EXT_texture_swizzle                   (SX)
#                Added Extension GL_NV_explicit_multisample               (SX)
#                Added Extension GL_NV_transform_feedback2                (SX)
#                Added Extension WGL_ARB_create_context                   (SX)
#                Added Extension WGL_NV_present_video                     (SX)
#                Added Extension WGL_NV_video_out                         (SX)
#                Added Extension WGL_NV_swap_group                        (SX)
#                Added Extension WGL_NV_gpu_affinity                      (SX)
#                Added define DGL_TINY_HEADER to suppress automatic
#                function loading                                         (SX)
#                glProcedure renamed to dglGetProcAddress and now it's
#                visible from outside the unit to custom load functions   (SX)
#                dglCheckExtension added to check if an extension exists  (SX)
#                Read_GL_ARB_buffer_object renamed to
#                Read_GL_ARB_vertex_buffer_object                         (SX)
# Version 3.0.1  fixed an problem with fpc                                (SX)
# Version 3.0.2  fixed an problem with WGL_ARB_create_context             (SX)
# Version 3.2    Functions from GL_VERSION_3_0 where updated              (SX)
#                Functions from GL_ARB_map_buffer_range where updated     (SX)
#                Functions from GL_NV_present_video where added           (SX)
#                Added consts of GL_ARB_instanced_arrays                  (SX)
#                Defines to identify Delphi was changed (prevent for
#                feature maintenance)                                     (SX)
#                Added Extension GL_ATI_meminfo                           (SX)
#                Added Extension GL_AMD_performance_monitor               (SX)
#                Added Extension GL_AMD_texture_texture4                  (SX)
#                Added Extension GL_AMD_vertex_shader_tesselator          (SX)
#                Added Extension GL_EXT_provoking_vertex                  (SX)
#                Added Extension WGL_AMD_gpu_association                  (SX)
#                Added OpenGL 3.1 Core                                    (SX)
#                All deprecated stuff can be disabled if you undef the
#                define DGL_DEPRECATED                                    (SX)
#                Added Extension GL_ARB_uniform_buffer_object             (SX)
#                Added Extension GL_ARB_compatibility                     (SX)
#                Added Extension GL_ARB_copy_buffer                       (SX)
#                Added Extension GL_ARB_shader_texture_lod                (SX)
#                Remove function from GL_NV_present_video                 (SX)
#                Added Extension WGL_3DL_stereo_control                   (SX)
#                Added Extension GL_EXT_texture_snorm                     (SX)
#                Added Extension GL_AMD_draw_buffers_blend                (SX)
#                Added Extension GL_APPLE_texture_range                   (SX)
#                Added Extension GL_APPLE_float_pixels                    (SX)
#                Added Extension GL_APPLE_vertex_program_evaluators       (SX)
#                Added Extension GL_APPLE_aux_depth_stencil               (SX)
#                Added Extension GL_APPLE_object_purgeable                (SX)
#                Added Extension GL_APPLE_row_bytes                       (SX)
#                Added OpenGL 3.2 Core                                    (SX)
#                Added Extension GL_ARB_depth_clamp                       (SX)
#                Added Extension GL_ARB_draw_elements_base_vertex         (SX)
#                Added Extension GL_ARB_fragment_coord_conventions        (SX)
#                Added Extension GL_ARB_provoking_vertex                  (SX)
#                Added Extension GL_ARB_seamless_cube_map                 (SX)
#                Added Extension GL_ARB_sync                              (SX)
#                Added Extension GL_ARB_texture_multisample               (SX)
#                Added Extension GL_ARB_vertex_array_bgra                 (SX)
#                Added Extension GL_ARB_draw_buffers_blend                (SX)
#                Added Extension GL_ARB_sample_shading                    (SX)
#                Added Extension GL_ARB_texture_cube_map_array            (SX)
#                Added Extension GL_ARB_texture_gather                    (SX)
#                Added Extension GL_ARB_texture_query_lod                 (SX)
#                Added Extension WGL_ARB_create_context_profile           (SX)
#                Added GLX Core up to Version 1.4                         (SX)
#                Added Extension GLX_ARB_multisample                      (SX)
#                Added Extension GLX_ARB_fbconfig_float                   (SX)
#                Added Extension GLX_ARB_get_proc_address                 (SX)
#                Added Extension GLX_ARB_create_context                   (SX)
#                Added Extension GLX_ARB_create_context_profile           (SX)
#                Added Extension GLX_EXT_visual_info                      (SX)
#                Added Extension GLX_EXT_visual_rating                    (SX)
#                Added Extension GLX_EXT_import_context                   (SX)
#                Added Extension GLX_EXT_fbconfig_packed_float            (SX)
#                Added Extension GLX_EXT_framebuffer_sRGB                 (SX)
#                Added Extension GLX_EXT_texture_from_pixmap              (SX)
# Version 3.2.1  Fixed some problems with Delphi < 6                      (SX)
# Version 3.2.2  Added Extension GL_APPLE_rgb_422                         (SX)
#                Added Extension GL_EXT_separate_shader_objects           (SX)
#                Added Extension GL_NV_video_capture                      (SX)
#                Added Extension GL_NV_copy_image                         (SX)
#                Added Extension GL_NV_parameter_buffer_object2           (SX)
#                Added Extension GL_NV_shader_buffer_load                 (SX)
#                Added Extension GL_NV_vertex_buffer_unified_memory       (SX)
#                Added Extension GL_NV_texture_barrier                    (SX)
#                Variable GL_EXT_texture_snorm will be filled             (SX)
#                Variable GL_APPLE_row_bytes will be filled               (SX)
#                Added Extension WGL_NV_video_capture                     (SX)
#                Added Extension WGL_NV_copy_image                        (SX)
#                WGL_NV_video_out now named WGL_NV_video_output           (SX)
#                Added Extension GLX_EXT_swap_control                     (SX)
# Version 3.2.3  Fixed an Problem with glGetAttribLocation                (SX)
#                Added const GL_UNIFORM_BUFFER_EXT                        (SX)
#                Functions of GL_NV_texture_barrier now will be loaded    (SX)
# Version 4.0    Changes on Extension GL_ARB_texture_gather               (SX)
#                Changes on Extension GL_NV_shader_buffer_load            (SX)
#                Added OpenGL 3.3 Core                                    (SX)
#                Added OpenGL 4.0 Core                                    (SX)
#                Added Extension GL_AMD_shader_stencil_export             (SX)
#                Added Extension GL_AMD_seamless_cubemap_per_texture      (SX)
#                Added Extension GL_ARB_shading_language_include          (SX)
#                Added Extension GL_ARB_texture_compression_bptc          (SX)
#                Added Extension GL_ARB_blend_func_extended               (SX)
#                Added Extension GL_ARB_explicit_attrib_location          (SX)
#                Added Extension GL_ARB_occlusion_query2                  (SX)
#                Added Extension GL_ARB_sampler_objects                   (SX)
#                Added Extension GL_ARB_shader_bit_encoding               (SX)
#                Added Extension GL_ARB_texture_rgb10_a2ui                (SX)
#                Added Extension GL_ARB_texture_swizzle                   (SX)
#                Added Extension GL_ARB_timer_query                       (SX)
#                Added Extension GL_ARB_vertextyp_2_10_10_10_rev        (SX)
#                Added Extension GL_ARB_draw_indirect                     (SX)
#                Added Extension GL_ARB_gpu_shader5                       (SX)
#                Added Extension GL_ARB_gpu_shader_fp64                   (SX)
#                Added Extension GL_ARB_shader_subroutine                 (SX)
#                Added Extension GL_ARB_tessellation_shader               (SX)
#                Added Extension GL_ARB_texture_buffer_object_rgb32       (SX)
#                Added Extension GL_ARB_transform_feedback2               (SX)
#                Added Extension GL_ARB_transform_feedback3               (SX)
# Version 4.1    Possible fix some strange linux behavior                 (SX)
#                All function uses GL instead of TGL types                (SX)
#                GL_AMD_vertex_shader_tesselator will be read now         (SX)
#                GL_AMD_draw_buffers_blend will be read now               (SX)
#                Changes on glStencilFuncSeparate (GL_2_0)                (SX)
#                Changes on GL_VERSION_3_2                                (SX)
#                Changes on GL_VERSION_3_3                                (SX)
#                Changes on GL_VERSION_4_0                                (SX)
#                Changes on GL_ARB_sample_shading                         (SX)
#                Changes on GL_ARB_texture_cube_map_array                 (SX)
#                Changes on GL_ARB_gpu_shader5                            (SX)
#                Changes on GL_ARB_transform_feedback3                    (SX)
#                Changes on GL_ARB_sampler_objects                        (SX)
#                Changes on GL_ARB_gpu_shader_fp64                        (SX)
#                Changes on GL_APPLE_element_array                        (SX)
#                Changes on GL_APPLE_vertex_array_range                   (SX)
#                Changes on GL_NV_transform_feedback                      (SX)
#                Changes on GL_NV_vertex_buffer_unified_memory            (SX)
#                Changes on GL_EXT_multi_draw_arrays                      (SX)
#                Changes on GL_EXT_direct_state_access                    (SX)
#                Changes on GL_AMD_performance_monitor                    (SX)
#                Changes on GL_AMD_seamless_cubemap_per_texture           (SX)
#                Changes on GL_EXT_geometry_shader4                       (SX)
#                Added OpenGL 4.1 Core                                    (SX)
#                Added Extension GL_ARB_ES2_compatibility                 (SX)
#                Added Extension GL_ARB_get_program_binary                (SX)
#                Added Extension GL_ARB_separate_shader_objects           (SX)
#                Added Extension GL_ARB_shader_precision                  (SX)
#                Added Extension GL_ARB_vertex_attrib_64bit               (SX)
#                Added Extension GL_ARB_viewport_array                    (SX)
#                Added Extension GL_ARB_cl_event                          (SX)
#                Added Extension GL_ARB_debug_output                      (SX)
#                Added Extension GL_ARB_robustness                        (SX)
#                Added Extension GL_ARB_shader_stencil_export             (SX)
#                Added Extension GL_AMD_conservative_depth                (SX)
#                Added Extension GL_EXT_shader_image_load_store           (SX)
#                Added Extension GL_EXT_vertex_attrib_64bit               (SX)
#                Added Extension GL_NV_gpu_program5                       (SX)
#                Added Extension GL_NV_gpu_shader5                        (SX)
#                Added Extension GL_NV_shader_buffer_store                (SX)
#                Added Extension GL_NV_tessellation_program5              (SX)
#                Added Extension GL_NV_vertex_attrib_integer_64bit        (SX)
#                Added Extension GL_NV_multisample_coverage               (SX)
#                Added Extension GL_AMD_name_gen_delete                   (SX)
#                Added Extension GL_AMD_debug_output                      (SX)
#                Added Extension GL_NV_vdpau_interop                      (SX)
#                Added Extension GL_AMD_transform_feedback3_lines_triangles (SX)
#                Added Extension GL_AMD_depth_clamp_separate              (SX)
#                Added Extension GL_EXT_texture_sRGB_decode               (SX)
#                Added Extension WGL_ARB_framebuffer_sRGB                 (SX)
#                Added Extension WGL_ARB_create_context_robustness        (SX)
#                Added Extension WGL_EXT_create_context_es2_profile       (SX)
#                Added Extension WGL_NV_multisample_coverage              (SX)
#                Added Extension GLX_ARB_vertex_buffer_object             (SX)
#                Added Extension GLX_ARB_framebuffer_sRGB                 (SX)
#                Added Extension GLX_ARB_create_context_robustness        (SX)
#                Added Extension GLX_EXT_create_context_es2_profile       (SX)
# Version 4.1a   Fix for dglGetProcAddress with FPC and linux (def param) (SW)
# Version 4.2    Added OpenGL 4.2 Core                                    (SW)
#                Added Extension GL_ARB_base_instance                     (SW)
#                Added Extension GL_ARB_shading_language_420pack          (SW)
#                Added Extension GL_ARB_transform_feedback_instanced      (SW)
#                Added Extension GL_ARB_compressed_texture_pixel_storage  (SW)
#                Added Extension GL_ARB_conservative_depth                (SW)
#                Added Extension GL_ARB_internalformat_query              (SW)
#                Added Extension GL_ARB_map_buffer_alignment              (SW)
#                Added Extension GL_ARB_shader_atomic_counters            (SW)
#                Added Extension GL_ARB_shader_image_load_store           (SW)
#                Added Extension GL_ARB_shading_language_packing          (SW)
#                Added Extension GL_ARB_texture_storage                   (SW)
#                Added Extension WGL_NV_DX_interop                        (SW)
#                Added Define for WGL_EXT_create_context_es2_profile      (SW)
# Version 4.2a   Added Mac OS X patch by Andrey Gruzdev                   (SW)
#==============================================================================
# Header based on glext.h  rev 72 (2011/08/08)
# Header based on wglext.h rev 23 (2011/04/13)
# Header based on glxext.h rev 32 (2010/08/06)  (only Core/ARB/EXT)
#
# This is an important notice for maintaining. Dont remove it. And make sure
# to keep it up to date
#==============================================================================

{.deadCodeElim: on.}

type
  PPointer* = ptr Pointer
  GLenum* = uint32
  GLboolean* = bool
  GLbitfield* = uint32
  GLbyte* = int8
  GLshort* = int16
  GLint* = int32
  GLsizei* = int32
  GLubyte* = uint8
  GLushort* = uint16
  GLuint* = uint32
  GLfloat* = float32
  GLclampf* = float32
  GLdouble* = float64
  GLclampd* = float64
  GLvoid* = Pointer
  GLint64* = Int64
  GLuint64* = uint64
  TGLenum* = GLenum
  TGLboolean* = GLboolean
  TGLbitfield* = GLbitfield
  TGLbyte* = GLbyte
  TGLshort* = GLshort
  TGLint* = GLint
  TGLsizei* = GLsizei
  TGLubyte* = GLubyte
  TGLushort* = GLushort
  TGLuint* = GLuint
  TGLfloat* = GLfloat
  TGLclampf* = GLclampf
  TGLdouble* = GLdouble
  TGLclampd* = GLclampd
  TGLvoid* = GLvoid
  TGLint64* = GLint64
  TGLuint64* = GLuint64
  PGLboolean* = ptr GLboolean
  PGLbyte* = ptr GLbyte
  PGLshort* = ptr GLshort
  PGLint* = ptr GLint
  PGLsizei* = ptr GLsizei
  PGLubyte* = ptr GLubyte
  PGLushort* = ptr GLushort
  PGLuint* = ptr GLuint
  PGLclampf* = ptr GLclampf
  PGLfloat* = ptr GLfloat
  PGLdouble* = ptr GLdouble
  PGLclampd* = ptr GLclampd
  PGLenum* = ptr GLenum
  PGLvoid* = Pointer
  PPGLvoid* = ptr PGLvoid
  PGLint64* = ptr GLint64
  PGLuint64* = ptr GLuint64   # GL_NV_half_float
  GLhalfNV* = int16
  TGLhalfNV* = GLhalfNV
  PGLhalfNV* = ptr GLhalfNV   # GL_ARB_shader_objects
  PGLHandleARB* = ptr GLHandleARB
  GLHandleARB* = int
  GLcharARB* = Char
  PGLcharARB* = cstring
  PPGLcharARB* = ptr PGLcharARB # GL_VERSION_1_5
  GLintptr* = GLint
  GLsizeiptr* = GLsizei       # GL_ARB_vertex_buffer_object
  GLintptrARB* = GLint
  GLsizeiptrARB* = GLsizei    # GL_VERSION_2_0
  GLHandle* = int
  PGLchar* = cstring
  PPGLchar* = ptr PGLChar     # GL_EXT_timer_query
  GLint64EXT* = Int64
  TGLint64EXT* = GLint64EXT
  PGLint64EXT* = ptr GLint64EXT
  GLuint64EXT* = GLuint64
  TGLuint64EXT* = GLuint64EXT
  PGLuint64EXT* = ptr GLuint64EXT # WGL_ARB_pbuffer

  GLsync* = Pointer           # GL_ARB_cl_event
                              # These incomplete types let us declare types compatible with OpenCL's cl_context and cl_event
  Tcl_context*{.final.} = object
  Tcl_event*{.final.} = object
  p_cl_context* = ptr Tcl_context
  p_cl_event* = ptr Tcl_event  # GL_ARB_debug_output
  TglDebugProcARB* = proc (source: GLenum, typ: GLenum, id: GLuint,
                           severity: GLenum, len: GLsizei, message: PGLchar,
                           userParam: PGLvoid){.stdcall.} # GL_AMD_debug_output
  TglDebugProcAMD* = proc (id: GLuint, category: GLenum, severity: GLenum,
                           len: GLsizei, message: PGLchar, userParam: PGLvoid){.
      stdcall.}               # GL_NV_vdpau_interop
  GLvdpauSurfaceNV* = GLintptr
  PGLvdpauSurfaceNV* = ptr GLvdpauSurfaceNV # GLX

when defined(windows):
  type
    HPBUFFERARB* = THandle      # WGL_EXT_pbuffer
    HPBUFFEREXT* = THandle      # WGL_NV_present_video
    PHVIDEOOUTPUTDEVICENV* = ptr HVIDEOOUTPUTDEVICENV
    HVIDEOOUTPUTDEVICENV* = THandle # WGL_NV_video_output
    PHPVIDEODEV* = ptr HPVIDEODEV
    HPVIDEODEV* = THandle       # WGL_NV_gpu_affinity
    PHPGPUNV* = ptr HPGPUNV
    PHGPUNV* = ptr HGPUNV       # WGL_NV_video_capture
    HVIDEOINPUTDEVICENV* = THandle
    PHVIDEOINPUTDEVICENV* = ptr HVIDEOINPUTDEVICENV
    HPGPUNV* = THandle
    HGPUNV* = THandle           # GL_ARB_sync

when defined(LINUX):
  type
    GLXContext* = Pointer
    GLXContextID* = TXID
    GLXDrawable* = TXID
    GLXFBConfig* = Pointer
    GLXPbuffer* = TXID
    GLXPixmap* = TXID
    GLXWindow* = TXID
    Window* = TXID
    Colormap* = TXID
    Pixmap* = TXID
    Font* = TXID
type                          # Datatypes corresponding to GL's types TGL(name)(type)(count)
  TGLVectorub2* = array[0..1, GLubyte]
  TGLVectori2* = array[0..1, GLint]
  TGLVectorf2* = array[0..1, GLfloat]
  TGLVectord2* = array[0..1, GLdouble]
  TGLVectorp2* = array[0..1, Pointer]
  TGLVectorb3* = array[0..2, GLbyte]
  TGLVectorub3* = array[0..2, GLubyte]
  TGLVectori3* = array[0..2, GLint]
  TGLVectorui3* = array[0..2, GLuint]
  TGLVectorf3* = array[0..2, GLfloat]
  TGLVectord3* = array[0..2, GLdouble]
  TGLVectorp3* = array[0..2, Pointer]
  TGLVectors3* = array[0..2, GLshort]
  TGLVectorus3* = array[0..2, GLushort]
  TGLVectorb4* = array[0..3, GLbyte]
  TGLVectorub4* = array[0..3, GLubyte]
  TGLVectori4* = array[0..3, GLint]
  TGLVectorui4* = array[0..3, GLuint]
  TGLVectorf4* = array[0..3, GLfloat]
  TGLVectord4* = array[0..3, GLdouble]
  TGLVectorp4* = array[0..3, Pointer]
  TGLVectors4* = array[0..3, GLshort]
  TGLVectorus4* = array[0..3, GLshort]
  TGLArrayf4* = TGLVectorf4
  TGLArrayf3* = TGLVectorf3
  TGLArrayd3* = TGLVectord3
  TGLArrayi4* = TGLVectori4
  TGLArrayp4* = TGLVectorp4
  TGlMatrixub3* = array[0..2, array[0..2, GLubyte]]
  TGlMatrixi3* = array[0..2, array[0..2, GLint]]
  TGLMatrixf3* = array[0..2, array[0..2, GLfloat]]
  TGLMatrixd3* = array[0..2, array[0..2, GLdouble]]
  TGlMatrixub4* = array[0..3, array[0..3, GLubyte]]
  TGlMatrixi4* = array[0..3, array[0..3, GLint]]
  TGLMatrixf4* = array[0..3, array[0..3, GLfloat]]
  TGLMatrixd4* = array[0..3, array[0..3, GLdouble]]
  TGLVector3f* = TGLVectorf3  # Datatypes corresponding to OpenGL12.pas for easy porting
  TVector3d* = TGLVectord3
  TVector4i* = TGLVectori4
  TVector4f* = TGLVectorf4
  TVector4p* = TGLVectorp4
  TMatrix4f* = TGLMatrixf4
  TMatrix4d* = TGLMatrixd4
  PGLMatrixd4* = ptr TGLMatrixd4
  PVector4i* = ptr TVector4i
  TRect*{.final.} = object
    Left*, Top*, Right*, Bottom*: int32

  PGPU_DEVICE* = ptr GPU_DEVICE
  GPU_DEVICE*{.final.} = object
    cb*: int32
    DeviceName*: array[0..31, Char]
    DeviceString*: array[0..127, Char]
    Flags*: int32
    rcVirtualScreen*: TRect


when defined(windows):
  type
    PWGLSwap* = ptr TWGLSwap
    TWGLSWAP*{.final.} = object
      hdc*: HDC
      uiFlags*: int32

type
  TGLUNurbs*{.final.} = object
  TGLUQuadric*{.final.} = object
  TGLUTesselator*{.final.} = object
  PGLUNurbs* = ptr TGLUNurbs
  PGLUQuadric* = ptr TGLUQuadric
  PGLUTesselator* = ptr TGLUTesselator # backwards compatibility
  TGLUNurbsObj* = TGLUNurbs
  TGLUQuadricObj* = TGLUQuadric
  TGLUTesselatorObj* = TGLUTesselator
  TGLUTriangulatorObj* = TGLUTesselator
  PGLUNurbsObj* = PGLUNurbs
  PGLUQuadricObj* = PGLUQuadric
  PGLUTesselatorObj* = PGLUTesselator
  PGLUTriangulatorObj* = PGLUTesselator # GLUQuadricCallback

  TGLUQuadricErrorProc* = proc(errorCode: GLenum){.stdcall.}
  TGLUTessBeginProc* = proc(AType: GLenum){.stdcall.}
  TGLUTessEdgeFlagProc* = proc(Flag: GLboolean){.stdcall.}
  TGLUTessVertexProc* = proc(VertexData: Pointer){.stdcall.}
  TGLUTessEndProc* = proc(){.stdcall.}
  TGLUTessErrorProc* = proc(ErrNo: GLenum){.stdcall.}
  TGLUTessCombineProc* = proc(Coords: TGLArrayd3, VertexData: TGLArrayp4,
                         Weight: TGLArrayf4, OutData: PPointer){.stdcall.}
  TGLUTessBeginDataProc* = proc(AType: GLenum, UserData: Pointer){.stdcall.}
  TGLUTessEdgeFlagDataProc* = proc(Flag: GLboolean, UserData: Pointer){.stdcall.}
  TGLUTessVertexDataProc* = proc(VertexData: Pointer, UserData: Pointer){.stdcall.}
  TGLUTessEndDataProc* = proc(UserData: Pointer){.stdcall.}
  TGLUTessErrorDataProc* = proc(ErrNo: GLenum, UserData: Pointer){.stdcall.}
  TGLUTessCombineDataProc* = proc(Coords: TGLArrayd3, VertexData: TGLArrayp4,
                             Weight: TGLArrayf4, OutData: PPointer,
                             UserData: Pointer){.stdcall.}
  # GLUNurbsCallback
  TGLUNurbsErrorProc* = proc(ErrorCode: GLEnum){.stdcall.}

const                         # GL_VERSION_1_1
                              # AttribMask
  GL_DEPTH_BUFFER_BIT* = 0x00000100
  GL_STENCIL_BUFFER_BIT* = 0x00000400
  GL_COLOR_BUFFER_BIT* = 0x00004000 # Boolean
  GL_TRUE* = 1
  GL_FALSE* = 0               # BeginMode
  GL_POINTS* = 0x00000000
  GL_LINES* = 0x00000001
  GL_LINE_LOOP* = 0x00000002
  GL_LINE_STRIP* = 0x00000003
  GL_TRIANGLES* = 0x00000004
  GL_TRIANGLE_STRIP* = 0x00000005
  GL_TRIANGLE_FAN* = 0x00000006 # AlphaFunction
  GL_NEVER* = 0x00000200
  GL_LESS* = 0x00000201
  GL_EQUAL* = 0x00000202
  GL_LEQUAL* = 0x00000203
  GL_GREATER* = 0x00000204
  GL_NOTEQUAL* = 0x00000205
  GL_GEQUAL* = 0x00000206
  GL_ALWAYS* = 0x00000207     # BlendingFactorDest
  GL_ZERO* = 0
  GL_ONE* = 1
  GL_SRC_COLOR* = 0x00000300
  GL_ONE_MINUS_SRC_COLOR* = 0x00000301
  GL_SRC_ALPHA* = 0x00000302
  GL_ONE_MINUS_SRC_ALPHA* = 0x00000303
  GL_DST_ALPHA* = 0x00000304
  GL_ONE_MINUS_DST_ALPHA* = 0x00000305 # BlendingFactorSrc
  GL_DST_COLOR* = 0x00000306
  GL_ONE_MINUS_DST_COLOR* = 0x00000307
  GL_SRC_ALPHA_SATURATE* = 0x00000308 # DrawBufferMode
  GL_NONE* = 0
  GL_FRONT_LEFT* = 0x00000400
  GL_FRONT_RIGHT* = 0x00000401
  GL_BACK_LEFT* = 0x00000402
  GL_BACK_RIGHT* = 0x00000403
  GL_FRONT* = 0x00000404
  GL_BACK* = 0x00000405
  GL_LEFT* = 0x00000406
  GL_RIGHT* = 0x00000407
  GL_FRONT_AND_BACK* = 0x00000408 # ErrorCode
  GL_NO_ERROR* = 0
  GL_INVALID_ENUM* = 0x00000500
  GL_INVALID_VALUE* = 0x00000501
  GL_INVALID_OPERATION* = 0x00000502
  GL_OUT_OF_MEMORY* = 0x00000505 # FrontFaceDirection
  GL_CW* = 0x00000900
  GL_CCW* = 0x00000901        # GetPName
  cGL_POINT_SIZE* = 0x00000B11
  GL_POINT_SIZE_RANGE* = 0x00000B12
  GL_POINT_SIZE_GRANULARITY* = 0x00000B13
  GL_LINE_SMOOTH* = 0x00000B20
  cGL_LINE_WIDTH* = 0x00000B21
  GL_LINE_WIDTH_RANGE* = 0x00000B22
  GL_LINE_WIDTH_GRANULARITY* = 0x00000B23
  GL_POLYGON_SMOOTH* = 0x00000B41
  cGL_CULL_FACE* = 0x00000B44
  GL_CULL_FACE_MODE* = 0x00000B45
  cGL_FRONT_FACE* = 0x00000B46
  cGL_DEPTH_RANGE* = 0x00000B70
  GL_DEPTH_TEST* = 0x00000B71
  GL_DEPTH_WRITEMASK* = 0x00000B72
  GL_DEPTH_CLEAR_VALUE* = 0x00000B73
  cGL_DEPTH_FUNC* = 0x00000B74
  GL_STENCIL_TEST* = 0x00000B90
  GL_STENCIL_CLEAR_VALUE* = 0x00000B91
  cGL_STENCIL_FUNC* = 0x00000B92
  GL_STENCIL_VALUE_MASK* = 0x00000B93
  GL_STENCIL_FAIL* = 0x00000B94
  GL_STENCIL_PASS_DEPTH_FAIL* = 0x00000B95
  GL_STENCIL_PASS_DEPTH_PASS* = 0x00000B96
  GL_STENCIL_REF* = 0x00000B97
  GL_STENCIL_WRITEMASK* = 0x00000B98
  cGL_VIEWPORT* = 0x00000BA2
  GL_DITHER* = 0x00000BD0
  GL_BLEND_DST* = 0x00000BE0
  GL_BLEND_SRC* = 0x00000BE1
  GL_BLEND* = 0x00000BE2
  GL_LOGIC_OP_MODE* = 0x00000BF0
  GL_COLOR_LOGIC_OP* = 0x00000BF2
  cGL_DRAW_BUFFER* = 0x00000C01
  cGL_READ_BUFFER* = 0x00000C02
  GL_SCISSOR_BOX* = 0x00000C10
  GL_SCISSOR_TEST* = 0x00000C11
  GL_COLOR_CLEAR_VALUE* = 0x00000C22
  GL_COLOR_WRITEMASK* = 0x00000C23
  GL_DOUBLEBUFFER* = 0x00000C32
  GL_STEREO* = 0x00000C33
  GL_LINE_SMOOTH_HINT* = 0x00000C52
  GL_POLYGON_SMOOTH_HINT* = 0x00000C53
  GL_UNPACK_SWAP_BYTES* = 0x00000CF0
  GL_UNPACK_LSB_FIRST* = 0x00000CF1
  GL_UNPACK_ROW_LENGTH* = 0x00000CF2
  GL_UNPACK_SKIP_ROWS* = 0x00000CF3
  GL_UNPACK_SKIP_PIXELS* = 0x00000CF4
  GL_UNPACK_ALIGNMENT* = 0x00000CF5
  GL_PACK_SWAP_BYTES* = 0x00000D00
  GL_PACK_LSB_FIRST* = 0x00000D01
  GL_PACK_ROW_LENGTH* = 0x00000D02
  GL_PACK_SKIP_ROWS* = 0x00000D03
  GL_PACK_SKIP_PIXELS* = 0x00000D04
  GL_PACK_ALIGNMENT* = 0x00000D05
  GL_MAX_TEXTURE_SIZE* = 0x00000D33
  GL_MAX_VIEWPORT_DIMS* = 0x00000D3A
  GL_SUBPIXEL_BITS* = 0x00000D50
  GL_TEXTURE_1D* = 0x00000DE0
  GL_TEXTURE_2D* = 0x00000DE1
  GL_POLYGON_OFFSET_UNITS* = 0x00002A00
  GL_POLYGON_OFFSET_POINT* = 0x00002A01
  GL_POLYGON_OFFSET_LINE* = 0x00002A02
  GL_POLYGON_OFFSET_FILL* = 0x00008037
  GL_POLYGON_OFFSET_FACTOR* = 0x00008038
  GL_TEXTURE_BINDING_1D* = 0x00008068
  GL_TEXTURE_BINDING_2D* = 0x00008069 # GetTextureParameter
  GL_TEXTURE_WIDTH* = 0x00001000
  GL_TEXTURE_HEIGHT* = 0x00001001
  GL_TEXTURE_INTERNAL_FORMAT* = 0x00001003
  GL_TEXTURE_BORDER_COLOR* = 0x00001004
  GL_TEXTURE_BORDER* = 0x00001005
  GL_TEXTURE_RED_SIZE* = 0x0000805C
  GL_TEXTURE_GREEN_SIZE* = 0x0000805D
  GL_TEXTURE_BLUE_SIZE* = 0x0000805E
  GL_TEXTURE_ALPHA_SIZE* = 0x0000805F # HintMode
  GL_DONT_CARE* = 0x00001100
  GL_FASTEST* = 0x00001101
  GL_NICEST* = 0x00001102     # DataType
  cGL_BYTE* = 0x00001400
  cGL_UNSIGNED_BYTE* = 0x00001401
  cGL_SHORT* = 0x00001402
  cGL_UNSIGNED_SHORT* = 0x00001403
  cGL_INT* = 0x00001404
  cGL_UNSIGNED_INT* = 0x00001405
  cGL_FLOAT* = 0x00001406
  cGL_DOUBLE* = 0x0000140A     # LogicOp
  cGL_CLEAR* = 0x00001500
  GL_AND* = 0x00001501
  GL_AND_REVERSE* = 0x00001502
  GL_COPY* = 0x00001503
  GL_AND_INVERTED* = 0x00001504
  GL_NOOP* = 0x00001505
  GL_XOR* = 0x00001506
  GL_OR* = 0x00001507
  GL_NOR* = 0x00001508
  GL_EQUIV* = 0x00001509
  GL_INVERT* = 0x0000150A
  GL_OR_REVERSE* = 0x0000150B
  GL_COPY_INVERTED* = 0x0000150C
  GL_OR_INVERTED* = 0x0000150D
  GL_NAND* = 0x0000150E
  GL_SET* = 0x0000150F        # MatrixMode (for gl3.h, FBO attachment type)
  GL_TEXTURE* = 0x00001702    # PixelCopyType
  GL_COLOR* = 0x00001800
  GL_DEPTH* = 0x00001801
  GL_STENCIL* = 0x00001802    # PixelFormat
  GL_STENCIL_INDEX* = 0x00001901
  GL_DEPTH_COMPONENT* = 0x00001902
  GL_RED* = 0x00001903
  GL_GREEN* = 0x00001904
  GL_BLUE* = 0x00001905
  GL_ALPHA* = 0x00001906
  GL_RGB* = 0x00001907
  GL_RGBA* = 0x00001908       # PolygonMode
  GL_POINT* = 0x00001B00
  GL_LINE* = 0x00001B01
  GL_FILL* = 0x00001B02       # StencilOp
  GL_KEEP* = 0x00001E00
  GL_REPLACE* = 0x00001E01
  GL_INCR* = 0x00001E02
  GL_DECR* = 0x00001E03       # StringName
  GL_VENDOR* = 0x00001F00
  GL_RENDERER* = 0x00001F01
  GL_VERSION* = 0x00001F02
  GL_EXTENSIONS* = 0x00001F03 # TextureMagFilter
  GL_NEAREST* = 0x00002600
  GL_LINEAR* = 0x00002601     # TextureMinFilter
  GL_NEAREST_MIPMAP_NEAREST* = 0x00002700
  GL_LINEAR_MIPMAP_NEAREST* = 0x00002701
  GL_NEAREST_MIPMAP_LINEAR* = 0x00002702
  GL_LINEAR_MIPMAP_LINEAR* = 0x00002703 # TextureParameterName
  GL_TEXTURE_MAG_FILTER* = 0x00002800
  GL_TEXTURE_MIN_FILTER* = 0x00002801
  GL_TEXTURE_WRAP_S* = 0x00002802
  GL_TEXTURE_WRAP_T* = 0x00002803 # TextureTarget
  GL_PROXY_TEXTURE_1D* = 0x00008063
  GL_PROXY_TEXTURE_2D* = 0x00008064 # TextureWrapMode
  GL_REPEAT* = 0x00002901     # PixelInternalFormat
  GL_R3_G3_B2* = 0x00002A10
  GL_RGB4* = 0x0000804F
  GL_RGB5* = 0x00008050
  GL_RGB8* = 0x00008051
  GL_RGB10* = 0x00008052
  GL_RGB12* = 0x00008053
  GL_RGB16* = 0x00008054
  GL_RGBA2* = 0x00008055
  GL_RGBA4* = 0x00008056
  GL_RGB5_A1* = 0x00008057
  GL_RGBA8* = 0x00008058
  GL_RGB10_A2* = 0x00008059
  GL_RGBA12* = 0x0000805A
  GL_RGBA16* = 0x0000805B
  cGL_ACCUM* = 0x00000100
  GL_LOAD* = 0x00000101
  GL_RETURN* = 0x00000102
  GL_MULT* = 0x00000103
  GL_ADD* = 0x00000104
  GL_CURRENT_BIT* = 0x00000001
  GL_POINT_BIT* = 0x00000002
  GL_LINE_BIT* = 0x00000004
  GL_POLYGON_BIT* = 0x00000008
  GL_POLYGON_STIPPLE_BIT* = 0x00000010
  GL_PIXEL_MODE_BIT* = 0x00000020
  GL_LIGHTING_BIT* = 0x00000040
  GL_FOG_BIT* = 0x00000080
  GL_ACCUM_BUFFER_BIT* = 0x00000200
  GL_VIEWPORT_BIT* = 0x00000800
  GL_TRANSFORM_BIT* = 0x00001000
  GL_ENABLE_BIT* = 0x00002000
  GL_HINT_BIT* = 0x00008000
  GL_EVAL_BIT* = 0x00010000
  GL_LIST_BIT* = 0x00020000
  GL_TEXTURE_BIT* = 0x00040000
  GL_SCISSOR_BIT* = 0x00080000
  GL_ALL_ATTRIB_BITS* = 0x000FFFFF
  GL_QUADS* = 0x00000007
  GL_QUAD_STRIP* = 0x00000008
  GL_POLYGON* = 0x00000009
  GL_CLIP_PLANE0* = 0x00003000
  GL_CLIP_PLANE1* = 0x00003001
  GL_CLIP_PLANE2* = 0x00003002
  GL_CLIP_PLANE3* = 0x00003003
  GL_CLIP_PLANE4* = 0x00003004
  GL_CLIP_PLANE5* = 0x00003005
  GL_2_BYTES* = 0x00001407
  GL_3_BYTES* = 0x00001408
  GL_4_BYTES* = 0x00001409
  GL_AUX0* = 0x00000409
  GL_AUX1* = 0x0000040A
  GL_AUX2* = 0x0000040B
  GL_AUX3* = 0x0000040C
  GL_STACK_OVERFLOW* = 0x00000503
  GL_STACK_UNDERFLOW* = 0x00000504
  GL_2D* = 0x00000600
  GL_3D* = 0x00000601
  GL_3D_COLOR* = 0x00000602
  GL_3D_COLOR_TEXTURE* = 0x00000603
  GL_4D_COLOR_TEXTURE* = 0x00000604
  GL_PASS_THROUGH_TOKEN* = 0x00000700
  GL_POINT_TOKEN* = 0x00000701
  GL_LINE_TOKEN* = 0x00000702
  GL_POLYGON_TOKEN* = 0x00000703
  GL_BITMAP_TOKEN* = 0x00000704
  GL_DRAW_PIXEL_TOKEN* = 0x00000705
  GL_COPY_PIXEL_TOKEN* = 0x00000706
  GL_LINE_RESET_TOKEN* = 0x00000707
  GL_EXP* = 0x00000800
  GL_EXP2* = 0x00000801
  GL_COEFF* = 0x00000A00
  GL_ORDER* = 0x00000A01
  GL_DOMAIN* = 0x00000A02
  GL_CURRENT_COLOR* = 0x00000B00
  GL_CURRENT_INDEX* = 0x00000B01
  GL_CURRENT_NORMAL* = 0x00000B02
  GL_CURRENT_TEXTURE_COORDS* = 0x00000B03
  GL_CURRENT_RASTER_COLOR* = 0x00000B04
  GL_CURRENT_RASTER_INDEX* = 0x00000B05
  GL_CURRENT_RASTER_TEXTURE_COORDS* = 0x00000B06
  GL_CURRENT_RASTER_POSITION* = 0x00000B07
  GL_CURRENT_RASTER_POSITION_VALID* = 0x00000B08
  GL_CURRENT_RASTER_DISTANCE* = 0x00000B09
  GL_POINT_SMOOTH* = 0x00000B10
  cGL_LINE_STIPPLE* = 0x00000B24
  GL_LINE_STIPPLE_PATTERN* = 0x00000B25
  GL_LINE_STIPPLE_REPEAT* = 0x00000B26
  GL_LIST_MODE* = 0x00000B30
  GL_MAX_LIST_NESTING* = 0x00000B31
  cGL_LIST_BASE* = 0x00000B32
  GL_LIST_INDEX* = 0x00000B33
  cGL_POLYGON_MODE* = 0x00000B40
  cGL_POLYGON_STIPPLE* = 0x00000B42
  cGL_EDGE_FLAG* = 0x00000B43
  GL_LIGHTING* = 0x00000B50
  GL_LIGHT_MODEL_LOCAL_VIEWER* = 0x00000B51
  GL_LIGHT_MODEL_TWO_SIDE* = 0x00000B52
  GL_LIGHT_MODEL_AMBIENT* = 0x00000B53
  cGL_SHADE_MODEL* = 0x00000B54
  GL_COLOR_MATERIAL_FACE* = 0x00000B55
  GL_COLOR_MATERIAL_PARAMETER* = 0x00000B56
  cGL_COLOR_MATERIAL* = 0x00000B57
  GL_FOG* = 0x00000B60
  GL_FOG_INDEX* = 0x00000B61
  GL_FOG_DENSITY* = 0x00000B62
  GL_FOG_START* = 0x00000B63
  GL_FOG_END* = 0x00000B64
  GL_FOG_MODE* = 0x00000B65
  GL_FOG_COLOR* = 0x00000B66
  GL_ACCUM_CLEAR_VALUE* = 0x00000B80
  cGL_MATRIX_MODE* = 0x00000BA0
  GL_NORMALIZE* = 0x00000BA1
  GL_MODELVIEW_STACK_DEPTH* = 0x00000BA3
  GL_PROJECTION_STACK_DEPTH* = 0x00000BA4
  GL_TEXTURE_STACK_DEPTH* = 0x00000BA5
  GL_MODELVIEW_MATRIX* = 0x00000BA6
  GL_PROJECTION_MATRIX* = 0x00000BA7
  GL_TEXTURE_MATRIX* = 0x00000BA8
  GL_ATTRIB_STACK_DEPTH* = 0x00000BB0
  GL_CLIENT_ATTRIB_STACK_DEPTH* = 0x00000BB1
  GL_ALPHA_TEST* = 0x00000BC0
  GL_ALPHA_TEST_FUNC* = 0x00000BC1
  GL_ALPHA_TEST_REF* = 0x00000BC2
  GL_INDEX_LOGIC_OP* = 0x00000BF1
  GL_AUX_BUFFERS* = 0x00000C00
  GL_INDEX_CLEAR_VALUE* = 0x00000C20
  GL_INDEX_WRITEMASK* = 0x00000C21
  GL_INDEX_MODE* = 0x00000C30
  GL_RGBA_MODE* = 0x00000C31
  cGL_RENDER_MODE* = 0x00000C40
  GL_PERSPECTIVE_CORRECTION_HINT* = 0x00000C50
  GL_POINT_SMOOTH_HINT* = 0x00000C51
  GL_FOG_HINT* = 0x00000C54
  GL_TEXTURE_GEN_S* = 0x00000C60
  GL_TEXTURE_GEN_T* = 0x00000C61
  GL_TEXTURE_GEN_R* = 0x00000C62
  GL_TEXTURE_GEN_Q* = 0x00000C63
  GL_PIXEL_MAP_I_TO_I* = 0x00000C70
  GL_PIXEL_MAP_S_TO_S* = 0x00000C71
  GL_PIXEL_MAP_I_TO_R* = 0x00000C72
  GL_PIXEL_MAP_I_TO_G* = 0x00000C73
  GL_PIXEL_MAP_I_TO_B* = 0x00000C74
  GL_PIXEL_MAP_I_TO_A* = 0x00000C75
  GL_PIXEL_MAP_R_TO_R* = 0x00000C76
  GL_PIXEL_MAP_G_TO_G* = 0x00000C77
  GL_PIXEL_MAP_B_TO_B* = 0x00000C78
  GL_PIXEL_MAP_A_TO_A* = 0x00000C79
  GL_PIXEL_MAP_I_TO_I_SIZE* = 0x00000CB0
  GL_PIXEL_MAP_S_TO_S_SIZE* = 0x00000CB1
  GL_PIXEL_MAP_I_TO_R_SIZE* = 0x00000CB2
  GL_PIXEL_MAP_I_TO_G_SIZE* = 0x00000CB3
  GL_PIXEL_MAP_I_TO_B_SIZE* = 0x00000CB4
  GL_PIXEL_MAP_I_TO_A_SIZE* = 0x00000CB5
  GL_PIXEL_MAP_R_TO_R_SIZE* = 0x00000CB6
  GL_PIXEL_MAP_G_TO_G_SIZE* = 0x00000CB7
  GL_PIXEL_MAP_B_TO_B_SIZE* = 0x00000CB8
  GL_PIXEL_MAP_A_TO_A_SIZE* = 0x00000CB9
  GL_MAP_COLOR* = 0x00000D10
  GL_MAP_STENCIL* = 0x00000D11
  GL_INDEX_SHIFT* = 0x00000D12
  GL_INDEX_OFFSET* = 0x00000D13
  GL_RED_SCALE* = 0x00000D14
  GL_RED_BIAS* = 0x00000D15
  GL_ZOOM_X* = 0x00000D16
  GL_ZOOM_Y* = 0x00000D17
  GL_GREEN_SCALE* = 0x00000D18
  GL_GREEN_BIAS* = 0x00000D19
  GL_BLUE_SCALE* = 0x00000D1A
  GL_BLUE_BIAS* = 0x00000D1B
  GL_ALPHA_SCALE* = 0x00000D1C
  GL_ALPHA_BIAS* = 0x00000D1D
  GL_DEPTH_SCALE* = 0x00000D1E
  GL_DEPTH_BIAS* = 0x00000D1F
  GL_MAX_EVAL_ORDER* = 0x00000D30
  GL_MAX_LIGHTS* = 0x00000D31
  GL_MAX_CLIP_PLANES* = 0x00000D32
  GL_MAX_PIXEL_MAP_TABLE* = 0x00000D34
  GL_MAX_ATTRIB_STACK_DEPTH* = 0x00000D35
  GL_MAX_MODELVIEW_STACK_DEPTH* = 0x00000D36
  GL_MAX_NAME_STACK_DEPTH* = 0x00000D37
  GL_MAX_PROJECTION_STACK_DEPTH* = 0x00000D38
  GL_MAX_TEXTURE_STACK_DEPTH* = 0x00000D39
  GL_MAX_CLIENT_ATTRIB_STACK_DEPTH* = 0x00000D3B
  GL_INDEX_BITS* = 0x00000D51
  GL_RED_BITS* = 0x00000D52
  GL_GREEN_BITS* = 0x00000D53
  GL_BLUE_BITS* = 0x00000D54
  GL_ALPHA_BITS* = 0x00000D55
  GL_DEPTH_BITS* = 0x00000D56
  GL_STENCIL_BITS* = 0x00000D57
  GL_ACCUM_RED_BITS* = 0x00000D58
  GL_ACCUM_GREEN_BITS* = 0x00000D59
  GL_ACCUM_BLUE_BITS* = 0x00000D5A
  GL_ACCUM_ALPHA_BITS* = 0x00000D5B
  GL_NAME_STACK_DEPTH* = 0x00000D70
  GL_AUTO_NORMAL* = 0x00000D80
  GL_MAP1_COLOR_4* = 0x00000D90
  GL_MAP1_INDEX* = 0x00000D91
  GL_MAP1_NORMAL* = 0x00000D92
  GL_MAP1_TEXTURE_COORD_1* = 0x00000D93
  GL_MAP1_TEXTURE_COORD_2* = 0x00000D94
  GL_MAP1_TEXTURE_COORD_3* = 0x00000D95
  GL_MAP1_TEXTURE_COORD_4* = 0x00000D96
  GL_MAP1_VERTEX_3* = 0x00000D97
  GL_MAP1_VERTEX_4* = 0x00000D98
  GL_MAP2_COLOR_4* = 0x00000DB0
  GL_MAP2_INDEX* = 0x00000DB1
  GL_MAP2_NORMAL* = 0x00000DB2
  GL_MAP2_TEXTURE_COORD_1* = 0x00000DB3
  GL_MAP2_TEXTURE_COORD_2* = 0x00000DB4
  GL_MAP2_TEXTURE_COORD_3* = 0x00000DB5
  GL_MAP2_TEXTURE_COORD_4* = 0x00000DB6
  GL_MAP2_VERTEX_3* = 0x00000DB7
  GL_MAP2_VERTEX_4* = 0x00000DB8
  GL_MAP1_GRID_DOMAIN* = 0x00000DD0
  GL_MAP1_GRID_SEGMENTS* = 0x00000DD1
  GL_MAP2_GRID_DOMAIN* = 0x00000DD2
  GL_MAP2_GRID_SEGMENTS* = 0x00000DD3
  GL_FEEDBACK_BUFFER_POINTER* = 0x00000DF0
  GL_FEEDBACK_BUFFER_SIZE* = 0x00000DF1
  GL_FEEDBACK_BUFFERtyp* = 0x00000DF2
  GL_SELECTION_BUFFER_POINTER* = 0x00000DF3
  GL_SELECTION_BUFFER_SIZE* = 0x00000DF4
  GL_LIGHT0* = 0x00004000
  GL_LIGHT1* = 0x00004001
  GL_LIGHT2* = 0x00004002
  GL_LIGHT3* = 0x00004003
  GL_LIGHT4* = 0x00004004
  GL_LIGHT5* = 0x00004005
  GL_LIGHT6* = 0x00004006
  GL_LIGHT7* = 0x00004007
  GL_AMBIENT* = 0x00001200
  GL_DIFFUSE* = 0x00001201
  GL_SPECULAR* = 0x00001202
  GL_POSITION* = 0x00001203
  GL_SPOT_DIRECTION* = 0x00001204
  GL_SPOT_EXPONENT* = 0x00001205
  GL_SPOT_CUTOFF* = 0x00001206
  GL_CONSTANT_ATTENUATION* = 0x00001207
  GL_LINEAR_ATTENUATION* = 0x00001208
  GL_QUADRATIC_ATTENUATION* = 0x00001209
  GL_COMPILE* = 0x00001300
  GL_COMPILE_AND_EXECUTE* = 0x00001301
  GL_EMISSION* = 0x00001600
  GL_SHININESS* = 0x00001601
  GL_AMBIENT_AND_DIFFUSE* = 0x00001602
  GL_COLOR_INDEXES* = 0x00001603
  GL_MODELVIEW* = 0x00001700
  GL_PROJECTION* = 0x00001701
  GL_COLOR_INDEX* = 0x00001900
  GL_LUMINANCE* = 0x00001909
  GL_LUMINANCE_ALPHA* = 0x0000190A
  cGL_BITMAP* = 0x00001A00
  GL_RENDER* = 0x00001C00
  GL_FEEDBACK* = 0x00001C01
  GL_SELECT* = 0x00001C02
  GL_FLAT* = 0x00001D00
  GL_SMOOTH* = 0x00001D01
  GL_S* = 0x00002000
  GL_T* = 0x00002001
  GL_R* = 0x00002002
  GL_Q* = 0x00002003
  GL_MODULATE* = 0x00002100
  GL_DECAL* = 0x00002101
  GL_TEXTURE_ENV_MODE* = 0x00002200
  GL_TEXTURE_ENV_COLOR* = 0x00002201
  GL_TEXTURE_ENV* = 0x00002300
  GL_EYE_LINEAR* = 0x00002400
  GL_OBJECT_LINEAR* = 0x00002401
  GL_SPHERE_MAP* = 0x00002402
  GL_TEXTURE_GEN_MODE* = 0x00002500
  GL_OBJECT_PLANE* = 0x00002501
  GL_EYE_PLANE* = 0x00002502
  GL_CLAMP* = 0x00002900
  GL_CLIENT_PIXEL_STORE_BIT* = 0x00000001
  GL_CLIENT_VERTEX_ARRAY_BIT* = 0x00000002
  GL_CLIENT_ALL_ATTRIB_BITS* = 0xFFFFFFFF
  GL_ALPHA4* = 0x0000803B
  GL_ALPHA8* = 0x0000803C
  GL_ALPHA12* = 0x0000803D
  GL_ALPHA16* = 0x0000803E
  GL_LUMINANCE4* = 0x0000803F
  GL_LUMINANCE8* = 0x00008040
  GL_LUMINANCE12* = 0x00008041
  GL_LUMINANCE16* = 0x00008042
  GL_LUMINANCE4_ALPHA4* = 0x00008043
  GL_LUMINANCE6_ALPHA2* = 0x00008044
  GL_LUMINANCE8_ALPHA8* = 0x00008045
  GL_LUMINANCE12_ALPHA4* = 0x00008046
  GL_LUMINANCE12_ALPHA12* = 0x00008047
  GL_LUMINANCE16_ALPHA16* = 0x00008048
  GL_INTENSITY* = 0x00008049
  GL_INTENSITY4* = 0x0000804A
  GL_INTENSITY8* = 0x0000804B
  GL_INTENSITY12* = 0x0000804C
  GL_INTENSITY16* = 0x0000804D
  GL_TEXTURE_LUMINANCE_SIZE* = 0x00008060
  GL_TEXTURE_INTENSITY_SIZE* = 0x00008061
  GL_TEXTURE_PRIORITY* = 0x00008066
  GL_TEXTURE_RESIDENT* = 0x00008067
  GL_VERTEX_ARRAY* = 0x00008074
  GL_NORMAL_ARRAY* = 0x00008075
  GL_COLOR_ARRAY* = 0x00008076
  GL_INDEX_ARRAY* = 0x00008077
  GL_TEXTURE_COORD_ARRAY* = 0x00008078
  GL_EDGE_FLAG_ARRAY* = 0x00008079
  GL_VERTEX_ARRAY_SIZE* = 0x0000807A
  GL_VERTEX_ARRAYtyp* = 0x0000807B
  GL_VERTEX_ARRAY_STRIDE* = 0x0000807C
  GL_NORMAL_ARRAYtyp* = 0x0000807E
  GL_NORMAL_ARRAY_STRIDE* = 0x0000807F
  GL_COLOR_ARRAY_SIZE* = 0x00008081
  GL_COLOR_ARRAYtyp* = 0x00008082
  GL_COLOR_ARRAY_STRIDE* = 0x00008083
  GL_INDEX_ARRAYtyp* = 0x00008085
  GL_INDEX_ARRAY_STRIDE* = 0x00008086
  GL_TEXTURE_COORD_ARRAY_SIZE* = 0x00008088
  GL_TEXTURE_COORD_ARRAYtyp* = 0x00008089
  GL_TEXTURE_COORD_ARRAY_STRIDE* = 0x0000808A
  GL_EDGE_FLAG_ARRAY_STRIDE* = 0x0000808C
  GL_VERTEX_ARRAY_POINTER* = 0x0000808E
  GL_NORMAL_ARRAY_POINTER* = 0x0000808F
  GL_COLOR_ARRAY_POINTER* = 0x00008090
  GL_INDEX_ARRAY_POINTER* = 0x00008091
  GL_TEXTURE_COORD_ARRAY_POINTER* = 0x00008092
  GL_EDGE_FLAG_ARRAY_POINTER* = 0x00008093
  GL_V2F* = 0x00002A20
  GL_V3F* = 0x00002A21
  GL_C4UB_V2F* = 0x00002A22
  GL_C4UB_V3F* = 0x00002A23
  GL_C3F_V3F* = 0x00002A24
  GL_N3F_V3F* = 0x00002A25
  GL_C4F_N3F_V3F* = 0x00002A26
  GL_T2F_V3F* = 0x00002A27
  GL_T4F_V4F* = 0x00002A28
  GL_T2F_C4UB_V3F* = 0x00002A29
  GL_T2F_C3F_V3F* = 0x00002A2A
  GL_T2F_N3F_V3F* = 0x00002A2B
  GL_T2F_C4F_N3F_V3F* = 0x00002A2C
  GL_T4F_C4F_N3F_V4F* = 0x00002A2D
  GL_COLOR_TABLE_FORMAT_EXT* = 0x000080D8
  GL_COLOR_TABLE_WIDTH_EXT* = 0x000080D9
  GL_COLOR_TABLE_RED_SIZE_EXT* = 0x000080DA
  GL_COLOR_TABLE_GREEN_SIZE_EXT* = 0x000080DB
  GL_COLOR_TABLE_BLUE_SIZE_EXT* = 0x000080DC
  GL_COLOR_TABLE_ALPHA_SIZE_EXT* = 0x000080DD
  GL_COLOR_TABLE_LUMINANCE_SIZE_EXT* = 0x000080DE
  GL_COLOR_TABLE_INTENSITY_SIZE_EXT* = 0x000080DF
  cGL_LOGIC_OP* = GL_INDEX_LOGIC_OP
  GL_TEXTURE_COMPONENTS* = GL_TEXTURE_INTERNAL_FORMAT # GL_VERSION_1_2
  GL_UNSIGNED_BYTE_3_3_2* = 0x00008032
  GL_UNSIGNED_SHORT_4_4_4_4* = 0x00008033
  GL_UNSIGNED_SHORT_5_5_5_1* = 0x00008034
  GL_UNSIGNED_INT_8_8_8_8* = 0x00008035
  GL_UNSIGNED_INT_10_10_10_2* = 0x00008036
  GL_TEXTURE_BINDING_3D* = 0x0000806A
  GL_PACK_SKIP_IMAGES* = 0x0000806B
  GL_PACK_IMAGE_HEIGHT* = 0x0000806C
  GL_UNPACK_SKIP_IMAGES* = 0x0000806D
  GL_UNPACK_IMAGE_HEIGHT* = 0x0000806E
  GL_TEXTURE_3D* = 0x0000806F
  GL_PROXY_TEXTURE_3D* = 0x00008070
  GL_TEXTURE_DEPTH* = 0x00008071
  GL_TEXTURE_WRAP_R* = 0x00008072
  GL_MAX_3D_TEXTURE_SIZE* = 0x00008073
  GL_UNSIGNED_BYTE_2_3_3_REV* = 0x00008362
  GL_UNSIGNED_SHORT_5_6_5* = 0x00008363
  GL_UNSIGNED_SHORT_5_6_5_REV* = 0x00008364
  GL_UNSIGNED_SHORT_4_4_4_4_REV* = 0x00008365
  GL_UNSIGNED_SHORT_1_5_5_5_REV* = 0x00008366
  GL_UNSIGNED_INT_8_8_8_8_REV* = 0x00008367
  GL_UNSIGNED_INT_2_10_10_10_REV* = 0x00008368
  GL_BGR* = 0x000080E0
  GL_BGRA* = 0x000080E1
  GL_MAX_ELEMENTS_VERTICES* = 0x000080E8
  GL_MAX_ELEMENTS_INDICES* = 0x000080E9
  GL_CLAMP_TO_EDGE* = 0x0000812F
  GL_TEXTURE_MIN_LOD* = 0x0000813A
  GL_TEXTURE_MAX_LOD* = 0x0000813B
  GL_TEXTURE_BASE_LEVEL* = 0x0000813C
  GL_TEXTURE_MAX_LEVEL* = 0x0000813D
  GL_SMOOTH_POINT_SIZE_RANGE* = 0x00000B12
  GL_SMOOTH_POINT_SIZE_GRANULARITY* = 0x00000B13
  GL_SMOOTH_LINE_WIDTH_RANGE* = 0x00000B22
  GL_SMOOTH_LINE_WIDTH_GRANULARITY* = 0x00000B23
  GL_ALIASED_LINE_WIDTH_RANGE* = 0x0000846E
  GL_RESCALE_NORMAL* = 0x0000803A
  GL_LIGHT_MODEL_COLOR_CONTROL* = 0x000081F8
  GL_SINGLE_COLOR* = 0x000081F9
  GL_SEPARATE_SPECULAR_COLOR* = 0x000081FA
  GL_ALIASED_POINT_SIZE_RANGE* = 0x0000846D # GL_VERSION_1_3
  GL_TEXTURE0* = 0x000084C0
  GL_TEXTURE1* = 0x000084C1
  GL_TEXTURE2* = 0x000084C2
  GL_TEXTURE3* = 0x000084C3
  GL_TEXTURE4* = 0x000084C4
  GL_TEXTURE5* = 0x000084C5
  GL_TEXTURE6* = 0x000084C6
  GL_TEXTURE7* = 0x000084C7
  GL_TEXTURE8* = 0x000084C8
  GL_TEXTURE9* = 0x000084C9
  GL_TEXTURE10* = 0x000084CA
  GL_TEXTURE11* = 0x000084CB
  GL_TEXTURE12* = 0x000084CC
  GL_TEXTURE13* = 0x000084CD
  GL_TEXTURE14* = 0x000084CE
  GL_TEXTURE15* = 0x000084CF
  GL_TEXTURE16* = 0x000084D0
  GL_TEXTURE17* = 0x000084D1
  GL_TEXTURE18* = 0x000084D2
  GL_TEXTURE19* = 0x000084D3
  GL_TEXTURE20* = 0x000084D4
  GL_TEXTURE21* = 0x000084D5
  GL_TEXTURE22* = 0x000084D6
  GL_TEXTURE23* = 0x000084D7
  GL_TEXTURE24* = 0x000084D8
  GL_TEXTURE25* = 0x000084D9
  GL_TEXTURE26* = 0x000084DA
  GL_TEXTURE27* = 0x000084DB
  GL_TEXTURE28* = 0x000084DC
  GL_TEXTURE29* = 0x000084DD
  GL_TEXTURE30* = 0x000084DE
  GL_TEXTURE31* = 0x000084DF
  cGL_ACTIVE_TEXTURE* = 0x000084E0
  GL_MULTISAMPLE* = 0x0000809D
  GL_SAMPLE_ALPHA_TO_COVERAGE* = 0x0000809E
  GL_SAMPLE_ALPHA_TO_ONE* = 0x0000809F
  cGL_SAMPLE_COVERAGE* = 0x000080A0
  GL_SAMPLE_BUFFERS* = 0x000080A8
  GL_SAMPLES* = 0x000080A9
  GL_SAMPLE_COVERAGE_VALUE* = 0x000080AA
  GL_SAMPLE_COVERAGE_INVERT* = 0x000080AB
  GL_TEXTURE_CUBE_MAP* = 0x00008513
  GL_TEXTURE_BINDING_CUBE_MAP* = 0x00008514
  GL_TEXTURE_CUBE_MAP_POSITIVE_X* = 0x00008515
  GL_TEXTURE_CUBE_MAP_NEGATIVE_X* = 0x00008516
  GL_TEXTURE_CUBE_MAP_POSITIVE_Y* = 0x00008517
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Y* = 0x00008518
  GL_TEXTURE_CUBE_MAP_POSITIVE_Z* = 0x00008519
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Z* = 0x0000851A
  GL_PROXY_TEXTURE_CUBE_MAP* = 0x0000851B
  GL_MAX_CUBE_MAP_TEXTURE_SIZE* = 0x0000851C
  GL_COMPRESSED_RGB* = 0x000084ED
  GL_COMPRESSED_RGBA* = 0x000084EE
  GL_TEXTURE_COMPRESSION_HINT* = 0x000084EF
  GL_TEXTURE_COMPRESSED_IMAGE_SIZE* = 0x000086A0
  GL_TEXTURE_COMPRESSED* = 0x000086A1
  GL_NUM_COMPRESSED_TEXTURE_FORMATS* = 0x000086A2
  GL_COMPRESSED_TEXTURE_FORMATS* = 0x000086A3
  GL_CLAMP_TO_BORDER* = 0x0000812D
  cGL_CLIENT_ACTIVE_TEXTURE* = 0x000084E1
  GL_MAX_TEXTURE_UNITS* = 0x000084E2
  GL_TRANSPOSE_MODELVIEW_MATRIX* = 0x000084E3
  GL_TRANSPOSE_PROJECTION_MATRIX* = 0x000084E4
  GL_TRANSPOSE_TEXTURE_MATRIX* = 0x000084E5
  GL_TRANSPOSE_COLOR_MATRIX* = 0x000084E6
  GL_MULTISAMPLE_BIT* = 0x20000000
  GL_NORMAL_MAP* = 0x00008511
  GL_REFLECTION_MAP* = 0x00008512
  GL_COMPRESSED_ALPHA* = 0x000084E9
  GL_COMPRESSED_LUMINANCE* = 0x000084EA
  GL_COMPRESSED_LUMINANCE_ALPHA* = 0x000084EB
  GL_COMPRESSED_INTENSITY* = 0x000084EC
  GL_COMBINE* = 0x00008570
  GL_COMBINE_RGB* = 0x00008571
  GL_COMBINE_ALPHA* = 0x00008572
  GL_SOURCE0_RGB* = 0x00008580
  GL_SOURCE1_RGB* = 0x00008581
  GL_SOURCE2_RGB* = 0x00008582
  GL_SOURCE0_ALPHA* = 0x00008588
  GL_SOURCE1_ALPHA* = 0x00008589
  GL_SOURCE2_ALPHA* = 0x0000858A
  GL_OPERAND0_RGB* = 0x00008590
  GL_OPERAND1_RGB* = 0x00008591
  GL_OPERAND2_RGB* = 0x00008592
  GL_OPERAND0_ALPHA* = 0x00008598
  GL_OPERAND1_ALPHA* = 0x00008599
  GL_OPERAND2_ALPHA* = 0x0000859A
  GL_RGB_SCALE* = 0x00008573
  GL_ADD_SIGNED* = 0x00008574
  GL_INTERPOLATE* = 0x00008575
  GL_SUBTRACT* = 0x000084E7
  GL_CONSTANT* = 0x00008576
  GL_PRIMARY_COLOR* = 0x00008577
  GL_PREVIOUS* = 0x00008578
  GL_DOT3_RGB* = 0x000086AE
  GL_DOT3_RGBA* = 0x000086AF  # GL_VERSION_1_4
  GL_BLEND_DST_RGB* = 0x000080C8
  GL_BLEND_SRC_RGB* = 0x000080C9
  GL_BLEND_DST_ALPHA* = 0x000080CA
  GL_BLEND_SRC_ALPHA* = 0x000080CB
  GL_POINT_FADE_THRESHOLD_SIZE* = 0x00008128
  GL_DEPTH_COMPONENT16* = 0x000081A5
  GL_DEPTH_COMPONENT24* = 0x000081A6
  GL_DEPTH_COMPONENT32* = 0x000081A7
  GL_MIRRORED_REPEAT* = 0x00008370
  GL_MAX_TEXTURE_LOD_BIAS* = 0x000084FD
  GL_TEXTURE_LOD_BIAS* = 0x00008501
  GL_INCR_WRAP* = 0x00008507
  GL_DECR_WRAP* = 0x00008508
  GL_TEXTURE_DEPTH_SIZE* = 0x0000884A
  GL_TEXTURE_COMPARE_MODE* = 0x0000884C
  GL_TEXTURE_COMPARE_FUNC* = 0x0000884D
  GL_POINT_SIZE_MIN* = 0x00008126
  GL_POINT_SIZE_MAX* = 0x00008127
  GL_POINT_DISTANCE_ATTENUATION* = 0x00008129
  cGL_GENERATE_MIPMAP* = 0x00008191
  GL_GENERATE_MIPMAP_HINT* = 0x00008192
  GL_FOG_COORDINATE_SOURCE* = 0x00008450
  GL_FOG_COORDINATE* = 0x00008451
  GL_FRAGMENT_DEPTH* = 0x00008452
  GL_CURRENT_FOG_COORDINATE* = 0x00008453
  GL_FOG_COORDINATE_ARRAYtyp* = 0x00008454
  GL_FOG_COORDINATE_ARRAY_STRIDE* = 0x00008455
  GL_FOG_COORDINATE_ARRAY_POINTER* = 0x00008456
  GL_FOG_COORDINATE_ARRAY* = 0x00008457
  GL_COLOR_SUM* = 0x00008458
  GL_CURRENT_SECONDARY_COLOR* = 0x00008459
  GL_SECONDARY_COLOR_ARRAY_SIZE* = 0x0000845A
  GL_SECONDARY_COLOR_ARRAYtyp* = 0x0000845B
  GL_SECONDARY_COLOR_ARRAY_STRIDE* = 0x0000845C
  GL_SECONDARY_COLOR_ARRAY_POINTER* = 0x0000845D
  GL_SECONDARY_COLOR_ARRAY* = 0x0000845E
  GL_TEXTURE_FILTER_CONTROL* = 0x00008500
  GL_DEPTH_TEXTURE_MODE* = 0x0000884B
  GL_COMPARE_R_TO_TEXTURE* = 0x0000884E # GL_VERSION_1_5
  GL_BUFFER_SIZE* = 0x00008764
  GL_BUFFER_USAGE* = 0x00008765
  GL_QUERY_COUNTER_BITS* = 0x00008864
  GL_CURRENT_QUERY* = 0x00008865
  GL_QUERY_RESULT* = 0x00008866
  GL_QUERY_RESULT_AVAILABLE* = 0x00008867
  GL_ARRAY_BUFFER* = 0x00008892
  GL_ELEMENT_ARRAY_BUFFER* = 0x00008893
  GL_ARRAY_BUFFER_BINDING* = 0x00008894
  GL_ELEMENT_ARRAY_BUFFER_BINDING* = 0x00008895
  GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING* = 0x0000889F
  GL_READ_ONLY* = 0x000088B8
  GL_WRITE_ONLY* = 0x000088B9
  GL_READ_WRITE* = 0x000088BA
  GL_BUFFER_ACCESS* = 0x000088BB
  GL_BUFFER_MAPPED* = 0x000088BC
  GL_BUFFER_MAP_POINTER* = 0x000088BD
  GL_STREAM_DRAW* = 0x000088E0
  GL_STREAM_READ* = 0x000088E1
  GL_STREAM_COPY* = 0x000088E2
  GL_STATIC_DRAW* = 0x000088E4
  GL_STATIC_READ* = 0x000088E5
  GL_STATIC_COPY* = 0x000088E6
  GL_DYNAMIC_DRAW* = 0x000088E8
  GL_DYNAMIC_READ* = 0x000088E9
  GL_DYNAMIC_COPY* = 0x000088EA
  GL_SAMPLES_PASSED* = 0x00008914
  GL_VERTEX_ARRAY_BUFFER_BINDING* = 0x00008896
  GL_NORMAL_ARRAY_BUFFER_BINDING* = 0x00008897
  GL_COLOR_ARRAY_BUFFER_BINDING* = 0x00008898
  GL_INDEX_ARRAY_BUFFER_BINDING* = 0x00008899
  GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING* = 0x0000889A
  GL_EDGE_FLAG_ARRAY_BUFFER_BINDING* = 0x0000889B
  GL_SECONDARY_COLOR_ARRAY_BUFFER_BINDING* = 0x0000889C
  GL_FOG_COORDINATE_ARRAY_BUFFER_BINDING* = 0x0000889D
  GL_WEIGHT_ARRAY_BUFFER_BINDING* = 0x0000889E
  GL_FOG_COORD_SRC* = 0x00008450
  GL_FOG_COORD* = 0x00008451
  GL_CURRENT_FOG_COORD* = 0x00008453
  GL_FOG_COORD_ARRAYtyp* = 0x00008454
  GL_FOG_COORD_ARRAY_STRIDE* = 0x00008455
  GL_FOG_COORD_ARRAY_POINTER* = 0x00008456
  GL_FOG_COORD_ARRAY* = 0x00008457
  GL_FOG_COORD_ARRAY_BUFFER_BINDING* = 0x0000889D
  GL_SRC0_RGB* = 0x00008580
  GL_SRC1_RGB* = 0x00008581
  GL_SRC2_RGB* = 0x00008582
  GL_SRC0_ALPHA* = 0x00008588
  GL_SRC1_ALPHA* = 0x00008589
  GL_SRC2_ALPHA* = 0x0000858A # GL_VERSION_2_0
  GL_BLEND_EQUATION_RGB* = 0x00008009
  GL_VERTEX_ATTRIB_ARRAY_ENABLED* = 0x00008622
  GL_VERTEX_ATTRIB_ARRAY_SIZE* = 0x00008623
  GL_VERTEX_ATTRIB_ARRAY_STRIDE* = 0x00008624
  GL_VERTEX_ATTRIB_ARRAYtyp* = 0x00008625
  GL_CURRENT_VERTEX_ATTRIB* = 0x00008626
  GL_VERTEX_PROGRAM_POINT_SIZE* = 0x00008642
  GL_VERTEX_ATTRIB_ARRAY_POINTER* = 0x00008645
  GL_STENCIL_BACK_FUNC* = 0x00008800
  GL_STENCIL_BACK_FAIL* = 0x00008801
  GL_STENCIL_BACK_PASS_DEPTH_FAIL* = 0x00008802
  GL_STENCIL_BACK_PASS_DEPTH_PASS* = 0x00008803
  GL_MAX_DRAW_BUFFERS* = 0x00008824
  GL_DRAW_BUFFER0* = 0x00008825
  GL_DRAW_BUFFER1* = 0x00008826
  GL_DRAW_BUFFER2* = 0x00008827
  GL_DRAW_BUFFER3* = 0x00008828
  GL_DRAW_BUFFER4* = 0x00008829
  GL_DRAW_BUFFER5* = 0x0000882A
  GL_DRAW_BUFFER6* = 0x0000882B
  GL_DRAW_BUFFER7* = 0x0000882C
  GL_DRAW_BUFFER8* = 0x0000882D
  GL_DRAW_BUFFER9* = 0x0000882E
  GL_DRAW_BUFFER10* = 0x0000882F
  GL_DRAW_BUFFER11* = 0x00008830
  GL_DRAW_BUFFER12* = 0x00008831
  GL_DRAW_BUFFER13* = 0x00008832
  GL_DRAW_BUFFER14* = 0x00008833
  GL_DRAW_BUFFER15* = 0x00008834
  GL_BLEND_EQUATION_ALPHA* = 0x0000883D
  GL_MAX_VERTEX_ATTRIBS* = 0x00008869
  GL_VERTEX_ATTRIB_ARRAY_NORMALIZED* = 0x0000886A
  GL_MAX_TEXTURE_IMAGE_UNITS* = 0x00008872
  GL_FRAGMENT_SHADER* = 0x00008B30
  GL_VERTEX_SHADER* = 0x00008B31
  GL_MAX_FRAGMENT_UNIFORM_COMPONENTS* = 0x00008B49
  GL_MAX_VERTEX_UNIFORM_COMPONENTS* = 0x00008B4A
  GL_MAX_VARYING_FLOATS* = 0x00008B4B
  GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS* = 0x00008B4C
  GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS* = 0x00008B4D
  GL_SHADERtyp* = 0x00008B4F
  GL_FLOAT_VEC2* = 0x00008B50
  GL_FLOAT_VEC3* = 0x00008B51
  GL_FLOAT_VEC4* = 0x00008B52
  GL_INT_VEC2* = 0x00008B53
  GL_INT_VEC3* = 0x00008B54
  GL_INT_VEC4* = 0x00008B55
  GL_BOOL* = 0x00008B56
  GL_BOOL_VEC2* = 0x00008B57
  GL_BOOL_VEC3* = 0x00008B58
  GL_BOOL_VEC4* = 0x00008B59
  GL_FLOAT_MAT2* = 0x00008B5A
  GL_FLOAT_MAT3* = 0x00008B5B
  GL_FLOAT_MAT4* = 0x00008B5C
  GL_SAMPLER_1D* = 0x00008B5D
  GL_SAMPLER_2D* = 0x00008B5E
  GL_SAMPLER_3D* = 0x00008B5F
  GL_SAMPLER_CUBE* = 0x00008B60
  GL_SAMPLER_1D_SHADOW* = 0x00008B61
  GL_SAMPLER_2D_SHADOW* = 0x00008B62
  GL_DELETE_STATUS* = 0x00008B80
  GL_COMPILE_STATUS* = 0x00008B81
  GL_LINK_STATUS* = 0x00008B82
  GL_VALIDATE_STATUS* = 0x00008B83
  GL_INFO_LOG_LENGTH* = 0x00008B84
  GL_ATTACHED_SHADERS* = 0x00008B85
  GL_ACTIVE_UNIFORMS* = 0x00008B86
  GL_ACTIVE_UNIFORM_MAX_LENGTH* = 0x00008B87
  GL_SHADER_SOURCE_LENGTH* = 0x00008B88
  GL_ACTIVE_ATTRIBUTES* = 0x00008B89
  GL_ACTIVE_ATTRIBUTE_MAX_LENGTH* = 0x00008B8A
  GL_FRAGMENT_SHADER_DERIVATIVE_HINT* = 0x00008B8B
  GL_SHADING_LANGUAGE_VERSION* = 0x00008B8C
  GL_CURRENT_PROGRAM* = 0x00008B8D
  GL_POINT_SPRITE_COORD_ORIGIN* = 0x00008CA0
  GL_LOWER_LEFT* = 0x00008CA1
  GL_UPPER_LEFT* = 0x00008CA2
  GL_STENCIL_BACK_REF* = 0x00008CA3
  GL_STENCIL_BACK_VALUE_MASK* = 0x00008CA4
  GL_STENCIL_BACK_WRITEMASK* = 0x00008CA5
  GL_VERTEX_PROGRAM_TWO_SIDE* = 0x00008643
  GL_POINT_SPRITE* = 0x00008861
  GL_COORD_REPLACE* = 0x00008862
  GL_MAX_TEXTURE_COORDS* = 0x00008871 # GL_VERSION_2_1
  GL_PIXEL_PACK_BUFFER* = 0x000088EB
  GL_PIXEL_UNPACK_BUFFER* = 0x000088EC
  GL_PIXEL_PACK_BUFFER_BINDING* = 0x000088ED
  GL_PIXEL_UNPACK_BUFFER_BINDING* = 0x000088EF
  GL_FLOAT_MAT2x3* = 0x00008B65
  GL_FLOAT_MAT2x4* = 0x00008B66
  GL_FLOAT_MAT3x2* = 0x00008B67
  GL_FLOAT_MAT3x4* = 0x00008B68
  GL_FLOAT_MAT4x2* = 0x00008B69
  GL_FLOAT_MAT4x3* = 0x00008B6A
  GL_SRGB* = 0x00008C40
  GL_SRGB8* = 0x00008C41
  GL_SRGB_ALPHA* = 0x00008C42
  GL_SRGB8_ALPHA8* = 0x00008C43
  GL_COMPRESSED_SRGB* = 0x00008C48
  GL_COMPRESSED_SRGB_ALPHA* = 0x00008C49
  GL_CURRENT_RASTER_SECONDARY_COLOR* = 0x0000845F
  GL_SLUMINANCE_ALPHA* = 0x00008C44
  GL_SLUMINANCE8_ALPHA8* = 0x00008C45
  GL_SLUMINANCE* = 0x00008C46
  GL_SLUMINANCE8* = 0x00008C47
  GL_COMPRESSED_SLUMINANCE* = 0x00008C4A
  GL_COMPRESSED_SLUMINANCE_ALPHA* = 0x00008C4B # GL_VERSION_3_0
  GL_COMPARE_REF_TO_TEXTURE* = 0x0000884E
  GL_CLIP_DISTANCE0* = 0x00003000
  GL_CLIP_DISTANCE1* = 0x00003001
  GL_CLIP_DISTANCE2* = 0x00003002
  GL_CLIP_DISTANCE3* = 0x00003003
  GL_CLIP_DISTANCE4* = 0x00003004
  GL_CLIP_DISTANCE5* = 0x00003005
  GL_CLIP_DISTANCE6* = 0x00003006
  GL_CLIP_DISTANCE7* = 0x00003007
  GL_MAX_CLIP_DISTANCES* = 0x00000D32
  GL_MAJOR_VERSION* = 0x0000821B
  GL_MINOR_VERSION* = 0x0000821C
  GL_NUM_EXTENSIONS* = 0x0000821D
  GL_CONTEXT_FLAGS* = 0x0000821E
  GL_DEPTH_BUFFER* = 0x00008223
  GL_STENCIL_BUFFER* = 0x00008224
  GL_COMPRESSED_RED* = 0x00008225
  GL_COMPRESSED_RG* = 0x00008226
  GL_CONTEXT_FLAG_FORWARD_COMPATIBLE_BIT* = 0x00000001
  GL_RGBA32F* = 0x00008814
  GL_RGB32F* = 0x00008815
  GL_RGBA16F* = 0x0000881A
  GL_RGB16F* = 0x0000881B
  GL_VERTEX_ATTRIB_ARRAY_INTEGER* = 0x000088FD
  GL_MAX_ARRAY_TEXTURE_LAYERS* = 0x000088FF
  GL_MIN_PROGRAM_TEXEL_OFFSET* = 0x00008904
  GL_MAX_PROGRAM_TEXEL_OFFSET* = 0x00008905
  GL_CLAMP_READ_COLOR* = 0x0000891C
  GL_FIXED_ONLY* = 0x0000891D
  GL_MAX_VARYING_COMPONENTS* = 0x00008B4B
  GL_TEXTURE_1D_ARRAY* = 0x00008C18
  GL_PROXY_TEXTURE_1D_ARRAY* = 0x00008C19
  GL_TEXTURE_2D_ARRAY* = 0x00008C1A
  GL_PROXY_TEXTURE_2D_ARRAY* = 0x00008C1B
  GL_TEXTURE_BINDING_1D_ARRAY* = 0x00008C1C
  GL_TEXTURE_BINDING_2D_ARRAY* = 0x00008C1D
  GL_R11F_G11F_B10F* = 0x00008C3A
  GL_UNSIGNED_INT_10F_11F_11F_REV* = 0x00008C3B
  GL_RGB9_E5* = 0x00008C3D
  GL_UNSIGNED_INT_5_9_9_9_REV* = 0x00008C3E
  GL_TEXTURE_SHARED_SIZE* = 0x00008C3F
  GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH* = 0x00008C76
  GL_TRANSFORM_FEEDBACK_BUFFER_MODE* = 0x00008C7F
  GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS* = 0x00008C80
  cGL_TRANSFORM_FEEDBACK_VARYINGS* = 0x00008C83
  GL_TRANSFORM_FEEDBACK_BUFFER_START* = 0x00008C84
  GL_TRANSFORM_FEEDBACK_BUFFER_SIZE* = 0x00008C85
  GL_PRIMITIVES_GENERATED* = 0x00008C87
  GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN* = 0x00008C88
  GL_RASTERIZER_DISCARD* = 0x00008C89
  GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS* = 0x00008C8A
  GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS* = 0x00008C8B
  GL_INTERLEAVED_ATTRIBS* = 0x00008C8C
  GL_SEPARATE_ATTRIBS* = 0x00008C8D
  GL_TRANSFORM_FEEDBACK_BUFFER* = 0x00008C8E
  GL_TRANSFORM_FEEDBACK_BUFFER_BINDING* = 0x00008C8F
  GL_RGBA32UI* = 0x00008D70
  GL_RGB32UI* = 0x00008D71
  GL_RGBA16UI* = 0x00008D76
  GL_RGB16UI* = 0x00008D77
  GL_RGBA8UI* = 0x00008D7C
  GL_RGB8UI* = 0x00008D7D
  GL_RGBA32I* = 0x00008D82
  GL_RGB32I* = 0x00008D83
  GL_RGBA16I* = 0x00008D88
  GL_RGB16I* = 0x00008D89
  GL_RGBA8I* = 0x00008D8E
  GL_RGB8I* = 0x00008D8F
  GL_RED_INTEGER* = 0x00008D94
  GL_GREEN_INTEGER* = 0x00008D95
  GL_BLUE_INTEGER* = 0x00008D96
  GL_RGB_INTEGER* = 0x00008D98
  GL_RGBA_INTEGER* = 0x00008D99
  GL_BGR_INTEGER* = 0x00008D9A
  GL_BGRA_INTEGER* = 0x00008D9B
  GL_SAMPLER_1D_ARRAY* = 0x00008DC0
  GL_SAMPLER_2D_ARRAY* = 0x00008DC1
  GL_SAMPLER_1D_ARRAY_SHADOW* = 0x00008DC3
  GL_SAMPLER_2D_ARRAY_SHADOW* = 0x00008DC4
  GL_SAMPLER_CUBE_SHADOW* = 0x00008DC5
  GL_UNSIGNED_INT_VEC2* = 0x00008DC6
  GL_UNSIGNED_INT_VEC3* = 0x00008DC7
  GL_UNSIGNED_INT_VEC4* = 0x00008DC8
  GL_INT_SAMPLER_1D* = 0x00008DC9
  GL_INT_SAMPLER_2D* = 0x00008DCA
  GL_INT_SAMPLER_3D* = 0x00008DCB
  GL_INT_SAMPLER_CUBE* = 0x00008DCC
  GL_INT_SAMPLER_1D_ARRAY* = 0x00008DCE
  GL_INT_SAMPLER_2D_ARRAY* = 0x00008DCF
  GL_UNSIGNED_INT_SAMPLER_1D* = 0x00008DD1
  GL_UNSIGNED_INT_SAMPLER_2D* = 0x00008DD2
  GL_UNSIGNED_INT_SAMPLER_3D* = 0x00008DD3
  GL_UNSIGNED_INT_SAMPLER_CUBE* = 0x00008DD4
  GL_UNSIGNED_INT_SAMPLER_1D_ARRAY* = 0x00008DD6
  GL_UNSIGNED_INT_SAMPLER_2D_ARRAY* = 0x00008DD7
  GL_QUERY_WAIT* = 0x00008E13
  GL_QUERY_NO_WAIT* = 0x00008E14
  GL_QUERY_BY_REGION_WAIT* = 0x00008E15
  GL_QUERY_BY_REGION_NO_WAIT* = 0x00008E16
  GL_BUFFER_ACCESS_FLAGS* = 0x0000911F
  GL_BUFFER_MAP_LENGTH* = 0x00009120
  GL_BUFFER_MAP_OFFSET* = 0x00009121
  GL_CLAMP_VERTEX_COLOR* = 0x0000891A
  GL_CLAMP_FRAGMENT_COLOR* = 0x0000891B
  GL_ALPHA_INTEGER* = 0x00008D97 # GL_VERSION_3_1
  GL_SAMPLER_2D_RECT* = 0x00008B63
  GL_SAMPLER_2D_RECT_SHADOW* = 0x00008B64
  GL_SAMPLER_BUFFER* = 0x00008DC2
  GL_INT_SAMPLER_2D_RECT* = 0x00008DCD
  GL_INT_SAMPLER_BUFFER* = 0x00008DD0
  GL_UNSIGNED_INT_SAMPLER_2D_RECT* = 0x00008DD5
  GL_UNSIGNED_INT_SAMPLER_BUFFER* = 0x00008DD8
  GL_TEXTURE_BUFFER* = 0x00008C2A
  GL_MAX_TEXTURE_BUFFER_SIZE* = 0x00008C2B
  GL_TEXTURE_BINDING_BUFFER* = 0x00008C2C
  GL_TEXTURE_BUFFER_DATA_STORE_BINDING* = 0x00008C2D
  GL_TEXTURE_BUFFER_FORMAT* = 0x00008C2E
  GL_TEXTURE_RECTANGLE* = 0x000084F5
  GL_TEXTURE_BINDING_RECTANGLE* = 0x000084F6
  GL_PROXY_TEXTURE_RECTANGLE* = 0x000084F7
  GL_MAX_RECTANGLE_TEXTURE_SIZE* = 0x000084F8
  GL_RED_SNORM* = 0x00008F90
  GL_RG_SNORM* = 0x00008F91
  GL_RGB_SNORM* = 0x00008F92
  GL_RGBA_SNORM* = 0x00008F93
  GL_R8_SNORM* = 0x00008F94
  GL_RG8_SNORM* = 0x00008F95
  GL_RGB8_SNORM* = 0x00008F96
  GL_RGBA8_SNORM* = 0x00008F97
  GL_R16_SNORM* = 0x00008F98
  GL_RG16_SNORM* = 0x00008F99
  GL_RGB16_SNORM* = 0x00008F9A
  GL_RGBA16_SNORM* = 0x00008F9B
  GL_SIGNED_NORMALIZED* = 0x00008F9C
  GL_PRIMITIVE_RESTART* = 0x00008F9D
  cGL_PRIMITIVE_RESTART_INDEX* = 0x00008F9E
  GL_CONTEXT_CORE_PROFILE_BIT* = 0x00000001
  GL_CONTEXT_COMPATIBILITY_PROFILE_BIT* = 0x00000002
  GL_LINES_ADJACENCY* = 0x0000000A
  GL_LINE_STRIP_ADJACENCY* = 0x0000000B
  GL_TRIANGLES_ADJACENCY* = 0x0000000C
  GL_TRIANGLE_STRIP_ADJACENCY* = 0x0000000D
  GL_PROGRAM_POINT_SIZE* = 0x00008642
  GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS* = 0x00008C29
  GL_FRAMEBUFFER_ATTACHMENT_LAYERED* = 0x00008DA7
  GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS* = 0x00008DA8
  GL_GEOMETRY_SHADER* = 0x00008DD9
  GL_GEOMETRY_VERTICES_OUT* = 0x00008916
  GL_GEOMETRY_INPUTtyp* = 0x00008917
  GL_GEOMETRY_OUTPUTtyp* = 0x00008918
  GL_MAX_GEOMETRY_UNIFORM_COMPONENTS* = 0x00008DDF
  GL_MAX_GEOMETRY_OUTPUT_VERTICES* = 0x00008DE0
  GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS* = 0x00008DE1
  GL_MAX_VERTEX_OUTPUT_COMPONENTS* = 0x00009122
  GL_MAX_GEOMETRY_INPUT_COMPONENTS* = 0x00009123
  GL_MAX_GEOMETRY_OUTPUT_COMPONENTS* = 0x00009124
  GL_MAX_FRAGMENT_INPUT_COMPONENTS* = 0x00009125
  GL_CONTEXT_PROFILE_MASK* = 0x00009126 # GL_VERSION_3_3
  GL_VERTEX_ATTRIB_ARRAY_DIVISOR* = 0x000088FE # GL_VERSION_4_0
  GL_SAMPLE_SHADING* = 0x00008C36
  GL_MIN_SAMPLE_SHADING_VALUE* = 0x00008C37
  GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET* = 0x00008E5E
  GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET* = 0x00008E5F
  GL_TEXTURE_CUBE_MAP_ARRAY* = 0x00009009
  GL_TEXTURE_BINDING_CUBE_MAP_ARRAY* = 0x0000900A
  GL_PROXY_TEXTURE_CUBE_MAP_ARRAY* = 0x0000900B
  GL_SAMPLER_CUBE_MAP_ARRAY* = 0x0000900C
  GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW* = 0x0000900D
  GL_INT_SAMPLER_CUBE_MAP_ARRAY* = 0x0000900E
  GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY* = 0x0000900F # GL_3DFX_multisample
  GL_MULTISAMPLE_3DFX* = 0x000086B2
  GL_SAMPLE_BUFFERS_3DFX* = 0x000086B3
  GL_SAMPLES_3DFX* = 0x000086B4
  GL_MULTISAMPLE_BIT_3DFX* = 0x20000000 # GL_3DFX_texture_compression_FXT1
  GL_COMPRESSED_RGB_FXT1_3DFX* = 0x000086B0
  GL_COMPRESSED_RGBA_FXT1_3DFX* = 0x000086B1 # GL_APPLE_client_storage
  GL_UNPACK_CLIENT_STORAGE_APPLE* = 0x000085B2 # GL_APPLE_element_array
  GL_ELEMENT_ARRAY_APPLE* = 0x00008A0C
  GL_ELEMENT_ARRAYtyp_APPLE* = 0x00008A0D
  GL_ELEMENT_ARRAY_POINTER_APPLE* = 0x00008A0E # GL_APPLE_fence
  GL_DRAW_PIXELS_APPLE* = 0x00008A0A
  GL_FENCE_APPLE* = 0x00008A0B # GL_APPLE_specular_vector
  GL_LIGHT_MODEL_SPECULAR_VECTOR_APPLE* = 0x000085B0 # GL_APPLE_transform_hint
  GL_TRANSFORM_HINT_APPLE* = 0x000085B1 # GL_APPLE_vertex_array_object
  GL_VERTEX_ARRAY_BINDING_APPLE* = 0x000085B5 # GL_APPLE_vertex_array_range
  cGL_VERTEX_ARRAY_RANGE_APPLE* = 0x0000851D
  GL_VERTEX_ARRAY_RANGE_LENGTH_APPLE* = 0x0000851E
  GL_VERTEX_ARRAY_STORAGE_HINT_APPLE* = 0x0000851F
  GL_VERTEX_ARRAY_RANGE_POINTER_APPLE* = 0x00008521
  GL_STORAGE_CLIENT_APPLE* = 0x000085B4
  GL_STORAGE_CACHED_APPLE* = 0x000085BE
  GL_STORAGE_SHARED_APPLE* = 0x000085BF # GL_APPLE_ycbcr_422
  GL_YCBCR_422_APPLE* = 0x000085B9
  GL_UNSIGNED_SHORT_8_8_APPLE* = 0x000085BA
  GL_UNSIGNED_SHORT_8_8_REV_APPLE* = 0x000085BB # GL_APPLE_texture_range
  GL_TEXTURE_RANGE_LENGTH_APPLE* = 0x000085B7
  GL_TEXTURE_RANGE_POINTER_APPLE* = 0x000085B8
  GL_TEXTURE_STORAGE_HINT_APPLE* = 0x000085BC
  GL_STORAGE_PRIVATE_APPLE* = 0x000085BD # reuse GL_STORAGE_CACHED_APPLE
                                         # reuse GL_STORAGE_SHARED_APPLE
                                         # GL_APPLE_float_pixels
  GL_HALF_APPLE* = 0x0000140B
  GL_RGBA_FLOAT32_APPLE* = 0x00008814
  GL_RGB_FLOAT32_APPLE* = 0x00008815
  GL_ALPHA_FLOAT32_APPLE* = 0x00008816
  GL_INTENSITY_FLOAT32_APPLE* = 0x00008817
  GL_LUMINANCE_FLOAT32_APPLE* = 0x00008818
  GL_LUMINANCE_ALPHA_FLOAT32_APPLE* = 0x00008819
  GL_RGBA_FLOAT16_APPLE* = 0x0000881A
  GL_RGB_FLOAT16_APPLE* = 0x0000881B
  GL_ALPHA_FLOAT16_APPLE* = 0x0000881C
  GL_INTENSITY_FLOAT16_APPLE* = 0x0000881D
  GL_LUMINANCE_FLOAT16_APPLE* = 0x0000881E
  GL_LUMINANCE_ALPHA_FLOAT16_APPLE* = 0x0000881F
  GL_COLOR_FLOAT_APPLE* = 0x00008A0F # GL_APPLE_vertex_program_evaluators
  GL_VERTEX_ATTRIB_MAP1_APPLE* = 0x00008A00
  GL_VERTEX_ATTRIB_MAP2_APPLE* = 0x00008A01
  GL_VERTEX_ATTRIB_MAP1_SIZE_APPLE* = 0x00008A02
  GL_VERTEX_ATTRIB_MAP1_COEFF_APPLE* = 0x00008A03
  GL_VERTEX_ATTRIB_MAP1_ORDER_APPLE* = 0x00008A04
  GL_VERTEX_ATTRIB_MAP1_DOMAIN_APPLE* = 0x00008A05
  GL_VERTEX_ATTRIB_MAP2_SIZE_APPLE* = 0x00008A06
  GL_VERTEX_ATTRIB_MAP2_COEFF_APPLE* = 0x00008A07
  GL_VERTEX_ATTRIB_MAP2_ORDER_APPLE* = 0x00008A08
  GL_VERTEX_ATTRIB_MAP2_DOMAIN_APPLE* = 0x00008A09 # GL_APPLE_aux_depth_stencil
  GL_AUX_DEPTH_STENCIL_APPLE* = 0x00008A14 # GL_APPLE_object_purgeable
  GL_BUFFER_OBJECT_APPLE* = 0x000085B3
  GL_RELEASED_APPLE* = 0x00008A19
  GL_VOLATILE_APPLE* = 0x00008A1A
  GL_RETAINED_APPLE* = 0x00008A1B
  GL_UNDEFINED_APPLE* = 0x00008A1C
  GL_PURGEABLE_APPLE* = 0x00008A1D # GL_APPLE_row_bytes
  GL_PACK_ROW_BYTES_APPLE* = 0x00008A15
  GL_UNPACK_ROW_BYTES_APPLE* = 0x00008A16 # GL_APPLE_rgb_422
                                          # reuse GL_UNSIGNED_SHORT_8_8_APPLE
                                          # reuse GL_UNSIGNED_SHORT_8_8_REV_APPLE
                                          # GL_ARB_depth_texture
  GL_DEPTH_COMPONENT16_ARB* = 0x000081A5
  GL_DEPTH_COMPONENT24_ARB* = 0x000081A6
  GL_DEPTH_COMPONENT32_ARB* = 0x000081A7
  GL_TEXTURE_DEPTH_SIZE_ARB* = 0x0000884A
  GL_DEPTH_TEXTURE_MODE_ARB* = 0x0000884B # GL_ARB_fragment_program
  GL_FRAGMENT_PROGRAM_ARB* = 0x00008804
  GL_PROGRAM_ALU_INSTRUCTIONS_ARB* = 0x00008805
  GL_PROGRAM_TEX_INSTRUCTIONS_ARB* = 0x00008806
  GL_PROGRAM_TEX_INDIRECTIONS_ARB* = 0x00008807
  GL_PROGRAM_NATIVE_ALU_INSTRUCTIONS_ARB* = 0x00008808
  GL_PROGRAM_NATIVE_TEX_INSTRUCTIONS_ARB* = 0x00008809
  GL_PROGRAM_NATIVE_TEX_INDIRECTIONS_ARB* = 0x0000880A
  GL_MAX_PROGRAM_ALU_INSTRUCTIONS_ARB* = 0x0000880B
  GL_MAX_PROGRAM_TEX_INSTRUCTIONS_ARB* = 0x0000880C
  GL_MAX_PROGRAM_TEX_INDIRECTIONS_ARB* = 0x0000880D
  GL_MAX_PROGRAM_NATIVE_ALU_INSTRUCTIONS_ARB* = 0x0000880E
  GL_MAX_PROGRAM_NATIVE_TEX_INSTRUCTIONS_ARB* = 0x0000880F
  GL_MAX_PROGRAM_NATIVE_TEX_INDIRECTIONS_ARB* = 0x00008810
  GL_MAX_TEXTURE_COORDS_ARB* = 0x00008871
  GL_MAX_TEXTURE_IMAGE_UNITS_ARB* = 0x00008872 # GL_ARB_imaging
  GL_CONSTANT_COLOR_ARB* = 0x00008001
  GL_ONE_MINUS_CONSTANT_COLOR* = 0x00008002
  GL_CONSTANT_ALPHA* = 0x00008003
  GL_ONE_MINUS_CONSTANT_ALPHA* = 0x00008004
  cGL_BLEND_COLOR* = 0x00008005
  GL_FUNC_ADD* = 0x00008006
  GL_MIN* = 0x00008007
  GL_MAX* = 0x00008008
  cGL_BLEND_EQUATION* = 0x00008009
  GL_FUNC_SUBTRACT* = 0x0000800A
  GL_FUNC_REVERSE_SUBTRACT* = 0x0000800B
  GL_CONVOLUTION_1D* = 0x00008010
  GL_CONVOLUTION_2D* = 0x00008011
  GL_SEPARABLE_2D* = 0x00008012
  GL_CONVOLUTION_BORDER_MODE* = 0x00008013
  GL_CONVOLUTION_FILTER_SCALE* = 0x00008014
  GL_CONVOLUTION_FILTER_BIAS* = 0x00008015
  GL_REDUCE* = 0x00008016
  GL_CONVOLUTION_FORMAT* = 0x00008017
  GL_CONVOLUTION_WIDTH* = 0x00008018
  GL_CONVOLUTION_HEIGHT* = 0x00008019
  GL_MAX_CONVOLUTION_WIDTH* = 0x0000801A
  GL_MAX_CONVOLUTION_HEIGHT* = 0x0000801B
  GL_POST_CONVOLUTION_RED_SCALE* = 0x0000801C
  GL_POST_CONVOLUTION_GREEN_SCALE* = 0x0000801D
  GL_POST_CONVOLUTION_BLUE_SCALE* = 0x0000801E
  GL_POST_CONVOLUTION_ALPHA_SCALE* = 0x0000801F
  GL_POST_CONVOLUTION_RED_BIAS* = 0x00008020
  GL_POST_CONVOLUTION_GREEN_BIAS* = 0x00008021
  GL_POST_CONVOLUTION_BLUE_BIAS* = 0x00008022
  GL_POST_CONVOLUTION_ALPHA_BIAS* = 0x00008023
  cGL_HISTOGRAM* = 0x00008024
  GL_PROXY_HISTOGRAM* = 0x00008025
  GL_HISTOGRAM_WIDTH* = 0x00008026
  GL_HISTOGRAM_FORMAT* = 0x00008027
  GL_HISTOGRAM_RED_SIZE* = 0x00008028
  GL_HISTOGRAM_GREEN_SIZE* = 0x00008029
  GL_HISTOGRAM_BLUE_SIZE* = 0x0000802A
  GL_HISTOGRAM_ALPHA_SIZE* = 0x0000802B
  GL_HISTOGRAM_LUMINANCE_SIZE* = 0x0000802C
  GL_HISTOGRAM_SINK* = 0x0000802D
  cGL_MINMAX* = 0x0000802E
  GL_MINMAX_FORMAT* = 0x0000802F
  GL_MINMAX_SINK* = 0x00008030
  GL_TABLE_TOO_LARGE* = 0x00008031
  GL_COLOR_MATRIX* = 0x000080B1
  GL_COLOR_MATRIX_STACK_DEPTH* = 0x000080B2
  GL_MAX_COLOR_MATRIX_STACK_DEPTH* = 0x000080B3
  GL_POST_COLOR_MATRIX_RED_SCALE* = 0x000080B4
  GL_POST_COLOR_MATRIX_GREEN_SCALE* = 0x000080B5
  GL_POST_COLOR_MATRIX_BLUE_SCALE* = 0x000080B6
  GL_POST_COLOR_MATRIX_ALPHA_SCALE* = 0x000080B7
  GL_POST_COLOR_MATRIX_RED_BIAS* = 0x000080B8
  GL_POST_COLOR_MATRIX_GREEN_BIAS* = 0x000080B9
  GL_POST_COLOR_MATRIX_BLUE_BIAS* = 0x000080BA
  GL_POST_COLOR_MATRIX_ALPHA_BIAS* = 0x000080BB
  cGL_COLOR_TABLE* = 0x000080D0
  GL_POST_CONVOLUTION_COLOR_TABLE* = 0x000080D1
  GL_POST_COLOR_MATRIX_COLOR_TABLE* = 0x000080D2
  GL_PROXY_COLOR_TABLE* = 0x000080D3
  GL_PROXY_POST_CONVOLUTION_COLOR_TABLE* = 0x000080D4
  GL_PROXY_POST_COLOR_MATRIX_COLOR_TABLE* = 0x000080D5
  GL_COLOR_TABLE_SCALE* = 0x000080D6
  GL_COLOR_TABLE_BIAS* = 0x000080D7
  GL_COLOR_TABLE_FORMAT* = 0x000080D8
  GL_COLOR_TABLE_WIDTH* = 0x000080D9
  GL_COLOR_TABLE_RED_SIZE* = 0x000080DA
  GL_COLOR_TABLE_GREEN_SIZE* = 0x000080DB
  GL_COLOR_TABLE_BLUE_SIZE* = 0x000080DC
  GL_COLOR_TABLE_ALPHA_SIZE* = 0x000080DD
  GL_COLOR_TABLE_LUMINANCE_SIZE* = 0x000080DE
  GL_COLOR_TABLE_INTENSITY_SIZE* = 0x000080DF
  GL_CONSTANT_BORDER* = 0x00008151
  GL_REPLICATE_BORDER* = 0x00008153
  GL_CONVOLUTION_BORDER_COLOR* = 0x00008154 # GL_ARB_matrix_palette
  GL_MATRIX_PALETTE_ARB* = 0x00008840
  GL_MAX_MATRIX_PALETTE_STACK_DEPTH_ARB* = 0x00008841
  GL_MAX_PALETTE_MATRICES_ARB* = 0x00008842
  cGL_CURRENT_PALETTE_MATRIX_ARB* = 0x00008843
  GL_MATRIX_INDEX_ARRAY_ARB* = 0x00008844
  GL_CURRENT_MATRIX_INDEX_ARB* = 0x00008845
  GL_MATRIX_INDEX_ARRAY_SIZE_ARB* = 0x00008846
  GL_MATRIX_INDEX_ARRAYtyp_ARB* = 0x00008847
  GL_MATRIX_INDEX_ARRAY_STRIDE_ARB* = 0x00008848
  GL_MATRIX_INDEX_ARRAY_POINTER_ARB* = 0x00008849 # GL_ARB_multisample
  GL_MULTISAMPLE_ARB* = 0x0000809D
  GL_SAMPLE_ALPHA_TO_COVERAGE_ARB* = 0x0000809E
  GL_SAMPLE_ALPHA_TO_ONE_ARB* = 0x0000809F
  cGL_SAMPLE_COVERAGE_ARB* = 0x000080A0
  GL_SAMPLE_BUFFERS_ARB* = 0x000080A8
  GL_SAMPLES_ARB* = 0x000080A9
  GL_SAMPLE_COVERAGE_VALUE_ARB* = 0x000080AA
  GL_SAMPLE_COVERAGE_INVERT_ARB* = 0x000080AB
  GL_MULTISAMPLE_BIT_ARB* = 0x20000000 # GL_ARB_multitexture
  GL_TEXTURE0_ARB* = 0x000084C0
  GL_TEXTURE1_ARB* = 0x000084C1
  GL_TEXTURE2_ARB* = 0x000084C2
  GL_TEXTURE3_ARB* = 0x000084C3
  GL_TEXTURE4_ARB* = 0x000084C4
  GL_TEXTURE5_ARB* = 0x000084C5
  GL_TEXTURE6_ARB* = 0x000084C6
  GL_TEXTURE7_ARB* = 0x000084C7
  GL_TEXTURE8_ARB* = 0x000084C8
  GL_TEXTURE9_ARB* = 0x000084C9
  GL_TEXTURE10_ARB* = 0x000084CA
  GL_TEXTURE11_ARB* = 0x000084CB
  GL_TEXTURE12_ARB* = 0x000084CC
  GL_TEXTURE13_ARB* = 0x000084CD
  GL_TEXTURE14_ARB* = 0x000084CE
  GL_TEXTURE15_ARB* = 0x000084CF
  GL_TEXTURE16_ARB* = 0x000084D0
  GL_TEXTURE17_ARB* = 0x000084D1
  GL_TEXTURE18_ARB* = 0x000084D2
  GL_TEXTURE19_ARB* = 0x000084D3
  GL_TEXTURE20_ARB* = 0x000084D4
  GL_TEXTURE21_ARB* = 0x000084D5
  GL_TEXTURE22_ARB* = 0x000084D6
  GL_TEXTURE23_ARB* = 0x000084D7
  GL_TEXTURE24_ARB* = 0x000084D8
  GL_TEXTURE25_ARB* = 0x000084D9
  GL_TEXTURE26_ARB* = 0x000084DA
  GL_TEXTURE27_ARB* = 0x000084DB
  GL_TEXTURE28_ARB* = 0x000084DC
  GL_TEXTURE29_ARB* = 0x000084DD
  GL_TEXTURE30_ARB* = 0x000084DE
  GL_TEXTURE31_ARB* = 0x000084DF
  cGL_ACTIVE_TEXTURE_ARB* = 0x000084E0
  cGL_CLIENT_ACTIVE_TEXTURE_ARB* = 0x000084E1
  GL_MAX_TEXTURE_UNITS_ARB* = 0x000084E2 # GL_ARB_point_parameters
  GL_POINT_SIZE_MIN_ARB* = 0x00008126
  GL_POINT_SIZE_MAX_ARB* = 0x00008127
  GL_POINT_FADE_THRESHOLD_SIZE_ARB* = 0x00008128
  GL_POINT_DISTANCE_ATTENUATION_ARB* = 0x00008129 # GL_ARB_shadow
  GL_TEXTURE_COMPARE_MODE_ARB* = 0x0000884C
  GL_TEXTURE_COMPARE_FUNC_ARB* = 0x0000884D
  GL_COMPARE_R_TO_TEXTURE_ARB* = 0x0000884E # GL_ARB_shadow_ambient
  GL_TEXTURE_COMPARE_FAIL_VALUE_ARB* = 0x000080BF # GL_ARB_texture_border_clamp
  GL_CLAMP_TO_BORDER_ARB* = 0x0000812D # GL_ARB_texture_compression
  GL_COMPRESSED_ALPHA_ARB* = 0x000084E9
  GL_COMPRESSED_LUMINANCE_ARB* = 0x000084EA
  GL_COMPRESSED_LUMINANCE_ALPHA_ARB* = 0x000084EB
  GL_COMPRESSED_INTENSITY_ARB* = 0x000084EC
  GL_COMPRESSED_RGB_ARB* = 0x000084ED
  GL_COMPRESSED_RGBA_ARB* = 0x000084EE
  GL_TEXTURE_COMPRESSION_HINT_ARB* = 0x000084EF
  GL_TEXTURE_COMPRESSED_IMAGE_SIZE_ARB* = 0x000086A0
  GL_TEXTURE_COMPRESSED_ARB* = 0x000086A1
  GL_NUM_COMPRESSED_TEXTURE_FORMATS_ARB* = 0x000086A2
  GL_COMPRESSED_TEXTURE_FORMATS_ARB* = 0x000086A3 # GL_ARB_texture_cube_map
  GL_NORMAL_MAP_ARB* = 0x00008511
  GL_REFLECTION_MAP_ARB* = 0x00008512
  GL_TEXTURE_CUBE_MAP_ARB* = 0x00008513
  GL_TEXTURE_BINDING_CUBE_MAP_ARB* = 0x00008514
  GL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB* = 0x00008515
  GL_TEXTURE_CUBE_MAP_NEGATIVE_X_ARB* = 0x00008516
  GL_TEXTURE_CUBE_MAP_POSITIVE_Y_ARB* = 0x00008517
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_ARB* = 0x00008518
  GL_TEXTURE_CUBE_MAP_POSITIVE_Z_ARB* = 0x00008519
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_ARB* = 0x0000851A
  GL_PROXY_TEXTURE_CUBE_MAP_ARB* = 0x0000851B
  GL_MAX_CUBE_MAP_TEXTURE_SIZE_ARB* = 0x0000851C # GL_ARB_texture_env_combine
  GL_COMBINE_ARB* = 0x00008570
  GL_COMBINE_RGB_ARB* = 0x00008571
  GL_COMBINE_ALPHA_ARB* = 0x00008572
  GL_SOURCE0_RGB_ARB* = 0x00008580
  GL_SOURCE1_RGB_ARB* = 0x00008581
  GL_SOURCE2_RGB_ARB* = 0x00008582
  GL_SOURCE0_ALPHA_ARB* = 0x00008588
  GL_SOURCE1_ALPHA_ARB* = 0x00008589
  GL_SOURCE2_ALPHA_ARB* = 0x0000858A
  GL_OPERAND0_RGB_ARB* = 0x00008590
  GL_OPERAND1_RGB_ARB* = 0x00008591
  GL_OPERAND2_RGB_ARB* = 0x00008592
  GL_OPERAND0_ALPHA_ARB* = 0x00008598
  GL_OPERAND1_ALPHA_ARB* = 0x00008599
  GL_OPERAND2_ALPHA_ARB* = 0x0000859A
  GL_RGB_SCALE_ARB* = 0x00008573
  GL_ADD_SIGNED_ARB* = 0x00008574
  GL_INTERPOLATE_ARB* = 0x00008575
  GL_SUBTRACT_ARB* = 0x000084E7
  GL_CONSTANT_ARB* = 0x00008576
  GL_PRIMARY_COLOR_ARB* = 0x00008577
  GL_PREVIOUS_ARB* = 0x00008578 # GL_ARB_texture_env_dot3
  GL_DOT3_RGB_ARB* = 0x000086AE
  GL_DOT3_RGBA_ARB* = 0x000086AF # GL_ARB_texture_mirrored_repeat
  GL_MIRRORED_REPEAT_ARB* = 0x00008370 # GL_ARB_transpose_matrix
  GL_TRANSPOSE_MODELVIEW_MATRIX_ARB* = 0x000084E3
  GL_TRANSPOSE_PROJECTION_MATRIX_ARB* = 0x000084E4
  GL_TRANSPOSE_TEXTURE_MATRIX_ARB* = 0x000084E5
  GL_TRANSPOSE_COLOR_MATRIX_ARB* = 0x000084E6 # GL_ARB_vertex_blend
  GL_MAX_VERTEX_UNITS_ARB* = 0x000086A4
  GL_ACTIVE_VERTEX_UNITS_ARB* = 0x000086A5
  GL_WEIGHT_SUM_UNITY_ARB* = 0x000086A6
  cGL_VERTEX_BLEND_ARB* = 0x000086A7
  GL_CURRENT_WEIGHT_ARB* = 0x000086A8
  GL_WEIGHT_ARRAYtyp_ARB* = 0x000086A9
  GL_WEIGHT_ARRAY_STRIDE_ARB* = 0x000086AA
  GL_WEIGHT_ARRAY_SIZE_ARB* = 0x000086AB
  GL_WEIGHT_ARRAY_POINTER_ARB* = 0x000086AC
  GL_WEIGHT_ARRAY_ARB* = 0x000086AD
  GL_MODELVIEW0_ARB* = 0x00001700
  GL_MODELVIEW1_ARB* = 0x0000850A
  GL_MODELVIEW2_ARB* = 0x00008722
  GL_MODELVIEW3_ARB* = 0x00008723
  GL_MODELVIEW4_ARB* = 0x00008724
  GL_MODELVIEW5_ARB* = 0x00008725
  GL_MODELVIEW6_ARB* = 0x00008726
  GL_MODELVIEW7_ARB* = 0x00008727
  GL_MODELVIEW8_ARB* = 0x00008728
  GL_MODELVIEW9_ARB* = 0x00008729
  GL_MODELVIEW10_ARB* = 0x0000872A
  GL_MODELVIEW11_ARB* = 0x0000872B
  GL_MODELVIEW12_ARB* = 0x0000872C
  GL_MODELVIEW13_ARB* = 0x0000872D
  GL_MODELVIEW14_ARB* = 0x0000872E
  GL_MODELVIEW15_ARB* = 0x0000872F
  GL_MODELVIEW16_ARB* = 0x00008730
  GL_MODELVIEW17_ARB* = 0x00008731
  GL_MODELVIEW18_ARB* = 0x00008732
  GL_MODELVIEW19_ARB* = 0x00008733
  GL_MODELVIEW20_ARB* = 0x00008734
  GL_MODELVIEW21_ARB* = 0x00008735
  GL_MODELVIEW22_ARB* = 0x00008736
  GL_MODELVIEW23_ARB* = 0x00008737
  GL_MODELVIEW24_ARB* = 0x00008738
  GL_MODELVIEW25_ARB* = 0x00008739
  GL_MODELVIEW26_ARB* = 0x0000873A
  GL_MODELVIEW27_ARB* = 0x0000873B
  GL_MODELVIEW28_ARB* = 0x0000873C
  GL_MODELVIEW29_ARB* = 0x0000873D
  GL_MODELVIEW30_ARB* = 0x0000873E
  GL_MODELVIEW31_ARB* = 0x0000873F # GL_ARB_vertex_buffer_object
  GL_BUFFER_SIZE_ARB* = 0x00008764
  GL_BUFFER_USAGE_ARB* = 0x00008765
  GL_ARRAY_BUFFER_ARB* = 0x00008892
  GL_ELEMENT_ARRAY_BUFFER_ARB* = 0x00008893
  GL_ARRAY_BUFFER_BINDING_ARB* = 0x00008894
  GL_ELEMENT_ARRAY_BUFFER_BINDING_ARB* = 0x00008895
  GL_VERTEX_ARRAY_BUFFER_BINDING_ARB* = 0x00008896
  GL_NORMAL_ARRAY_BUFFER_BINDING_ARB* = 0x00008897
  GL_COLOR_ARRAY_BUFFER_BINDING_ARB* = 0x00008898
  GL_INDEX_ARRAY_BUFFER_BINDING_ARB* = 0x00008899
  GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING_ARB* = 0x0000889A
  GL_EDGE_FLAG_ARRAY_BUFFER_BINDING_ARB* = 0x0000889B
  GL_SECONDARY_COLOR_ARRAY_BUFFER_BINDING_ARB* = 0x0000889C
  GL_FOG_COORDINATE_ARRAY_BUFFER_BINDING_ARB* = 0x0000889D
  GL_WEIGHT_ARRAY_BUFFER_BINDING_ARB* = 0x0000889E
  GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING_ARB* = 0x0000889F
  GL_READ_ONLY_ARB* = 0x000088B8
  GL_WRITE_ONLY_ARB* = 0x000088B9
  GL_READ_WRITE_ARB* = 0x000088BA
  GL_BUFFER_ACCESS_ARB* = 0x000088BB
  GL_BUFFER_MAPPED_ARB* = 0x000088BC
  GL_BUFFER_MAP_POINTER_ARB* = 0x000088BD
  GL_STREAM_DRAW_ARB* = 0x000088E0
  GL_STREAM_READ_ARB* = 0x000088E1
  GL_STREAM_COPY_ARB* = 0x000088E2
  GL_STATIC_DRAW_ARB* = 0x000088E4
  GL_STATIC_READ_ARB* = 0x000088E5
  GL_STATIC_COPY_ARB* = 0x000088E6
  GL_DYNAMIC_DRAW_ARB* = 0x000088E8
  GL_DYNAMIC_READ_ARB* = 0x000088E9
  GL_DYNAMIC_COPY_ARB* = 0x000088EA # GL_ARB_vertex_program
  GL_COLOR_SUM_ARB* = 0x00008458
  GL_VERTEX_PROGRAM_ARB* = 0x00008620
  GL_VERTEX_ATTRIB_ARRAY_ENABLED_ARB* = 0x00008622
  GL_VERTEX_ATTRIB_ARRAY_SIZE_ARB* = 0x00008623
  GL_VERTEX_ATTRIB_ARRAY_STRIDE_ARB* = 0x00008624
  GL_VERTEX_ATTRIB_ARRAYtyp_ARB* = 0x00008625
  GL_CURRENT_VERTEX_ATTRIB_ARB* = 0x00008626
  GL_PROGRAM_LENGTH_ARB* = 0x00008627
  cGL_PROGRAM_STRING_ARB* = 0x00008628
  GL_MAX_PROGRAM_MATRIX_STACK_DEPTH_ARB* = 0x0000862E
  GL_MAX_PROGRAM_MATRICES_ARB* = 0x0000862F
  GL_CURRENT_MATRIX_STACK_DEPTH_ARB* = 0x00008640
  GL_CURRENT_MATRIX_ARB* = 0x00008641
  GL_VERTEX_PROGRAM_POINT_SIZE_ARB* = 0x00008642
  GL_VERTEX_PROGRAM_TWO_SIDE_ARB* = 0x00008643
  GL_VERTEX_ATTRIB_ARRAY_POINTER_ARB* = 0x00008645
  GL_PROGRAM_ERROR_POSITION_ARB* = 0x0000864B
  GL_PROGRAM_BINDING_ARB* = 0x00008677
  GL_MAX_VERTEX_ATTRIBS_ARB* = 0x00008869
  GL_VERTEX_ATTRIB_ARRAY_NORMALIZED_ARB* = 0x0000886A
  GL_PROGRAM_ERROR_STRING_ARB* = 0x00008874
  GL_PROGRAM_FORMAT_ASCII_ARB* = 0x00008875
  GL_PROGRAM_FORMAT_ARB* = 0x00008876
  GL_PROGRAM_INSTRUCTIONS_ARB* = 0x000088A0
  GL_MAX_PROGRAM_INSTRUCTIONS_ARB* = 0x000088A1
  GL_PROGRAM_NATIVE_INSTRUCTIONS_ARB* = 0x000088A2
  GL_MAX_PROGRAM_NATIVE_INSTRUCTIONS_ARB* = 0x000088A3
  GL_PROGRAM_TEMPORARIES_ARB* = 0x000088A4
  GL_MAX_PROGRAM_TEMPORARIES_ARB* = 0x000088A5
  GL_PROGRAM_NATIVE_TEMPORARIES_ARB* = 0x000088A6
  GL_MAX_PROGRAM_NATIVE_TEMPORARIES_ARB* = 0x000088A7
  GL_PROGRAM_PARAMETERS_ARB* = 0x000088A8
  GL_MAX_PROGRAM_PARAMETERS_ARB* = 0x000088A9
  GL_PROGRAM_NATIVE_PARAMETERS_ARB* = 0x000088AA
  GL_MAX_PROGRAM_NATIVE_PARAMETERS_ARB* = 0x000088AB
  GL_PROGRAM_ATTRIBS_ARB* = 0x000088AC
  GL_MAX_PROGRAM_ATTRIBS_ARB* = 0x000088AD
  GL_PROGRAM_NATIVE_ATTRIBS_ARB* = 0x000088AE
  GL_MAX_PROGRAM_NATIVE_ATTRIBS_ARB* = 0x000088AF
  GL_PROGRAM_ADDRESS_REGISTERS_ARB* = 0x000088B0
  GL_MAX_PROGRAM_ADDRESS_REGISTERS_ARB* = 0x000088B1
  GL_PROGRAM_NATIVE_ADDRESS_REGISTERS_ARB* = 0x000088B2
  GL_MAX_PROGRAM_NATIVE_ADDRESS_REGISTERS_ARB* = 0x000088B3
  GL_MAX_PROGRAM_LOCAL_PARAMETERS_ARB* = 0x000088B4
  GL_MAX_PROGRAM_ENV_PARAMETERS_ARB* = 0x000088B5
  GL_PROGRAM_UNDER_NATIVE_LIMITS_ARB* = 0x000088B6
  GL_TRANSPOSE_CURRENT_MATRIX_ARB* = 0x000088B7
  GL_MATRIX0_ARB* = 0x000088C0
  GL_MATRIX1_ARB* = 0x000088C1
  GL_MATRIX2_ARB* = 0x000088C2
  GL_MATRIX3_ARB* = 0x000088C3
  GL_MATRIX4_ARB* = 0x000088C4
  GL_MATRIX5_ARB* = 0x000088C5
  GL_MATRIX6_ARB* = 0x000088C6
  GL_MATRIX7_ARB* = 0x000088C7
  GL_MATRIX8_ARB* = 0x000088C8
  GL_MATRIX9_ARB* = 0x000088C9
  GL_MATRIX10_ARB* = 0x000088CA
  GL_MATRIX11_ARB* = 0x000088CB
  GL_MATRIX12_ARB* = 0x000088CC
  GL_MATRIX13_ARB* = 0x000088CD
  GL_MATRIX14_ARB* = 0x000088CE
  GL_MATRIX15_ARB* = 0x000088CF
  GL_MATRIX16_ARB* = 0x000088D0
  GL_MATRIX17_ARB* = 0x000088D1
  GL_MATRIX18_ARB* = 0x000088D2
  GL_MATRIX19_ARB* = 0x000088D3
  GL_MATRIX20_ARB* = 0x000088D4
  GL_MATRIX21_ARB* = 0x000088D5
  GL_MATRIX22_ARB* = 0x000088D6
  GL_MATRIX23_ARB* = 0x000088D7
  GL_MATRIX24_ARB* = 0x000088D8
  GL_MATRIX25_ARB* = 0x000088D9
  GL_MATRIX26_ARB* = 0x000088DA
  GL_MATRIX27_ARB* = 0x000088DB
  GL_MATRIX28_ARB* = 0x000088DC
  GL_MATRIX29_ARB* = 0x000088DD
  GL_MATRIX30_ARB* = 0x000088DE
  GL_MATRIX31_ARB* = 0x000088DF # GL_ARB_draw_buffers
  GL_MAX_DRAW_BUFFERS_ARB* = 0x00008824
  GL_DRAW_BUFFER0_ARB* = 0x00008825
  GL_DRAW_BUFFER1_ARB* = 0x00008826
  GL_DRAW_BUFFER2_ARB* = 0x00008827
  GL_DRAW_BUFFER3_ARB* = 0x00008828
  GL_DRAW_BUFFER4_ARB* = 0x00008829
  GL_DRAW_BUFFER5_ARB* = 0x0000882A
  GL_DRAW_BUFFER6_ARB* = 0x0000882B
  GL_DRAW_BUFFER7_ARB* = 0x0000882C
  GL_DRAW_BUFFER8_ARB* = 0x0000882D
  GL_DRAW_BUFFER9_ARB* = 0x0000882E
  GL_DRAW_BUFFER10_ARB* = 0x0000882F
  GL_DRAW_BUFFER11_ARB* = 0x00008830
  GL_DRAW_BUFFER12_ARB* = 0x00008831
  GL_DRAW_BUFFER13_ARB* = 0x00008832
  GL_DRAW_BUFFER14_ARB* = 0x00008833
  GL_DRAW_BUFFER15_ARB* = 0x00008834 # GL_ARB_texture_rectangle
  GL_TEXTURE_RECTANGLE_ARB* = 0x000084F5
  GL_TEXTURE_BINDING_RECTANGLE_ARB* = 0x000084F6
  GL_PROXY_TEXTURE_RECTANGLE_ARB* = 0x000084F7
  GL_MAX_RECTANGLE_TEXTURE_SIZE_ARB* = 0x000084F8 # GL_ARB_color_buffer_float
  GL_RGBA_FLOAT_MODE_ARB* = 0x00008820
  GL_CLAMP_VERTEX_COLOR_ARB* = 0x0000891A
  GL_CLAMP_FRAGMENT_COLOR_ARB* = 0x0000891B
  GL_CLAMP_READ_COLOR_ARB* = 0x0000891C
  GL_FIXED_ONLY_ARB* = 0x0000891D
  WGLtyp_RGBA_FLOAT_ARB* = 0x000021A0
  GLX_RGBA_FLOATtyp* = 0x000020B9
  GLX_RGBA_FLOAT_BIT* = 0x00000004 # GL_ARB_half_float_pixel
  GL_HALF_FLOAT_ARB* = 0x0000140B # GL_ARB_texture_float
  GL_TEXTURE_REDtyp_ARB* = 0x00008C10
  GL_TEXTURE_GREENtyp_ARB* = 0x00008C11
  GL_TEXTURE_BLUEtyp_ARB* = 0x00008C12
  GL_TEXTURE_ALPHAtyp_ARB* = 0x00008C13
  GL_TEXTURE_LUMINANCEtyp_ARB* = 0x00008C14
  GL_TEXTURE_INTENSITYtyp_ARB* = 0x00008C15
  GL_TEXTURE_DEPTHtyp_ARB* = 0x00008C16
  GL_UNSIGNED_NORMALIZED_ARB* = 0x00008C17
  GL_RGBA32F_ARB* = 0x00008814
  GL_RGB32F_ARB* = 0x00008815
  GL_ALPHA32F_ARB* = 0x00008816
  GL_INTENSITY32F_ARB* = 0x00008817
  GL_LUMINANCE32F_ARB* = 0x00008818
  GL_LUMINANCE_ALPHA32F_ARB* = 0x00008819
  GL_RGBA16F_ARB* = 0x0000881A
  GL_RGB16F_ARB* = 0x0000881B
  GL_ALPHA16F_ARB* = 0x0000881C
  GL_INTENSITY16F_ARB* = 0x0000881D
  GL_LUMINANCE16F_ARB* = 0x0000881E
  GL_LUMINANCE_ALPHA16F_ARB* = 0x0000881F # GL_ARB_pixel_buffer_object
  GL_PIXEL_PACK_BUFFER_ARB* = 0x000088EB
  GL_PIXEL_UNPACK_BUFFER_ARB* = 0x000088EC
  GL_PIXEL_PACK_BUFFER_BINDING_ARB* = 0x000088ED
  GL_PIXEL_UNPACK_BUFFER_BINDING_ARB* = 0x000088EF # GL_ARB_depth_buffer_float
  GL_DEPTH_COMPONENT32F* = 0x00008CAC
  GL_DEPTH32F_STENCIL8* = 0x00008CAD
  GL_FLOAT_32_UNSIGNED_INT_24_8_REV* = 0x00008DAD # GL_ARB_framebuffer_object
  GL_INVALID_FRAMEBUFFER_OPERATION* = 0x00000506
  GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING* = 0x00008210
  GL_FRAMEBUFFER_ATTACHMENT_COMPONENTtyp* = 0x00008211
  GL_FRAMEBUFFER_ATTACHMENT_RED_SIZE* = 0x00008212
  GL_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE* = 0x00008213
  GL_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE* = 0x00008214
  GL_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE* = 0x00008215
  GL_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE* = 0x00008216
  GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE* = 0x00008217
  GL_FRAMEBUFFER_DEFAULT* = 0x00008218
  GL_FRAMEBUFFER_UNDEFINED* = 0x00008219
  GL_DEPTH_STENCIL_ATTACHMENT* = 0x0000821A
  GL_MAX_RENDERBUFFER_SIZE* = 0x000084E8
  GL_DEPTH_STENCIL* = 0x000084F9
  GL_UNSIGNED_INT_24_8* = 0x000084FA
  GL_DEPTH24_STENCIL8* = 0x000088F0
  GL_TEXTURE_STENCIL_SIZE* = 0x000088F1
  GL_TEXTURE_REDtyp* = 0x00008C10
  GL_TEXTURE_GREENtyp* = 0x00008C11
  GL_TEXTURE_BLUEtyp* = 0x00008C12
  GL_TEXTURE_ALPHAtyp* = 0x00008C13
  GL_TEXTURE_DEPTHtyp* = 0x00008C16
  GL_UNSIGNED_NORMALIZED* = 0x00008C17
  GL_FRAMEBUFFER_BINDING* = 0x00008CA6
  GL_DRAW_FRAMEBUFFER_BINDING* = GL_FRAMEBUFFER_BINDING
  GL_RENDERBUFFER_BINDING* = 0x00008CA7
  GL_READ_FRAMEBUFFER* = 0x00008CA8
  GL_DRAW_FRAMEBUFFER* = 0x00008CA9
  GL_READ_FRAMEBUFFER_BINDING* = 0x00008CAA
  GL_RENDERBUFFER_SAMPLES* = 0x00008CAB
  GL_FRAMEBUFFER_ATTACHMENT_OBJECTtyp* = 0x00008CD0
  GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME* = 0x00008CD1
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL* = 0x00008CD2
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE* = 0x00008CD3
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER* = 0x00008CD4
  GL_FRAMEBUFFER_COMPLETE* = 0x00008CD5
  GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT* = 0x00008CD6
  GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT* = 0x00008CD7
  GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER* = 0x00008CDB
  GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER* = 0x00008CDC
  GL_FRAMEBUFFER_UNSUPPORTED* = 0x00008CDD
  GL_MAX_COLOR_ATTACHMENTS* = 0x00008CDF
  GL_COLOR_ATTACHMENT0* = 0x00008CE0
  GL_COLOR_ATTACHMENT1* = 0x00008CE1
  GL_COLOR_ATTACHMENT2* = 0x00008CE2
  GL_COLOR_ATTACHMENT3* = 0x00008CE3
  GL_COLOR_ATTACHMENT4* = 0x00008CE4
  GL_COLOR_ATTACHMENT5* = 0x00008CE5
  GL_COLOR_ATTACHMENT6* = 0x00008CE6
  GL_COLOR_ATTACHMENT7* = 0x00008CE7
  GL_COLOR_ATTACHMENT8* = 0x00008CE8
  GL_COLOR_ATTACHMENT9* = 0x00008CE9
  GL_COLOR_ATTACHMENT10* = 0x00008CEA
  GL_COLOR_ATTACHMENT11* = 0x00008CEB
  GL_COLOR_ATTACHMENT12* = 0x00008CEC
  GL_COLOR_ATTACHMENT13* = 0x00008CED
  GL_COLOR_ATTACHMENT14* = 0x00008CEE
  GL_COLOR_ATTACHMENT15* = 0x00008CEF
  GL_DEPTH_ATTACHMENT* = 0x00008D00
  GL_STENCIL_ATTACHMENT* = 0x00008D20
  GL_FRAMEBUFFER* = 0x00008D40
  GL_RENDERBUFFER* = 0x00008D41
  GL_RENDERBUFFER_WIDTH* = 0x00008D42
  GL_RENDERBUFFER_HEIGHT* = 0x00008D43
  GL_RENDERBUFFER_INTERNAL_FORMAT* = 0x00008D44
  GL_STENCIL_INDEX1* = 0x00008D46
  GL_STENCIL_INDEX4* = 0x00008D47
  GL_STENCIL_INDEX8* = 0x00008D48
  GL_STENCIL_INDEX16* = 0x00008D49
  GL_RENDERBUFFER_RED_SIZE* = 0x00008D50
  GL_RENDERBUFFER_GREEN_SIZE* = 0x00008D51
  GL_RENDERBUFFER_BLUE_SIZE* = 0x00008D52
  GL_RENDERBUFFER_ALPHA_SIZE* = 0x00008D53
  GL_RENDERBUFFER_DEPTH_SIZE* = 0x00008D54
  GL_RENDERBUFFER_STENCIL_SIZE* = 0x00008D55
  GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE* = 0x00008D56
  GL_MAX_SAMPLES* = 0x00008D57
  GL_INDEX* = 0x00008222
  GL_TEXTURE_LUMINANCEtyp* = 0x00008C14
  GL_TEXTURE_INTENSITYtyp* = 0x00008C15 # GL_ARB_framebuffer_sRGB
  GL_FRAMEBUFFER_SRGB* = 0x00008DB9 # GL_ARB_geometry_shader4
  GL_LINES_ADJACENCY_ARB* = 0x0000000A
  GL_LINE_STRIP_ADJACENCY_ARB* = 0x0000000B
  GL_TRIANGLES_ADJACENCY_ARB* = 0x0000000C
  GL_TRIANGLE_STRIP_ADJACENCY_ARB* = 0x0000000D
  GL_PROGRAM_POINT_SIZE_ARB* = 0x00008642
  GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS_ARB* = 0x00008C29
  GL_FRAMEBUFFER_ATTACHMENT_LAYERED_ARB* = 0x00008DA7
  GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS_ARB* = 0x00008DA8
  GL_FRAMEBUFFER_INCOMPLETE_LAYER_COUNT_ARB* = 0x00008DA9
  GL_GEOMETRY_SHADER_ARB* = 0x00008DD9
  GL_GEOMETRY_VERTICES_OUT_ARB* = 0x00008DDA
  GL_GEOMETRY_INPUTtyp_ARB* = 0x00008DDB
  GL_GEOMETRY_OUTPUTtyp_ARB* = 0x00008DDC
  GL_MAX_GEOMETRY_VARYING_COMPONENTS_ARB* = 0x00008DDD
  GL_MAX_VERTEX_VARYING_COMPONENTS_ARB* = 0x00008DDE
  GL_MAX_GEOMETRY_UNIFORM_COMPONENTS_ARB* = 0x00008DDF
  GL_MAX_GEOMETRY_OUTPUT_VERTICES_ARB* = 0x00008DE0
  GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS_ARB* = 0x00008DE1 # reuse
                                                            # GL_MAX_VARYING_COMPONENTS
                                                            # reuse
                                                            # GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER
                                                            #
                                                            # GL_ARB_half_float_vertex
  GL_HALF_FLOAT* = 0x0000140B # GL_ARB_instanced_arrays
  GL_VERTEX_ATTRIB_ARRAY_DIVISOR_ARB* = 0x000088FE # GL_ARB_map_buffer_range
  GL_MAP_READ_BIT* = 0x00000001
  GL_MAP_WRITE_BIT* = 0x00000002
  GL_MAP_INVALIDATE_RANGE_BIT* = 0x00000004
  GL_MAP_INVALIDATE_BUFFER_BIT* = 0x00000008
  GL_MAP_FLUSH_EXPLICIT_BIT* = 0x00000010
  GL_MAP_UNSYNCHRONIZED_BIT* = 0x00000020 # GL_ARB_texture_buffer_object
  GL_TEXTURE_BUFFER_ARB* = 0x00008C2A
  GL_MAX_TEXTURE_BUFFER_SIZE_ARB* = 0x00008C2B
  GL_TEXTURE_BINDING_BUFFER_ARB* = 0x00008C2C
  GL_TEXTURE_BUFFER_DATA_STORE_BINDING_ARB* = 0x00008C2D
  GL_TEXTURE_BUFFER_FORMAT_ARB* = 0x00008C2E # GL_ARB_texture_compression_rgtc
  GL_COMPRESSED_RED_RGTC1* = 0x00008DBB
  GL_COMPRESSED_SIGNED_RED_RGTC1* = 0x00008DBC
  GL_COMPRESSED_RG_RGTC2* = 0x00008DBD
  GL_COMPRESSED_SIGNED_RG_RGTC2* = 0x00008DBE # GL_ARB_texture_rg
  GL_RG* = 0x00008227
  GL_RG_INTEGER* = 0x00008228
  GL_R8* = 0x00008229
  GL_R16* = 0x0000822A
  GL_RG8* = 0x0000822B
  GL_RG16* = 0x0000822C
  GL_R16F* = 0x0000822D
  GL_R32F* = 0x0000822E
  GL_RG16F* = 0x0000822F
  GL_RG32F* = 0x00008230
  GL_R8I* = 0x00008231
  GL_R8UI* = 0x00008232
  GL_R16I* = 0x00008233
  GL_R16UI* = 0x00008234
  GL_R32I* = 0x00008235
  GL_R32UI* = 0x00008236
  GL_RG8I* = 0x00008237
  GL_RG8UI* = 0x00008238
  GL_RG16I* = 0x00008239
  GL_RG16UI* = 0x0000823A
  GL_RG32I* = 0x0000823B
  GL_RG32UI* = 0x0000823C     # GL_ARB_vertex_array_object
  GL_VERTEX_ARRAY_BINDING* = 0x000085B5 # GL_ARB_uniform_buffer_object
  GL_UNIFORM_BUFFER* = 0x00008A11
  GL_UNIFORM_BUFFER_BINDING* = 0x00008A28
  GL_UNIFORM_BUFFER_START* = 0x00008A29
  GL_UNIFORM_BUFFER_SIZE* = 0x00008A2A
  GL_MAX_VERTEX_UNIFORM_BLOCKS* = 0x00008A2B
  GL_MAX_GEOMETRY_UNIFORM_BLOCKS* = 0x00008A2C
  GL_MAX_FRAGMENT_UNIFORM_BLOCKS* = 0x00008A2D
  GL_MAX_COMBINED_UNIFORM_BLOCKS* = 0x00008A2E
  GL_MAX_UNIFORM_BUFFER_BINDINGS* = 0x00008A2F
  GL_MAX_UNIFORM_BLOCK_SIZE* = 0x00008A30
  GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS* = 0x00008A31
  GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS* = 0x00008A32
  GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS* = 0x00008A33
  GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT* = 0x00008A34
  GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH* = 0x00008A35
  GL_ACTIVE_UNIFORM_BLOCKS* = 0x00008A36
  GL_UNIFORMtyp* = 0x00008A37
  GL_UNIFORM_SIZE* = 0x00008A38
  GL_UNIFORM_NAME_LENGTH* = 0x00008A39
  GL_UNIFORM_BLOCK_INDEX* = 0x00008A3A
  GL_UNIFORM_OFFSET* = 0x00008A3B
  GL_UNIFORM_ARRAY_STRIDE* = 0x00008A3C
  GL_UNIFORM_MATRIX_STRIDE* = 0x00008A3D
  GL_UNIFORM_IS_ROW_MAJOR* = 0x00008A3E
  cGL_UNIFORM_BLOCK_BINDING* = 0x00008A3F
  GL_UNIFORM_BLOCK_DATA_SIZE* = 0x00008A40
  GL_UNIFORM_BLOCK_NAME_LENGTH* = 0x00008A41
  GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS* = 0x00008A42
  GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES* = 0x00008A43
  GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER* = 0x00008A44
  GL_UNIFORM_BLOCK_REFERENCED_BY_GEOMETRY_SHADER* = 0x00008A45
  GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER* = 0x00008A46
  GL_INVALID_INDEX* = 0xFFFFFFFF # GL_ARB_compatibility
                                 # ARB_compatibility just defines tokens from core 3.0
                                 # GL_ARB_copy_buffer
  GL_COPY_READ_BUFFER* = 0x00008F36
  GL_COPY_WRITE_BUFFER* = 0x00008F37 # GL_ARB_depth_clamp
  GL_DEPTH_CLAMP* = 0x0000864F # GL_ARB_provoking_vertex
  GL_QUADS_FOLLOW_PROVOKING_VERTEX_CONVENTION* = 0x00008E4C
  GL_FIRST_VERTEX_CONVENTION* = 0x00008E4D
  GL_LAST_VERTEX_CONVENTION* = 0x00008E4E
  cGL_PROVOKING_VERTEX* = 0x00008E4F # GL_ARB_seamless_cube_map
  GL_TEXTURE_CUBE_MAP_SEAMLESS* = 0x0000884F # GL_ARB_sync
  GL_MAX_SERVER_WAIT_TIMEOUT* = 0x00009111
  GL_OBJECTtyp* = 0x00009112
  GL_SYNC_CONDITION* = 0x00009113
  GL_SYNC_STATUS* = 0x00009114
  GL_SYNC_FLAGS* = 0x00009115
  GL_SYNC_FENCE* = 0x00009116
  GL_SYNC_GPU_COMMANDS_COMPLETE* = 0x00009117
  GL_UNSIGNALED* = 0x00009118
  GL_SIGNALED* = 0x00009119
  GL_ALREADY_SIGNALED* = 0x0000911A
  GL_TIMEOUT_EXPIRED* = 0x0000911B
  GL_CONDITION_SATISFIED* = 0x0000911C
  GL_WAIT_FAILED* = 0x0000911D
  GL_SYNC_FLUSH_COMMANDS_BIT* = 0x00000001
  GL_TIMEOUT_IGNORED* = int64(- 1) # GL_ARB_texture_multisample
  GL_SAMPLE_POSITION* = 0x00008E50
  GL_SAMPLE_MASK* = 0x00008E51
  GL_SAMPLE_MASK_VALUE* = 0x00008E52
  GL_MAX_SAMPLE_MASK_WORDS* = 0x00008E59
  GL_TEXTURE_2D_MULTISAMPLE* = 0x00009100
  GL_PROXY_TEXTURE_2D_MULTISAMPLE* = 0x00009101
  GL_TEXTURE_2D_MULTISAMPLE_ARRAY* = 0x00009102
  GL_PROXY_TEXTURE_2D_MULTISAMPLE_ARRAY* = 0x00009103
  GL_TEXTURE_BINDING_2D_MULTISAMPLE* = 0x00009104
  GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY* = 0x00009105
  GL_TEXTURE_SAMPLES* = 0x00009106
  GL_TEXTURE_FIXED_SAMPLE_LOCATIONS* = 0x00009107
  GL_SAMPLER_2D_MULTISAMPLE* = 0x00009108
  GL_INT_SAMPLER_2D_MULTISAMPLE* = 0x00009109
  GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE* = 0x0000910A
  GL_SAMPLER_2D_MULTISAMPLE_ARRAY* = 0x0000910B
  GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY* = 0x0000910C
  GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY* = 0x0000910D
  GL_MAX_COLOR_TEXTURE_SAMPLES* = 0x0000910E
  GL_MAX_DEPTH_TEXTURE_SAMPLES* = 0x0000910F
  GL_MAX_INTEGER_SAMPLES* = 0x00009110 # GL_ARB_vertex_array_bgra
                                       # reuse GL_BGRA
                                       # GL_ARB_sample_shading
  GL_SAMPLE_SHADING_ARB* = 0x00008C36
  GL_MIN_SAMPLE_SHADING_VALUE_ARB* = 0x00008C37 # GL_ARB_texture_cube_map_array
  GL_TEXTURE_CUBE_MAP_ARRAY_ARB* = 0x00009009
  GL_TEXTURE_BINDING_CUBE_MAP_ARRAY_ARB* = 0x0000900A
  GL_PROXY_TEXTURE_CUBE_MAP_ARRAY_ARB* = 0x0000900B
  GL_SAMPLER_CUBE_MAP_ARRAY_ARB* = 0x0000900C
  GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW_ARB* = 0x0000900D
  GL_INT_SAMPLER_CUBE_MAP_ARRAY_ARB* = 0x0000900E
  GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY_ARB* = 0x0000900F # GL_ARB_texture_gather
  GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET_ARB* = 0x00008E5E
  GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET_ARB* = 0x00008E5F #
                                                         # GL_ARB_shading_language_include
  GL_SHADER_INCLUDE_ARB* = 0x00008DAE
  GL_NAMED_STRING_LENGTH_ARB* = 0x00008DE9
  GL_NAMED_STRINGtyp_ARB* = 0x00008DEA # GL_ARB_texture_compression_bptc
  GL_COMPRESSED_RGBA_BPTC_UNORM_ARB* = 0x00008E8C
  GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM_ARB* = 0x00008E8D
  GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT_ARB* = 0x00008E8E
  GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_ARB* = 0x00008E8F #
                                                          # GL_ARB_blend_func_extended
  GL_SRC1_COLOR* = 0x000088F9 # reuse GL_SRC1_ALPHA
  GL_ONE_MINUS_SRC1_COLOR* = 0x000088FA
  GL_ONE_MINUS_SRC1_ALPHA* = 0x000088FB
  GL_MAX_DUAL_SOURCE_DRAW_BUFFERS* = 0x000088FC # GL_ARB_occlusion_query2
  GL_ANY_SAMPLES_PASSED* = 0x00008C2F # GL_ARB_sampler_objects
  GL_SAMPLER_BINDING* = 0x00008919 # GL_ARB_texture_rgb10_a2ui
  GL_RGB10_A2UI* = 0x0000906F # GL_ARB_texture_swizzle
  GL_TEXTURE_SWIZZLE_R* = 0x00008E42
  GL_TEXTURE_SWIZZLE_G* = 0x00008E43
  GL_TEXTURE_SWIZZLE_B* = 0x00008E44
  GL_TEXTURE_SWIZZLE_A* = 0x00008E45
  GL_TEXTURE_SWIZZLE_RGBA* = 0x00008E46 # GL_ARB_timer_query
  GL_TIME_ELAPSED* = 0x000088BF
  GL_TIMESTAMP* = 0x00008E28  # GL_ARB_vertextyp_2_10_10_10_rev
                              # reuse GL_UNSIGNED_INT_2_10_10_10_REV
  GL_INT_2_10_10_10_REV* = 0x00008D9F # GL_ARB_draw_indirect
  GL_DRAW_INDIRECT_BUFFER* = 0x00008F3F
  GL_DRAW_INDIRECT_BUFFER_BINDING* = 0x00008F43 # GL_ARB_gpu_shader5
  GL_GEOMETRY_SHADER_INVOCATIONS* = 0x0000887F
  GL_MAX_GEOMETRY_SHADER_INVOCATIONS* = 0x00008E5A
  GL_MIN_FRAGMENT_INTERPOLATION_OFFSET* = 0x00008E5B
  GL_MAX_FRAGMENT_INTERPOLATION_OFFSET* = 0x00008E5C
  GL_FRAGMENT_INTERPOLATION_OFFSET_BITS* = 0x00008E5D # reuse GL_MAX_VERTEX_STREAMS
                                                      # GL_ARB_gpu_shader_fp64
                                                      # reuse GL_DOUBLE
  GL_DOUBLE_VEC2* = 0x00008FFC
  GL_DOUBLE_VEC3* = 0x00008FFD
  GL_DOUBLE_VEC4* = 0x00008FFE
  GL_DOUBLE_MAT2* = 0x00008F46
  GL_DOUBLE_MAT3* = 0x00008F47
  GL_DOUBLE_MAT4* = 0x00008F48
  GL_DOUBLE_MAT2x3* = 0x00008F49
  GL_DOUBLE_MAT2x4* = 0x00008F4A
  GL_DOUBLE_MAT3x2* = 0x00008F4B
  GL_DOUBLE_MAT3x4* = 0x00008F4C
  GL_DOUBLE_MAT4x2* = 0x00008F4D
  GL_DOUBLE_MAT4x3* = 0x00008F4E # GL_ARB_shader_subroutine
  GL_ACTIVE_SUBROUTINES* = 0x00008DE5
  GL_ACTIVE_SUBROUTINE_UNIFORMS* = 0x00008DE6
  GL_ACTIVE_SUBROUTINE_UNIFORM_LOCATIONS* = 0x00008E47
  GL_ACTIVE_SUBROUTINE_MAX_LENGTH* = 0x00008E48
  GL_ACTIVE_SUBROUTINE_UNIFORM_MAX_LENGTH* = 0x00008E49
  GL_MAX_SUBROUTINES* = 0x00008DE7
  GL_MAX_SUBROUTINE_UNIFORM_LOCATIONS* = 0x00008DE8
  GL_NUM_COMPATIBLE_SUBROUTINES* = 0x00008E4A
  GL_COMPATIBLE_SUBROUTINES* = 0x00008E4B # GL_ARB_tessellation_shader
  GL_PATCHES* = 0x0000000E
  GL_PATCH_VERTICES* = 0x00008E72
  GL_PATCH_DEFAULT_INNER_LEVEL* = 0x00008E73
  GL_PATCH_DEFAULT_OUTER_LEVEL* = 0x00008E74
  GL_TESS_CONTROL_OUTPUT_VERTICES* = 0x00008E75
  GL_TESS_GEN_MODE* = 0x00008E76
  GL_TESS_GEN_SPACING* = 0x00008E77
  GL_TESS_GEN_VERTEX_ORDER* = 0x00008E78
  GL_TESS_GEN_POINT_MODE* = 0x00008E79
  GL_ISOLINES* = 0x00008E7A   # reuse GL_EQUAL
  GL_FRACTIONAL_ODD* = 0x00008E7B
  GL_FRACTIONAL_EVEN* = 0x00008E7C
  GL_MAX_PATCH_VERTICES* = 0x00008E7D
  GL_MAX_TESS_GEN_LEVEL* = 0x00008E7E
  GL_MAX_TESS_CONTROL_UNIFORM_COMPONENTS* = 0x00008E7F
  GL_MAX_TESS_EVALUATION_UNIFORM_COMPONENTS* = 0x00008E80
  GL_MAX_TESS_CONTROL_TEXTURE_IMAGE_UNITS* = 0x00008E81
  GL_MAX_TESS_EVALUATION_TEXTURE_IMAGE_UNITS* = 0x00008E82
  GL_MAX_TESS_CONTROL_OUTPUT_COMPONENTS* = 0x00008E83
  GL_MAX_TESS_PATCH_COMPONENTS* = 0x00008E84
  GL_MAX_TESS_CONTROL_TOTAL_OUTPUT_COMPONENTS* = 0x00008E85
  GL_MAX_TESS_EVALUATION_OUTPUT_COMPONENTS* = 0x00008E86
  GL_MAX_TESS_CONTROL_UNIFORM_BLOCKS* = 0x00008E89
  GL_MAX_TESS_EVALUATION_UNIFORM_BLOCKS* = 0x00008E8A
  GL_MAX_TESS_CONTROL_INPUT_COMPONENTS* = 0x0000886C
  GL_MAX_TESS_EVALUATION_INPUT_COMPONENTS* = 0x0000886D
  GL_MAX_COMBINED_TESS_CONTROL_UNIFORM_COMPONENTS* = 0x00008E1E
  GL_MAX_COMBINED_TESS_EVALUATION_UNIFORM_COMPONENTS* = 0x00008E1F
  GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_CONTROL_SHADER* = 0x000084F0
  GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_EVALUATION_SHADER* = 0x000084F1
  GL_TESS_EVALUATION_SHADER* = 0x00008E87
  GL_TESS_CONTROL_SHADER* = 0x00008E88 # GL_ARB_texture_buffer_object_rgb32
                                       # GL_ARB_transform_feedback2
  GL_TRANSFORM_FEEDBACK* = 0x00008E22
  GL_TRANSFORM_FEEDBACK_BUFFER_PAUSED* = 0x00008E23
  GL_TRANSFORM_FEEDBACK_BUFFER_ACTIVE* = 0x00008E24
  GL_TRANSFORM_FEEDBACK_BINDING* = 0x00008E25 # GL_ARB_transform_feedback3
  GL_MAX_TRANSFORM_FEEDBACK_BUFFERS* = 0x00008E70
  GL_MAX_VERTEX_STREAMS* = 0x00008E71 # GL_ARB_ES2_compatibility
  GL_FIXED* = 0x0000140C
  GL_IMPLEMENTATION_COLOR_READtyp* = 0x00008B9A
  GL_IMPLEMENTATION_COLOR_READ_FORMAT* = 0x00008B9B
  GL_LOW_FLOAT* = 0x00008DF0
  GL_MEDIUM_FLOAT* = 0x00008DF1
  GL_HIGH_FLOAT* = 0x00008DF2
  GL_LOW_INT* = 0x00008DF3
  GL_MEDIUM_INT* = 0x00008DF4
  GL_HIGH_INT* = 0x00008DF5
  GL_SHADER_COMPILER* = 0x00008DFA
  GL_NUM_SHADER_BINARY_FORMATS* = 0x00008DF9
  GL_MAX_VERTEX_UNIFORM_VECTORS* = 0x00008DFB
  GL_MAX_VARYING_VECTORS* = 0x00008DFC
  GL_MAX_FRAGMENT_UNIFORM_VECTORS* = 0x00008DFD # GL_ARB_get_program_binary
  GL_PROGRAM_BINARY_RETRIEVABLE_HINT* = 0x00008257
  GL_PROGRAM_BINARY_LENGTH* = 0x00008741
  GL_NUM_PROGRAM_BINARY_FORMATS* = 0x000087FE
  GL_PROGRAM_BINARY_FORMATS* = 0x000087FF # GL_ARB_separate_shader_objects
  GL_VERTEX_SHADER_BIT* = 0x00000001
  GL_FRAGMENT_SHADER_BIT* = 0x00000002
  GL_GEOMETRY_SHADER_BIT* = 0x00000004
  GL_TESS_CONTROL_SHADER_BIT* = 0x00000008
  GL_TESS_EVALUATION_SHADER_BIT* = 0x00000010
  GL_ALL_SHADER_BITS* = 0xFFFFFFFF
  GL_PROGRAM_SEPARABLE* = 0x00008258
  GL_ACTIVE_PROGRAM* = 0x00008259
  GL_PROGRAM_PIPELINE_BINDING* = 0x0000825A # GL_ARB_vertex_attrib_64bit
  GL_MAX_VIEWPORTS* = 0x0000825B
  GL_VIEWPORT_SUBPIXEL_BITS* = 0x0000825C
  GL_VIEWPORT_BOUNDS_RANGE* = 0x0000825D
  GL_LAYER_PROVOKING_VERTEX* = 0x0000825E
  GL_VIEWPORT_INDEX_PROVOKING_VERTEX* = 0x0000825F
  GL_UNDEFINED_VERTEX* = 0x00008260 # GL_ARB_cl_event
  GL_SYNC_CL_EVENT_ARB* = 0x00008240
  GL_SYNC_CL_EVENT_COMPLETE_ARB* = 0x00008241 # GL_ARB_debug_output
  GL_DEBUG_OUTPUT_SYNCHRONOUS_ARB* = 0x00008242
  GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH_ARB* = 0x00008243
  GL_DEBUG_CALLBACK_FUNCTION_ARB* = 0x00008244
  GL_DEBUG_CALLBACK_USER_PARAM_ARB* = 0x00008245
  GL_DEBUG_SOURCE_API_ARB* = 0x00008246
  GL_DEBUG_SOURCE_WINDOW_SYSTEM_ARB* = 0x00008247
  GL_DEBUG_SOURCE_SHADER_COMPILER_ARB* = 0x00008248
  GL_DEBUG_SOURCE_THIRD_PARTY_ARB* = 0x00008249
  GL_DEBUG_SOURCE_APPLICATION_ARB* = 0x0000824A
  GL_DEBUG_SOURCE_OTHER_ARB* = 0x0000824B
  GL_DEBUGtyp_ERROR_ARB* = 0x0000824C
  GL_DEBUGtyp_DEPRECATED_BEHAVIOR_ARB* = 0x0000824D
  GL_DEBUGtyp_UNDEFINED_BEHAVIOR_ARB* = 0x0000824E
  GL_DEBUGtyp_PORTABILITY_ARB* = 0x0000824F
  GL_DEBUGtyp_PERFORMANCE_ARB* = 0x00008250
  GL_DEBUGtyp_OTHER_ARB* = 0x00008251
  GL_MAX_DEBUG_MESSAGE_LENGTH_ARB* = 0x00009143
  GL_MAX_DEBUG_LOGGED_MESSAGES_ARB* = 0x00009144
  GL_DEBUG_LOGGED_MESSAGES_ARB* = 0x00009145
  GL_DEBUG_SEVERITY_HIGH_ARB* = 0x00009146
  GL_DEBUG_SEVERITY_MEDIUM_ARB* = 0x00009147
  GL_DEBUG_SEVERITY_LOW_ARB* = 0x00009148 # GL_ARB_robustness
                                          # reuse GL_NO_ERROR
  GL_CONTEXT_FLAG_ROBUST_ACCESS_BIT_ARB* = 0x00000004
  GL_LOSE_CONTEXT_ON_RESET_ARB* = 0x00008252
  GL_GUILTY_CONTEXT_RESET_ARB* = 0x00008253
  GL_INNOCENT_CONTEXT_RESET_ARB* = 0x00008254
  GL_UNKNOWN_CONTEXT_RESET_ARB* = 0x00008255
  GL_RESET_NOTIFICATION_STRATEGY_ARB* = 0x00008256
  GL_NO_RESET_NOTIFICATION_ARB* = 0x00008261 #
                                             #  GL_ARB_compressed_texture_pixel_storage
  GL_UNPACK_COMPRESSED_BLOCK_WIDTH* = 0x00009127
  GL_UNPACK_COMPRESSED_BLOCK_HEIGHT* = 0x00009128
  GL_UNPACK_COMPRESSED_BLOCK_DEPTH* = 0x00009129
  GL_UNPACK_COMPRESSED_BLOCK_SIZE* = 0x0000912A
  GL_PACK_COMPRESSED_BLOCK_WIDTH* = 0x0000912B
  GL_PACK_COMPRESSED_BLOCK_HEIGHT* = 0x0000912C
  GL_PACK_COMPRESSED_BLOCK_DEPTH* = 0x0000912D
  GL_PACK_COMPRESSED_BLOCK_SIZE* = 0x0000912E # GL_ARB_internalformat_query
  GL_NUM_SAMPLE_COUNTS* = 0x00009380 # GL_ARB_map_buffer_alignment
  GL_MIN_MAP_BUFFER_ALIGNMENT* = 0x000090BC # GL_ARB_shader_atomic_counters
  GL_ATOMIC_COUNTER_BUFFER* = 0x000092C0
  GL_ATOMIC_COUNTER_BUFFER_BINDING* = 0x000092C1
  GL_ATOMIC_COUNTER_BUFFER_START* = 0x000092C2
  GL_ATOMIC_COUNTER_BUFFER_SIZE* = 0x000092C3
  GL_ATOMIC_COUNTER_BUFFER_DATA_SIZE* = 0x000092C4
  GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTERS* = 0x000092C5
  GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTER_INDICES* = 0x000092C6
  GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_VERTEX_SHADER* = 0x000092C7
  GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_CONTROL_SHADER* = 0x000092C8
  GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_EVALUATION_SHADER* = 0x000092C9
  GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_GEOMETRY_SHADER* = 0x000092CA
  GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_FRAGMENT_SHADER* = 0x000092CB
  GL_MAX_VERTEX_ATOMIC_COUNTER_BUFFERS* = 0x000092CC
  GL_MAX_TESS_CONTROL_ATOMIC_COUNTER_BUFFERS* = 0x000092CD
  GL_MAX_TESS_EVALUATION_ATOMIC_COUNTER_BUFFERS* = 0x000092CE
  GL_MAX_GEOMETRY_ATOMIC_COUNTER_BUFFERS* = 0x000092CF
  GL_MAX_FRAGMENT_ATOMIC_COUNTER_BUFFERS* = 0x000092D0
  GL_MAX_COMBINED_ATOMIC_COUNTER_BUFFERS* = 0x000092D1
  GL_MAX_VERTEX_ATOMIC_COUNTERS* = 0x000092D2
  GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS* = 0x000092D3
  GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS* = 0x000092D4
  GL_MAX_GEOMETRY_ATOMIC_COUNTERS* = 0x000092D5
  GL_MAX_FRAGMENT_ATOMIC_COUNTERS* = 0x000092D6
  GL_MAX_COMBINED_ATOMIC_COUNTERS* = 0x000092D7
  GL_MAX_ATOMIC_COUNTER_BUFFER_SIZE* = 0x000092D8
  GL_MAX_ATOMIC_COUNTER_BUFFER_BINDINGS* = 0x000092DC
  GL_ACTIVE_ATOMIC_COUNTER_BUFFERS* = 0x000092D9
  GL_UNIFORM_ATOMIC_COUNTER_BUFFER_INDEX* = 0x000092DA
  GL_UNSIGNED_INT_ATOMIC_COUNTER* = 0x000092DB # GL_ARB_shader_image_load_store
  GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT* = 0x00000001
  GL_ELEMENT_ARRAY_BARRIER_BIT* = 0x00000002
  GL_UNIFORM_BARRIER_BIT* = 0x00000004
  GL_TEXTURE_FETCH_BARRIER_BIT* = 0x00000008
  GL_SHADER_IMAGE_ACCESS_BARRIER_BIT* = 0x00000020
  GL_COMMAND_BARRIER_BIT* = 0x00000040
  GL_PIXEL_BUFFER_BARRIER_BIT* = 0x00000080
  GL_TEXTURE_UPDATE_BARRIER_BIT* = 0x00000100
  GL_BUFFER_UPDATE_BARRIER_BIT* = 0x00000200
  GL_FRAMEBUFFER_BARRIER_BIT* = 0x00000400
  GL_TRANSFORM_FEEDBACK_BARRIER_BIT* = 0x00000800
  GL_ATOMIC_COUNTER_BARRIER_BIT* = 0x00001000
  GL_ALL_BARRIER_BITS* = 0xFFFFFFFF
  GL_MAX_IMAGE_UNITS* = 0x00008F38
  GL_MAX_COMBINED_IMAGE_UNITS_AND_FRAGMENT_OUTPUTS* = 0x00008F39
  GL_IMAGE_BINDING_NAME* = 0x00008F3A
  GL_IMAGE_BINDING_LEVEL* = 0x00008F3B
  GL_IMAGE_BINDING_LAYERED* = 0x00008F3C
  GL_IMAGE_BINDING_LAYER* = 0x00008F3D
  GL_IMAGE_BINDING_ACCESS* = 0x00008F3E
  GL_IMAGE_1D* = 0x0000904C
  GL_IMAGE_2D* = 0x0000904D
  GL_IMAGE_3D* = 0x0000904E
  GL_IMAGE_2D_RECT* = 0x0000904F
  GL_IMAGE_CUBE* = 0x00009050
  GL_IMAGE_BUFFER* = 0x00009051
  GL_IMAGE_1D_ARRAY* = 0x00009052
  GL_IMAGE_2D_ARRAY* = 0x00009053
  GL_IMAGE_CUBE_MAP_ARRAY* = 0x00009054
  GL_IMAGE_2D_MULTISAMPLE* = 0x00009055
  GL_IMAGE_2D_MULTISAMPLE_ARRAY* = 0x00009056
  GL_INT_IMAGE_1D* = 0x00009057
  GL_INT_IMAGE_2D* = 0x00009058
  GL_INT_IMAGE_3D* = 0x00009059
  GL_INT_IMAGE_2D_RECT* = 0x0000905A
  GL_INT_IMAGE_CUBE* = 0x0000905B
  GL_INT_IMAGE_BUFFER* = 0x0000905C
  GL_INT_IMAGE_1D_ARRAY* = 0x0000905D
  GL_INT_IMAGE_2D_ARRAY* = 0x0000905E
  GL_INT_IMAGE_CUBE_MAP_ARRAY* = 0x0000905F
  GL_INT_IMAGE_2D_MULTISAMPLE* = 0x00009060
  GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY* = 0x00009061
  GL_UNSIGNED_INT_IMAGE_1D* = 0x00009062
  GL_UNSIGNED_INT_IMAGE_2D* = 0x00009063
  GL_UNSIGNED_INT_IMAGE_3D* = 0x00009064
  GL_UNSIGNED_INT_IMAGE_2D_RECT* = 0x00009065
  GL_UNSIGNED_INT_IMAGE_CUBE* = 0x00009066
  GL_UNSIGNED_INT_IMAGE_BUFFER* = 0x00009067
  GL_UNSIGNED_INT_IMAGE_1D_ARRAY* = 0x00009068
  GL_UNSIGNED_INT_IMAGE_2D_ARRAY* = 0x00009069
  GL_UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY* = 0x0000906A
  GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE* = 0x0000906B
  GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY* = 0x0000906C
  GL_MAX_IMAGE_SAMPLES* = 0x0000906D
  GL_IMAGE_BINDING_FORMAT* = 0x0000906E
  GL_IMAGE_FORMAT_COMPATIBILITYtyp* = 0x000090C7
  GL_IMAGE_FORMAT_COMPATIBILITY_BY_SIZE* = 0x000090C8
  GL_IMAGE_FORMAT_COMPATIBILITY_BY_CLASS* = 0x000090C9
  GL_MAX_VERTEX_IMAGE_UNIFORMS* = 0x000090CA
  GL_MAX_TESS_CONTROL_IMAGE_UNIFORMS* = 0x000090CB
  GL_MAX_TESS_EVALUATION_IMAGE_UNIFORMS* = 0x000090CC
  GL_MAX_GEOMETRY_IMAGE_UNIFORMS* = 0x000090CD
  GL_MAX_FRAGMENT_IMAGE_UNIFORMS* = 0x000090CE
  GL_MAX_COMBINED_IMAGE_UNIFORMS* = 0x000090CF # GL_ARB_texture_storage
  GL_TEXTURE_IMMUTABLE_FORMAT* = 0x0000912F # GL_ATI_draw_buffers
  GL_MAX_DRAW_BUFFERS_ATI* = 0x00008824
  GL_DRAW_BUFFER0_ATI* = 0x00008825
  GL_DRAW_BUFFER1_ATI* = 0x00008826
  GL_DRAW_BUFFER2_ATI* = 0x00008827
  GL_DRAW_BUFFER3_ATI* = 0x00008828
  GL_DRAW_BUFFER4_ATI* = 0x00008829
  GL_DRAW_BUFFER5_ATI* = 0x0000882A
  GL_DRAW_BUFFER6_ATI* = 0x0000882B
  GL_DRAW_BUFFER7_ATI* = 0x0000882C
  GL_DRAW_BUFFER8_ATI* = 0x0000882D
  GL_DRAW_BUFFER9_ATI* = 0x0000882E
  GL_DRAW_BUFFER10_ATI* = 0x0000882F
  GL_DRAW_BUFFER11_ATI* = 0x00008830
  GL_DRAW_BUFFER12_ATI* = 0x00008831
  GL_DRAW_BUFFER13_ATI* = 0x00008832
  GL_DRAW_BUFFER14_ATI* = 0x00008833
  GL_DRAW_BUFFER15_ATI* = 0x00008834 # GL_ATI_element_array
  GL_ELEMENT_ARRAY_ATI* = 0x00008768
  GL_ELEMENT_ARRAYtyp_ATI* = 0x00008769
  GL_ELEMENT_ARRAY_POINTER_ATI* = 0x0000876A # GL_ATI_envmap_bumpmap
  GL_BUMP_ROT_MATRIX_ATI* = 0x00008775
  GL_BUMP_ROT_MATRIX_SIZE_ATI* = 0x00008776
  GL_BUMP_NUM_TEX_UNITS_ATI* = 0x00008777
  GL_BUMP_TEX_UNITS_ATI* = 0x00008778
  GL_DUDV_ATI* = 0x00008779
  GL_DU8DV8_ATI* = 0x0000877A
  GL_BUMP_ENVMAP_ATI* = 0x0000877B
  GL_BUMP_TARGET_ATI* = 0x0000877C # GL_ATI_fragment_shader
  GL_FRAGMENT_SHADER_ATI* = 0x00008920
  GL_REG_0_ATI* = 0x00008921
  GL_REG_1_ATI* = 0x00008922
  GL_REG_2_ATI* = 0x00008923
  GL_REG_3_ATI* = 0x00008924
  GL_REG_4_ATI* = 0x00008925
  GL_REG_5_ATI* = 0x00008926
  GL_REG_6_ATI* = 0x00008927
  GL_REG_7_ATI* = 0x00008928
  GL_REG_8_ATI* = 0x00008929
  GL_REG_9_ATI* = 0x0000892A
  GL_REG_10_ATI* = 0x0000892B
  GL_REG_11_ATI* = 0x0000892C
  GL_REG_12_ATI* = 0x0000892D
  GL_REG_13_ATI* = 0x0000892E
  GL_REG_14_ATI* = 0x0000892F
  GL_REG_15_ATI* = 0x00008930
  GL_REG_16_ATI* = 0x00008931
  GL_REG_17_ATI* = 0x00008932
  GL_REG_18_ATI* = 0x00008933
  GL_REG_19_ATI* = 0x00008934
  GL_REG_20_ATI* = 0x00008935
  GL_REG_21_ATI* = 0x00008936
  GL_REG_22_ATI* = 0x00008937
  GL_REG_23_ATI* = 0x00008938
  GL_REG_24_ATI* = 0x00008939
  GL_REG_25_ATI* = 0x0000893A
  GL_REG_26_ATI* = 0x0000893B
  GL_REG_27_ATI* = 0x0000893C
  GL_REG_28_ATI* = 0x0000893D
  GL_REG_29_ATI* = 0x0000893E
  GL_REG_30_ATI* = 0x0000893F
  GL_REG_31_ATI* = 0x00008940
  GL_CON_0_ATI* = 0x00008941
  GL_CON_1_ATI* = 0x00008942
  GL_CON_2_ATI* = 0x00008943
  GL_CON_3_ATI* = 0x00008944
  GL_CON_4_ATI* = 0x00008945
  GL_CON_5_ATI* = 0x00008946
  GL_CON_6_ATI* = 0x00008947
  GL_CON_7_ATI* = 0x00008948
  GL_CON_8_ATI* = 0x00008949
  GL_CON_9_ATI* = 0x0000894A
  GL_CON_10_ATI* = 0x0000894B
  GL_CON_11_ATI* = 0x0000894C
  GL_CON_12_ATI* = 0x0000894D
  GL_CON_13_ATI* = 0x0000894E
  GL_CON_14_ATI* = 0x0000894F
  GL_CON_15_ATI* = 0x00008950
  GL_CON_16_ATI* = 0x00008951
  GL_CON_17_ATI* = 0x00008952
  GL_CON_18_ATI* = 0x00008953
  GL_CON_19_ATI* = 0x00008954
  GL_CON_20_ATI* = 0x00008955
  GL_CON_21_ATI* = 0x00008956
  GL_CON_22_ATI* = 0x00008957
  GL_CON_23_ATI* = 0x00008958
  GL_CON_24_ATI* = 0x00008959
  GL_CON_25_ATI* = 0x0000895A
  GL_CON_26_ATI* = 0x0000895B
  GL_CON_27_ATI* = 0x0000895C
  GL_CON_28_ATI* = 0x0000895D
  GL_CON_29_ATI* = 0x0000895E
  GL_CON_30_ATI* = 0x0000895F
  GL_CON_31_ATI* = 0x00008960
  GL_MOV_ATI* = 0x00008961
  GL_ADD_ATI* = 0x00008963
  GL_MUL_ATI* = 0x00008964
  GL_SUB_ATI* = 0x00008965
  GL_DOT3_ATI* = 0x00008966
  GL_DOT4_ATI* = 0x00008967
  GL_MAD_ATI* = 0x00008968
  GL_LERP_ATI* = 0x00008969
  GL_CND_ATI* = 0x0000896A
  GL_CND0_ATI* = 0x0000896B
  GL_DOT2_ADD_ATI* = 0x0000896C
  GL_SECONDARY_INTERPOLATOR_ATI* = 0x0000896D
  GL_NUM_FRAGMENT_REGISTERS_ATI* = 0x0000896E
  GL_NUM_FRAGMENT_CONSTANTS_ATI* = 0x0000896F
  GL_NUM_PASSES_ATI* = 0x00008970
  GL_NUM_INSTRUCTIONS_PER_PASS_ATI* = 0x00008971
  GL_NUM_INSTRUCTIONS_TOTAL_ATI* = 0x00008972
  GL_NUM_INPUT_INTERPOLATOR_COMPONENTS_ATI* = 0x00008973
  GL_NUM_LOOPBACK_COMPONENTS_ATI* = 0x00008974
  GL_COLOR_ALPHA_PAIRING_ATI* = 0x00008975
  GL_SWIZZLE_STR_ATI* = 0x00008976
  GL_SWIZZLE_STQ_ATI* = 0x00008977
  GL_SWIZZLE_STR_DR_ATI* = 0x00008978
  GL_SWIZZLE_STQ_DQ_ATI* = 0x00008979
  GL_SWIZZLE_STRQ_ATI* = 0x0000897A
  GL_SWIZZLE_STRQ_DQ_ATI* = 0x0000897B
  GL_RED_BIT_ATI* = 0x00000001
  GL_GREEN_BIT_ATI* = 0x00000002
  GL_BLUE_BIT_ATI* = 0x00000004
  GL_2X_BIT_ATI* = 0x00000001
  GL_4X_BIT_ATI* = 0x00000002
  GL_8X_BIT_ATI* = 0x00000004
  GL_HALF_BIT_ATI* = 0x00000008
  GL_QUARTER_BIT_ATI* = 0x00000010
  GL_EIGHTH_BIT_ATI* = 0x00000020
  GL_SATURATE_BIT_ATI* = 0x00000040
  GL_COMP_BIT_ATI* = 0x00000002
  GL_NEGATE_BIT_ATI* = 0x00000004
  GL_BIAS_BIT_ATI* = 0x00000008 # GL_ATI_pn_triangles
  GL_PN_TRIANGLES_ATI* = 0x000087F0
  GL_MAX_PN_TRIANGLES_TESSELATION_LEVEL_ATI* = 0x000087F1
  GL_PN_TRIANGLES_POINT_MODE_ATI* = 0x000087F2
  GL_PN_TRIANGLES_NORMAL_MODE_ATI* = 0x000087F3
  GL_PN_TRIANGLES_TESSELATION_LEVEL_ATI* = 0x000087F4
  GL_PN_TRIANGLES_POINT_MODE_LINEAR_ATI* = 0x000087F5
  GL_PN_TRIANGLES_POINT_MODE_CUBIC_ATI* = 0x000087F6
  GL_PN_TRIANGLES_NORMAL_MODE_LINEAR_ATI* = 0x000087F7
  GL_PN_TRIANGLES_NORMAL_MODE_QUADRATIC_ATI* = 0x000087F8 #
                                                          # GL_ATI_separate_stencil
  GL_STENCIL_BACK_FUNC_ATI* = 0x00008800
  GL_STENCIL_BACK_FAIL_ATI* = 0x00008801
  GL_STENCIL_BACK_PASS_DEPTH_FAIL_ATI* = 0x00008802
  GL_STENCIL_BACK_PASS_DEPTH_PASS_ATI* = 0x00008803 # GL_ATI_text_fragment_shader
  GL_TEXT_FRAGMENT_SHADER_ATI* = 0x00008200 # GL_ATI_texture_env_combine3
  GL_MODULATE_ADD_ATI* = 0x00008744
  GL_MODULATE_SIGNED_ADD_ATI* = 0x00008745
  GL_MODULATE_SUBTRACT_ATI* = 0x00008746 # GL_ATI_texture_float
  GL_RGBA_FLOAT32_ATI* = 0x00008814
  GL_RGB_FLOAT32_ATI* = 0x00008815
  GL_ALPHA_FLOAT32_ATI* = 0x00008816
  GL_INTENSITY_FLOAT32_ATI* = 0x00008817
  GL_LUMINANCE_FLOAT32_ATI* = 0x00008818
  GL_LUMINANCE_ALPHA_FLOAT32_ATI* = 0x00008819
  GL_RGBA_FLOAT16_ATI* = 0x0000881A
  GL_RGB_FLOAT16_ATI* = 0x0000881B
  GL_ALPHA_FLOAT16_ATI* = 0x0000881C
  GL_INTENSITY_FLOAT16_ATI* = 0x0000881D
  GL_LUMINANCE_FLOAT16_ATI* = 0x0000881E
  GL_LUMINANCE_ALPHA_FLOAT16_ATI* = 0x0000881F # GL_ATI_texture_mirror_once
  GL_MIRROR_CLAMP_ATI* = 0x00008742
  GL_MIRROR_CLAMP_TO_EDGE_ATI* = 0x00008743 # GL_ATI_vertex_array_object
  GL_STATIC_ATI* = 0x00008760
  GL_DYNAMIC_ATI* = 0x00008761
  GL_PRESERVE_ATI* = 0x00008762
  GL_DISCARD_ATI* = 0x00008763
  GL_OBJECT_BUFFER_SIZE_ATI* = 0x00008764
  GL_OBJECT_BUFFER_USAGE_ATI* = 0x00008765
  GL_ARRAY_OBJECT_BUFFER_ATI* = 0x00008766
  GL_ARRAY_OBJECT_OFFSET_ATI* = 0x00008767 # GL_ATI_vertex_streams
  GL_MAX_VERTEX_STREAMS_ATI* = 0x0000876B
  GL_VERTEX_STREAM0_ATI* = 0x0000876C
  GL_VERTEX_STREAM1_ATI* = 0x0000876D
  GL_VERTEX_STREAM2_ATI* = 0x0000876E
  GL_VERTEX_STREAM3_ATI* = 0x0000876F
  GL_VERTEX_STREAM4_ATI* = 0x00008770
  GL_VERTEX_STREAM5_ATI* = 0x00008771
  GL_VERTEX_STREAM6_ATI* = 0x00008772
  GL_VERTEX_STREAM7_ATI* = 0x00008773
  GL_VERTEX_SOURCE_ATI* = 0x00008774 # GL_ATI_meminfo
  GL_VBO_FREE_MEMORY_ATI* = 0x000087FB
  GL_TEXTURE_FREE_MEMORY_ATI* = 0x000087FC
  GL_RENDERBUFFER_FREE_MEMORY_ATI* = 0x000087FD # GL_AMD_performance_monitor
  GL_COUNTERtyp_AMD* = 0x00008BC0
  GL_COUNTER_RANGE_AMD* = 0x00008BC1
  GL_UNSIGNED_INT64_AMD* = 0x00008BC2
  GL_PERCENTAGE_AMD* = 0x00008BC3
  GL_PERFMON_RESULT_AVAILABLE_AMD* = 0x00008BC4
  GL_PERFMON_RESULT_SIZE_AMD* = 0x00008BC5
  GL_PERFMON_RESULT_AMD* = 0x00008BC6 # GL_AMD_vertex_shader_tesselator
  GL_SAMPLER_BUFFER_AMD* = 0x00009001
  GL_INT_SAMPLER_BUFFER_AMD* = 0x00009002
  GL_UNSIGNED_INT_SAMPLER_BUFFER_AMD* = 0x00009003
  cGL_TESSELLATION_MODE_AMD* = 0x00009004
  cGL_TESSELLATION_FACTOR_AMD* = 0x00009005
  GL_DISCRETE_AMD* = 0x00009006
  GL_CONTINUOUS_AMD* = 0x00009007 # GL_AMD_seamless_cubemap_per_texture
                                  # reuse GL_TEXTURE_CUBE_MAP_SEAMLESS
                                  # GL_AMD_name_gen_delete
  GL_DATA_BUFFER_AMD* = 0x00009151
  GL_PERFORMANCE_MONITOR_AMD* = 0x00009152
  GL_QUERY_OBJECT_AMD* = 0x00009153
  GL_VERTEX_ARRAY_OBJECT_AMD* = 0x00009154
  GL_SAMPLER_OBJECT_AMD* = 0x00009155 # GL_AMD_debug_output
  GL_MAX_DEBUG_LOGGED_MESSAGES_AMD* = 0x00009144
  GL_DEBUG_LOGGED_MESSAGES_AMD* = 0x00009145
  GL_DEBUG_SEVERITY_HIGH_AMD* = 0x00009146
  GL_DEBUG_SEVERITY_MEDIUM_AMD* = 0x00009147
  GL_DEBUG_SEVERITY_LOW_AMD* = 0x00009148
  GL_DEBUG_CATEGORY_API_ERROR_AMD* = 0x00009149
  GL_DEBUG_CATEGORY_WINDOW_SYSTEM_AMD* = 0x0000914A
  GL_DEBUG_CATEGORY_DEPRECATION_AMD* = 0x0000914B
  GL_DEBUG_CATEGORY_UNDEFINED_BEHAVIOR_AMD* = 0x0000914C
  GL_DEBUG_CATEGORY_PERFORMANCE_AMD* = 0x0000914D
  GL_DEBUG_CATEGORY_SHADER_COMPILER_AMD* = 0x0000914E
  GL_DEBUG_CATEGORY_APPLICATION_AMD* = 0x0000914F
  GL_DEBUG_CATEGORY_OTHER_AMD* = 0x00009150 # GL_AMD_depth_clamp_separate
  GL_DEPTH_CLAMP_NEAR_AMD* = 0x0000901E
  GL_DEPTH_CLAMP_FAR_AMD* = 0x0000901F # GL_EXT_422_pixels
  GL_422_EXT* = 0x000080CC
  GL_422_REV_EXT* = 0x000080CD
  GL_422_AVERAGE_EXT* = 0x000080CE
  GL_422_REV_AVERAGE_EXT* = 0x000080CF # GL_EXT_abgr
  GL_ABGR_EXT* = 0x00008000   # GL_EXT_bgra
  GL_BGR_EXT* = 0x000080E0
  GL_BGRA_EXT* = 0x000080E1   # GL_EXT_blend_color
  GL_CONSTANT_COLOR_EXT* = 0x00008001
  GL_ONE_MINUS_CONSTANT_COLOR_EXT* = 0x00008002
  GL_CONSTANT_ALPHA_EXT* = 0x00008003
  GL_ONE_MINUS_CONSTANT_ALPHA_EXT* = 0x00008004
  cGL_BLEND_COLOR_EXT* = 0x00008005 # GL_EXT_blend_func_separate
  GL_BLEND_DST_RGB_EXT* = 0x000080C8
  GL_BLEND_SRC_RGB_EXT* = 0x000080C9
  GL_BLEND_DST_ALPHA_EXT* = 0x000080CA
  GL_BLEND_SRC_ALPHA_EXT* = 0x000080CB # GL_EXT_blend_minmax
  GL_FUNC_ADD_EXT* = 0x00008006
  GL_MIN_EXT* = 0x00008007
  GL_MAX_EXT* = 0x00008008
  cGL_BLEND_EQUATION_EXT* = 0x00008009 # GL_EXT_blend_subtract
  GL_FUNC_SUBTRACT_EXT* = 0x0000800A
  GL_FUNC_REVERSE_SUBTRACT_EXT* = 0x0000800B # GL_EXT_clip_volume_hint
  GL_CLIP_VOLUME_CLIPPING_HINT_EXT* = 0x000080F0 # GL_EXT_cmyka
  GL_CMYK_EXT* = 0x0000800C
  GL_CMYKA_EXT* = 0x0000800D
  GL_PACK_CMYK_HINT_EXT* = 0x0000800E
  GL_UNPACK_CMYK_HINT_EXT* = 0x0000800F # GL_EXT_compiled_vertex_array
  GL_ARRAY_ELEMENT_LOCK_FIRST_EXT* = 0x000081A8
  GL_ARRAY_ELEMENT_LOCK_COUNT_EXT* = 0x000081A9 # GL_EXT_convolution
  GL_CONVOLUTION_1D_EXT* = 0x00008010
  GL_CONVOLUTION_2D_EXT* = 0x00008011
  GL_SEPARABLE_2D_EXT* = 0x00008012
  GL_CONVOLUTION_BORDER_MODE_EXT* = 0x00008013
  GL_CONVOLUTION_FILTER_SCALE_EXT* = 0x00008014
  GL_CONVOLUTION_FILTER_BIAS_EXT* = 0x00008015
  GL_REDUCE_EXT* = 0x00008016
  GL_CONVOLUTION_FORMAT_EXT* = 0x00008017
  GL_CONVOLUTION_WIDTH_EXT* = 0x00008018
  GL_CONVOLUTION_HEIGHT_EXT* = 0x00008019
  GL_MAX_CONVOLUTION_WIDTH_EXT* = 0x0000801A
  GL_MAX_CONVOLUTION_HEIGHT_EXT* = 0x0000801B
  GL_POST_CONVOLUTION_RED_SCALE_EXT* = 0x0000801C
  GL_POST_CONVOLUTION_GREEN_SCALE_EXT* = 0x0000801D
  GL_POST_CONVOLUTION_BLUE_SCALE_EXT* = 0x0000801E
  GL_POST_CONVOLUTION_ALPHA_SCALE_EXT* = 0x0000801F
  GL_POST_CONVOLUTION_RED_BIAS_EXT* = 0x00008020
  GL_POST_CONVOLUTION_GREEN_BIAS_EXT* = 0x00008021
  GL_POST_CONVOLUTION_BLUE_BIAS_EXT* = 0x00008022
  GL_POST_CONVOLUTION_ALPHA_BIAS_EXT* = 0x00008023 # GL_EXT_coordinate_frame
  GL_TANGENT_ARRAY_EXT* = 0x00008439
  GL_BINORMAL_ARRAY_EXT* = 0x0000843A
  GL_CURRENT_TANGENT_EXT* = 0x0000843B
  GL_CURRENT_BINORMAL_EXT* = 0x0000843C
  GL_TANGENT_ARRAYtyp_EXT* = 0x0000843E
  GL_TANGENT_ARRAY_STRIDE_EXT* = 0x0000843F
  GL_BINORMAL_ARRAYtyp_EXT* = 0x00008440
  GL_BINORMAL_ARRAY_STRIDE_EXT* = 0x00008441
  GL_TANGENT_ARRAY_POINTER_EXT* = 0x00008442
  GL_BINORMAL_ARRAY_POINTER_EXT* = 0x00008443
  GL_MAP1_TANGENT_EXT* = 0x00008444
  GL_MAP2_TANGENT_EXT* = 0x00008445
  GL_MAP1_BINORMAL_EXT* = 0x00008446
  GL_MAP2_BINORMAL_EXT* = 0x00008447 # GL_EXT_cull_vertex
  GL_CULL_VERTEX_EXT* = 0x000081AA
  GL_CULL_VERTEX_EYE_POSITION_EXT* = 0x000081AB
  GL_CULL_VERTEX_OBJECT_POSITION_EXT* = 0x000081AC # GL_EXT_draw_range_elements
  GL_MAX_ELEMENTS_VERTICES_EXT* = 0x000080E8
  GL_MAX_ELEMENTS_INDICES_EXT* = 0x000080E9 # GL_EXT_fog_coord
  GL_FOG_COORDINATE_SOURCE_EXT* = 0x00008450
  GL_FOG_COORDINATE_EXT* = 0x00008451
  GL_FRAGMENT_DEPTH_EXT* = 0x00008452
  GL_CURRENT_FOG_COORDINATE_EXT* = 0x00008453
  GL_FOG_COORDINATE_ARRAYtyp_EXT* = 0x00008454
  GL_FOG_COORDINATE_ARRAY_STRIDE_EXT* = 0x00008455
  GL_FOG_COORDINATE_ARRAY_POINTER_EXT* = 0x00008456
  GL_FOG_COORDINATE_ARRAY_EXT* = 0x00008457 # GL_EXT_framebuffer_object
  GL_FRAMEBUFFER_EXT* = 0x00008D40
  GL_RENDERBUFFER_EXT* = 0x00008D41
  GL_STENCIL_INDEX_EXT* = 0x00008D45
  GL_STENCIL_INDEX1_EXT* = 0x00008D46
  GL_STENCIL_INDEX4_EXT* = 0x00008D47
  GL_STENCIL_INDEX8_EXT* = 0x00008D48
  GL_STENCIL_INDEX16_EXT* = 0x00008D49
  GL_RENDERBUFFER_WIDTH_EXT* = 0x00008D42
  GL_RENDERBUFFER_HEIGHT_EXT* = 0x00008D43
  GL_RENDERBUFFER_INTERNAL_FORMAT_EXT* = 0x00008D44
  GL_FRAMEBUFFER_ATTACHMENT_OBJECTtyp_EXT* = 0x00008CD0
  GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME_EXT* = 0x00008CD1
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL_EXT* = 0x00008CD2
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE_EXT* = 0x00008CD3
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_3D_ZOFFSET_EXT* = 0x00008CD4
  GL_COLOR_ATTACHMENT0_EXT* = 0x00008CE0
  GL_COLOR_ATTACHMENT1_EXT* = 0x00008CE1
  GL_COLOR_ATTACHMENT2_EXT* = 0x00008CE2
  GL_COLOR_ATTACHMENT3_EXT* = 0x00008CE3
  GL_COLOR_ATTACHMENT4_EXT* = 0x00008CE4
  GL_COLOR_ATTACHMENT5_EXT* = 0x00008CE5
  GL_COLOR_ATTACHMENT6_EXT* = 0x00008CE6
  GL_COLOR_ATTACHMENT7_EXT* = 0x00008CE7
  GL_COLOR_ATTACHMENT8_EXT* = 0x00008CE8
  GL_COLOR_ATTACHMENT9_EXT* = 0x00008CE9
  GL_COLOR_ATTACHMENT10_EXT* = 0x00008CEA
  GL_COLOR_ATTACHMENT11_EXT* = 0x00008CEB
  GL_COLOR_ATTACHMENT12_EXT* = 0x00008CEC
  GL_COLOR_ATTACHMENT13_EXT* = 0x00008CED
  GL_COLOR_ATTACHMENT14_EXT* = 0x00008CEE
  GL_COLOR_ATTACHMENT15_EXT* = 0x00008CEF
  GL_DEPTH_ATTACHMENT_EXT* = 0x00008D00
  GL_STENCIL_ATTACHMENT_EXT* = 0x00008D20
  GL_FRAMEBUFFER_COMPLETE_EXT* = 0x00008CD5
  GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_EXT* = 0x00008CD6
  GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_EXT* = 0x00008CD7
  GL_FRAMEBUFFER_INCOMPLETE_DUPLICATE_ATTACHMENT_EXT* = 0x00008CD8
  GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT* = 0x00008CD9
  GL_FRAMEBUFFER_INCOMPLETE_FORMATS_EXT* = 0x00008CDA
  GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_EXT* = 0x00008CDB
  GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER_EXT* = 0x00008CDC
  GL_FRAMEBUFFER_UNSUPPORTED_EXT* = 0x00008CDD
  GL_FRAMEBUFFER_STATUS_ERROR_EXT* = 0x00008CDE
  GL_FRAMEBUFFER_BINDING_EXT* = 0x00008CA6
  GL_RENDERBUFFER_BINDING_EXT* = 0x00008CA7
  GL_MAX_COLOR_ATTACHMENTS_EXT* = 0x00008CDF
  GL_MAX_RENDERBUFFER_SIZE_EXT* = 0x000084E8
  GL_INVALID_FRAMEBUFFER_OPERATION_EXT* = 0x00000506 # GL_EXT_histogram
  cGL_HISTOGRAM_EXT* = 0x00008024
  GL_PROXY_HISTOGRAM_EXT* = 0x00008025
  GL_HISTOGRAM_WIDTH_EXT* = 0x00008026
  GL_HISTOGRAM_FORMAT_EXT* = 0x00008027
  GL_HISTOGRAM_RED_SIZE_EXT* = 0x00008028
  GL_HISTOGRAM_GREEN_SIZE_EXT* = 0x00008029
  GL_HISTOGRAM_BLUE_SIZE_EXT* = 0x0000802A
  GL_HISTOGRAM_ALPHA_SIZE_EXT* = 0x0000802B
  GL_HISTOGRAM_LUMINANCE_SIZE_EXT* = 0x0000802C
  GL_HISTOGRAM_SINK_EXT* = 0x0000802D
  cGL_MINMAX_EXT* = 0x0000802E
  GL_MINMAX_FORMAT_EXT* = 0x0000802F
  GL_MINMAX_SINK_EXT* = 0x00008030
  GL_TABLE_TOO_LARGE_EXT* = 0x00008031 # GL_EXT_index_array_formats
  GL_IUI_V2F_EXT* = 0x000081AD
  GL_IUI_V3F_EXT* = 0x000081AE
  GL_IUI_N3F_V2F_EXT* = 0x000081AF
  GL_IUI_N3F_V3F_EXT* = 0x000081B0
  GL_T2F_IUI_V2F_EXT* = 0x000081B1
  GL_T2F_IUI_V3F_EXT* = 0x000081B2
  GL_T2F_IUI_N3F_V2F_EXT* = 0x000081B3
  GL_T2F_IUI_N3F_V3F_EXT* = 0x000081B4 # GL_EXT_index_func
  GL_INDEX_TEST_EXT* = 0x000081B5
  GL_INDEX_TEST_FUNC_EXT* = 0x000081B6
  GL_INDEX_TEST_REF_EXT* = 0x000081B7 # GL_EXT_index_material
  cGL_INDEX_MATERIAL_EXT* = 0x000081B8
  GL_INDEX_MATERIAL_PARAMETER_EXT* = 0x000081B9
  GL_INDEX_MATERIAL_FACE_EXT* = 0x000081BA # GL_EXT_light_texture
  GL_FRAGMENT_MATERIAL_EXT* = 0x00008349
  GL_FRAGMENT_NORMAL_EXT* = 0x0000834A
  GL_FRAGMENT_COLOR_EXT* = 0x0000834C
  GL_ATTENUATION_EXT* = 0x0000834D
  GL_SHADOW_ATTENUATION_EXT* = 0x0000834E
  GL_TEXTURE_APPLICATION_MODE_EXT* = 0x0000834F
  cGL_TEXTURE_LIGHT_EXT* = 0x00008350
  GL_TEXTURE_MATERIAL_FACE_EXT* = 0x00008351
  GL_TEXTURE_MATERIAL_PARAMETER_EXT* = 0x00008352 # GL_EXT_multisample
  GL_MULTISAMPLE_EXT* = 0x0000809D
  GL_SAMPLE_ALPHA_TO_MASK_EXT* = 0x0000809E
  GL_SAMPLE_ALPHA_TO_ONE_EXT* = 0x0000809F
  cGL_SAMPLE_MASK_EXT* = 0x000080A0
  GL_1PASS_EXT* = 0x000080A1
  GL_2PASS_0_EXT* = 0x000080A2
  GL_2PASS_1_EXT* = 0x000080A3
  GL_4PASS_0_EXT* = 0x000080A4
  GL_4PASS_1_EXT* = 0x000080A5
  GL_4PASS_2_EXT* = 0x000080A6
  GL_4PASS_3_EXT* = 0x000080A7
  GL_SAMPLE_BUFFERS_EXT* = 0x000080A8
  GL_SAMPLES_EXT* = 0x000080A9
  GL_SAMPLE_MASK_VALUE_EXT* = 0x000080AA
  GL_SAMPLE_MASK_INVERT_EXT* = 0x000080AB
  cGL_SAMPLE_PATTERN_EXT* = 0x000080AC
  GL_MULTISAMPLE_BIT_EXT* = 0x20000000 # GL_EXT_packed_pixels
  GL_UNSIGNED_BYTE_3_3_2_EXT* = 0x00008032
  GL_UNSIGNED_SHORT_4_4_4_4_EXT* = 0x00008033
  GL_UNSIGNED_SHORT_5_5_5_1_EXT* = 0x00008034
  GL_UNSIGNED_INT_8_8_8_8_EXT* = 0x00008035
  GL_UNSIGNED_INT_10_10_10_2_EXT* = 0x00008036 # GL_EXT_paletted_texture
  GL_COLOR_INDEX1_EXT* = 0x000080E2
  GL_COLOR_INDEX2_EXT* = 0x000080E3
  GL_COLOR_INDEX4_EXT* = 0x000080E4
  GL_COLOR_INDEX8_EXT* = 0x000080E5
  GL_COLOR_INDEX12_EXT* = 0x000080E6
  GL_COLOR_INDEX16_EXT* = 0x000080E7
  GL_TEXTURE_INDEX_SIZE_EXT* = 0x000080ED # GL_EXT_pixel_transform
  GL_PIXEL_TRANSFORM_2D_EXT* = 0x00008330
  GL_PIXEL_MAG_FILTER_EXT* = 0x00008331
  GL_PIXEL_MIN_FILTER_EXT* = 0x00008332
  GL_PIXEL_CUBIC_WEIGHT_EXT* = 0x00008333
  GL_CUBIC_EXT* = 0x00008334
  GL_AVERAGE_EXT* = 0x00008335
  GL_PIXEL_TRANSFORM_2D_STACK_DEPTH_EXT* = 0x00008336
  GL_MAX_PIXEL_TRANSFORM_2D_STACK_DEPTH_EXT* = 0x00008337
  GL_PIXEL_TRANSFORM_2D_MATRIX_EXT* = 0x00008338 # GL_EXT_point_parameters
  GL_POINT_SIZE_MIN_EXT* = 0x00008126
  GL_POINT_SIZE_MAX_EXT* = 0x00008127
  GL_POINT_FADE_THRESHOLD_SIZE_EXT* = 0x00008128
  GL_DISTANCE_ATTENUATION_EXT* = 0x00008129 # GL_EXT_polygon_offset
  cGL_POLYGON_OFFSET_EXT* = 0x00008037
  GL_POLYGON_OFFSET_FACTOR_EXT* = 0x00008038
  GL_POLYGON_OFFSET_BIAS_EXT* = 0x00008039 # GL_EXT_rescale_normal
  GL_RESCALE_NORMAL_EXT* = 0x0000803A # GL_EXT_secondary_color
  GL_COLOR_SUM_EXT* = 0x00008458
  GL_CURRENT_SECONDARY_COLOR_EXT* = 0x00008459
  GL_SECONDARY_COLOR_ARRAY_SIZE_EXT* = 0x0000845A
  GL_SECONDARY_COLOR_ARRAYtyp_EXT* = 0x0000845B
  GL_SECONDARY_COLOR_ARRAY_STRIDE_EXT* = 0x0000845C
  GL_SECONDARY_COLOR_ARRAY_POINTER_EXT* = 0x0000845D
  GL_SECONDARY_COLOR_ARRAY_EXT* = 0x0000845E # GL_EXT_separate_specular_color
  GL_LIGHT_MODEL_COLOR_CONTROL_EXT* = 0x000081F8
  GL_SINGLE_COLOR_EXT* = 0x000081F9
  GL_SEPARATE_SPECULAR_COLOR_EXT* = 0x000081FA # GL_EXT_shared_texture_palette
  GL_SHARED_TEXTURE_PALETTE_EXT* = 0x000081FB # GL_EXT_stencil_two_side
  GL_STENCIL_TEST_TWO_SIDE_EXT* = 0x00008910
  cGL_ACTIVE_STENCIL_FACE_EXT* = 0x00008911 # GL_EXT_stencil_wrap
  GL_INCR_WRAP_EXT* = 0x00008507
  GL_DECR_WRAP_EXT* = 0x00008508 # GL_EXT_texture
  GL_ALPHA4_EXT* = 0x0000803B
  GL_ALPHA8_EXT* = 0x0000803C
  GL_ALPHA12_EXT* = 0x0000803D
  GL_ALPHA16_EXT* = 0x0000803E
  GL_LUMINANCE4_EXT* = 0x0000803F
  GL_LUMINANCE8_EXT* = 0x00008040
  GL_LUMINANCE12_EXT* = 0x00008041
  GL_LUMINANCE16_EXT* = 0x00008042
  GL_LUMINANCE4_ALPHA4_EXT* = 0x00008043
  GL_LUMINANCE6_ALPHA2_EXT* = 0x00008044
  GL_LUMINANCE8_ALPHA8_EXT* = 0x00008045
  GL_LUMINANCE12_ALPHA4_EXT* = 0x00008046
  GL_LUMINANCE12_ALPHA12_EXT* = 0x00008047
  GL_LUMINANCE16_ALPHA16_EXT* = 0x00008048
  GL_INTENSITY_EXT* = 0x00008049
  GL_INTENSITY4_EXT* = 0x0000804A
  GL_INTENSITY8_EXT* = 0x0000804B
  GL_INTENSITY12_EXT* = 0x0000804C
  GL_INTENSITY16_EXT* = 0x0000804D
  GL_RGB2_EXT* = 0x0000804E
  GL_RGB4_EXT* = 0x0000804F
  GL_RGB5_EXT* = 0x00008050
  GL_RGB8_EXT* = 0x00008051
  GL_RGB10_EXT* = 0x00008052
  GL_RGB12_EXT* = 0x00008053
  GL_RGB16_EXT* = 0x00008054
  GL_RGBA2_EXT* = 0x00008055
  GL_RGBA4_EXT* = 0x00008056
  GL_RGB5_A1_EXT* = 0x00008057
  GL_RGBA8_EXT* = 0x00008058
  GL_RGB10_A2_EXT* = 0x00008059
  GL_RGBA12_EXT* = 0x0000805A
  GL_RGBA16_EXT* = 0x0000805B
  GL_TEXTURE_RED_SIZE_EXT* = 0x0000805C
  GL_TEXTURE_GREEN_SIZE_EXT* = 0x0000805D
  GL_TEXTURE_BLUE_SIZE_EXT* = 0x0000805E
  GL_TEXTURE_ALPHA_SIZE_EXT* = 0x0000805F
  GL_TEXTURE_LUMINANCE_SIZE_EXT* = 0x00008060
  GL_TEXTURE_INTENSITY_SIZE_EXT* = 0x00008061
  GL_REPLACE_EXT* = 0x00008062
  GL_PROXY_TEXTURE_1D_EXT* = 0x00008063
  GL_PROXY_TEXTURE_2D_EXT* = 0x00008064
  GL_TEXTURE_TOO_LARGE_EXT* = 0x00008065 # GL_EXT_texture3D
  GL_PACK_SKIP_IMAGES_EXT* = 0x0000806B
  GL_PACK_IMAGE_HEIGHT_EXT* = 0x0000806C
  GL_UNPACK_SKIP_IMAGES_EXT* = 0x0000806D
  GL_UNPACK_IMAGE_HEIGHT_EXT* = 0x0000806E
  GL_TEXTURE_3D_EXT* = 0x0000806F
  GL_PROXY_TEXTURE_3D_EXT* = 0x00008070
  GL_TEXTURE_DEPTH_EXT* = 0x00008071
  GL_TEXTURE_WRAP_R_EXT* = 0x00008072
  GL_MAX_3D_TEXTURE_SIZE_EXT* = 0x00008073 # GL_EXT_texture_compression_s3tc
  GL_COMPRESSED_RGB_S3TC_DXT1_EXT* = 0x000083F0
  GL_COMPRESSED_RGBA_S3TC_DXT1_EXT* = 0x000083F1
  GL_COMPRESSED_RGBA_S3TC_DXT3_EXT* = 0x000083F2
  GL_COMPRESSED_RGBA_S3TC_DXT5_EXT* = 0x000083F3 # GL_EXT_texture_cube_map
  GL_NORMAL_MAP_EXT* = 0x00008511
  GL_REFLECTION_MAP_EXT* = 0x00008512
  GL_TEXTURE_CUBE_MAP_EXT* = 0x00008513
  GL_TEXTURE_BINDING_CUBE_MAP_EXT* = 0x00008514
  GL_TEXTURE_CUBE_MAP_POSITIVE_X_EXT* = 0x00008515
  GL_TEXTURE_CUBE_MAP_NEGATIVE_X_EXT* = 0x00008516
  GL_TEXTURE_CUBE_MAP_POSITIVE_Y_EXT* = 0x00008517
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_EXT* = 0x00008518
  GL_TEXTURE_CUBE_MAP_POSITIVE_Z_EXT* = 0x00008519
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_EXT* = 0x0000851A
  GL_PROXY_TEXTURE_CUBE_MAP_EXT* = 0x0000851B
  GL_MAX_CUBE_MAP_TEXTURE_SIZE_EXT* = 0x0000851C # GL_EXT_texture_edge_clamp
  GL_CLAMP_TO_EDGE_EXT* = 0x0000812F # GL_EXT_texture_env_combine
  GL_COMBINE_EXT* = 0x00008570
  GL_COMBINE_RGB_EXT* = 0x00008571
  GL_COMBINE_ALPHA_EXT* = 0x00008572
  GL_RGB_SCALE_EXT* = 0x00008573
  GL_ADD_SIGNED_EXT* = 0x00008574
  GL_INTERPOLATE_EXT* = 0x00008575
  GL_CONSTANT_EXT* = 0x00008576
  GL_PRIMARY_COLOR_EXT* = 0x00008577
  GL_PREVIOUS_EXT* = 0x00008578
  GL_SOURCE0_RGB_EXT* = 0x00008580
  GL_SOURCE1_RGB_EXT* = 0x00008581
  GL_SOURCE2_RGB_EXT* = 0x00008582
  GL_SOURCE0_ALPHA_EXT* = 0x00008588
  GL_SOURCE1_ALPHA_EXT* = 0x00008589
  GL_SOURCE2_ALPHA_EXT* = 0x0000858A
  GL_OPERAND0_RGB_EXT* = 0x00008590
  GL_OPERAND1_RGB_EXT* = 0x00008591
  GL_OPERAND2_RGB_EXT* = 0x00008592
  GL_OPERAND0_ALPHA_EXT* = 0x00008598
  GL_OPERAND1_ALPHA_EXT* = 0x00008599
  GL_OPERAND2_ALPHA_EXT* = 0x0000859A # GL_EXT_texture_env_dot3
  GL_DOT3_RGB_EXT* = 0x00008740
  GL_DOT3_RGBA_EXT* = 0x00008741 # GL_EXT_texture_filter_anisotropic
  GL_TEXTURE_MAX_ANISOTROPY_EXT* = 0x000084FE
  GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT* = 0x000084FF # GL_EXT_texture_lod_bias
  GL_MAX_TEXTURE_LOD_BIAS_EXT* = 0x000084FD
  GL_TEXTURE_FILTER_CONTROL_EXT* = 0x00008500
  GL_TEXTURE_LOD_BIAS_EXT* = 0x00008501 # GL_EXT_texture_object
  GL_TEXTURE_PRIORITY_EXT* = 0x00008066
  GL_TEXTURE_RESIDENT_EXT* = 0x00008067
  GL_TEXTURE_1D_BINDING_EXT* = 0x00008068
  GL_TEXTURE_2D_BINDING_EXT* = 0x00008069
  GL_TEXTURE_3D_BINDING_EXT* = 0x0000806A # GL_EXT_texture_perturb_normal
  GL_PERTURB_EXT* = 0x000085AE
  cGL_TEXTURE_NORMAL_EXT* = 0x000085AF # GL_EXT_texture_rectangle
  GL_TEXTURE_RECTANGLE_EXT* = 0x000084F5
  GL_TEXTURE_BINDING_RECTANGLE_EXT* = 0x000084F6
  GL_PROXY_TEXTURE_RECTANGLE_EXT* = 0x000084F7
  GL_MAX_RECTANGLE_TEXTURE_SIZE_EXT* = 0x000084F8 # GL_EXT_vertex_array
  GL_VERTEX_ARRAY_EXT* = 0x00008074
  GL_NORMAL_ARRAY_EXT* = 0x00008075
  GL_COLOR_ARRAY_EXT* = 0x00008076
  GL_INDEX_ARRAY_EXT* = 0x00008077
  GL_TEXTURE_COORD_ARRAY_EXT* = 0x00008078
  GL_EDGE_FLAG_ARRAY_EXT* = 0x00008079
  GL_VERTEX_ARRAY_SIZE_EXT* = 0x0000807A
  GL_VERTEX_ARRAYtyp_EXT* = 0x0000807B
  GL_VERTEX_ARRAY_STRIDE_EXT* = 0x0000807C
  GL_VERTEX_ARRAY_COUNT_EXT* = 0x0000807D
  GL_NORMAL_ARRAYtyp_EXT* = 0x0000807E
  GL_NORMAL_ARRAY_STRIDE_EXT* = 0x0000807F
  GL_NORMAL_ARRAY_COUNT_EXT* = 0x00008080
  GL_COLOR_ARRAY_SIZE_EXT* = 0x00008081
  GL_COLOR_ARRAYtyp_EXT* = 0x00008082
  GL_COLOR_ARRAY_STRIDE_EXT* = 0x00008083
  GL_COLOR_ARRAY_COUNT_EXT* = 0x00008084
  GL_INDEX_ARRAYtyp_EXT* = 0x00008085
  GL_INDEX_ARRAY_STRIDE_EXT* = 0x00008086
  GL_INDEX_ARRAY_COUNT_EXT* = 0x00008087
  GL_TEXTURE_COORD_ARRAY_SIZE_EXT* = 0x00008088
  GL_TEXTURE_COORD_ARRAYtyp_EXT* = 0x00008089
  GL_TEXTURE_COORD_ARRAY_STRIDE_EXT* = 0x0000808A
  GL_TEXTURE_COORD_ARRAY_COUNT_EXT* = 0x0000808B
  GL_EDGE_FLAG_ARRAY_STRIDE_EXT* = 0x0000808C
  GL_EDGE_FLAG_ARRAY_COUNT_EXT* = 0x0000808D
  GL_VERTEX_ARRAY_POINTER_EXT* = 0x0000808E
  GL_NORMAL_ARRAY_POINTER_EXT* = 0x0000808F
  GL_COLOR_ARRAY_POINTER_EXT* = 0x00008090
  GL_INDEX_ARRAY_POINTER_EXT* = 0x00008091
  GL_TEXTURE_COORD_ARRAY_POINTER_EXT* = 0x00008092
  GL_EDGE_FLAG_ARRAY_POINTER_EXT* = 0x00008093 # GL_EXT_vertex_shader
  GL_VERTEX_SHADER_EXT* = 0x00008780
  GL_VERTEX_SHADER_BINDING_EXT* = 0x00008781
  GL_OP_INDEX_EXT* = 0x00008782
  GL_OP_NEGATE_EXT* = 0x00008783
  GL_OP_DOT3_EXT* = 0x00008784
  GL_OP_DOT4_EXT* = 0x00008785
  GL_OP_MUL_EXT* = 0x00008786
  GL_OP_ADD_EXT* = 0x00008787
  GL_OP_MADD_EXT* = 0x00008788
  GL_OP_FRAC_EXT* = 0x00008789
  GL_OP_MAX_EXT* = 0x0000878A
  GL_OP_MIN_EXT* = 0x0000878B
  GL_OP_SET_GE_EXT* = 0x0000878C
  GL_OP_SET_LT_EXT* = 0x0000878D
  GL_OP_CLAMP_EXT* = 0x0000878E
  GL_OP_FLOOR_EXT* = 0x0000878F
  GL_OP_ROUND_EXT* = 0x00008790
  GL_OP_EXP_BASE_2_EXT* = 0x00008791
  GL_OP_LOG_BASE_2_EXT* = 0x00008792
  GL_OP_POWER_EXT* = 0x00008793
  GL_OP_RECIP_EXT* = 0x00008794
  GL_OP_RECIP_SQRT_EXT* = 0x00008795
  GL_OP_SUB_EXT* = 0x00008796
  GL_OP_CROSS_PRODUCT_EXT* = 0x00008797
  GL_OP_MULTIPLY_MATRIX_EXT* = 0x00008798
  GL_OP_MOV_EXT* = 0x00008799
  GL_OUTPUT_VERTEX_EXT* = 0x0000879A
  GL_OUTPUT_COLOR0_EXT* = 0x0000879B
  GL_OUTPUT_COLOR1_EXT* = 0x0000879C
  GL_OUTPUT_TEXTURE_COORD0_EXT* = 0x0000879D
  GL_OUTPUT_TEXTURE_COORD1_EXT* = 0x0000879E
  GL_OUTPUT_TEXTURE_COORD2_EXT* = 0x0000879F
  GL_OUTPUT_TEXTURE_COORD3_EXT* = 0x000087A0
  GL_OUTPUT_TEXTURE_COORD4_EXT* = 0x000087A1
  GL_OUTPUT_TEXTURE_COORD5_EXT* = 0x000087A2
  GL_OUTPUT_TEXTURE_COORD6_EXT* = 0x000087A3
  GL_OUTPUT_TEXTURE_COORD7_EXT* = 0x000087A4
  GL_OUTPUT_TEXTURE_COORD8_EXT* = 0x000087A5
  GL_OUTPUT_TEXTURE_COORD9_EXT* = 0x000087A6
  GL_OUTPUT_TEXTURE_COORD10_EXT* = 0x000087A7
  GL_OUTPUT_TEXTURE_COORD11_EXT* = 0x000087A8
  GL_OUTPUT_TEXTURE_COORD12_EXT* = 0x000087A9
  GL_OUTPUT_TEXTURE_COORD13_EXT* = 0x000087AA
  GL_OUTPUT_TEXTURE_COORD14_EXT* = 0x000087AB
  GL_OUTPUT_TEXTURE_COORD15_EXT* = 0x000087AC
  GL_OUTPUT_TEXTURE_COORD16_EXT* = 0x000087AD
  GL_OUTPUT_TEXTURE_COORD17_EXT* = 0x000087AE
  GL_OUTPUT_TEXTURE_COORD18_EXT* = 0x000087AF
  GL_OUTPUT_TEXTURE_COORD19_EXT* = 0x000087B0
  GL_OUTPUT_TEXTURE_COORD20_EXT* = 0x000087B1
  GL_OUTPUT_TEXTURE_COORD21_EXT* = 0x000087B2
  GL_OUTPUT_TEXTURE_COORD22_EXT* = 0x000087B3
  GL_OUTPUT_TEXTURE_COORD23_EXT* = 0x000087B4
  GL_OUTPUT_TEXTURE_COORD24_EXT* = 0x000087B5
  GL_OUTPUT_TEXTURE_COORD25_EXT* = 0x000087B6
  GL_OUTPUT_TEXTURE_COORD26_EXT* = 0x000087B7
  GL_OUTPUT_TEXTURE_COORD27_EXT* = 0x000087B8
  GL_OUTPUT_TEXTURE_COORD28_EXT* = 0x000087B9
  GL_OUTPUT_TEXTURE_COORD29_EXT* = 0x000087BA
  GL_OUTPUT_TEXTURE_COORD30_EXT* = 0x000087BB
  GL_OUTPUT_TEXTURE_COORD31_EXT* = 0x000087BC
  GL_OUTPUT_FOG_EXT* = 0x000087BD
  GL_SCALAR_EXT* = 0x000087BE
  GL_VECTOR_EXT* = 0x000087BF
  GL_MATRIX_EXT* = 0x000087C0
  GL_VARIANT_EXT* = 0x000087C1
  GL_INVARIANT_EXT* = 0x000087C2
  GL_LOCAL_CONSTANT_EXT* = 0x000087C3
  GL_LOCAL_EXT* = 0x000087C4
  GL_MAX_VERTEX_SHADER_INSTRUCTIONS_EXT* = 0x000087C5
  GL_MAX_VERTEX_SHADER_VARIANTS_EXT* = 0x000087C6
  GL_MAX_VERTEX_SHADER_INVARIANTS_EXT* = 0x000087C7
  GL_MAX_VERTEX_SHADER_LOCAL_CONSTANTS_EXT* = 0x000087C8
  GL_MAX_VERTEX_SHADER_LOCALS_EXT* = 0x000087C9
  GL_MAX_OPTIMIZED_VERTEX_SHADER_INSTRUCTIONS_EXT* = 0x000087CA
  GL_MAX_OPTIMIZED_VERTEX_SHADER_VARIANTS_EXT* = 0x000087CB
  GL_MAX_OPTIMIZED_VERTEX_SHADER_LOCAL_CONSTANTS_EXT* = 0x000087CC
  GL_MAX_OPTIMIZED_VERTEX_SHADER_INVARIANTS_EXT* = 0x000087CD
  GL_MAX_OPTIMIZED_VERTEX_SHADER_LOCALS_EXT* = 0x000087CE
  GL_VERTEX_SHADER_INSTRUCTIONS_EXT* = 0x000087CF
  GL_VERTEX_SHADER_VARIANTS_EXT* = 0x000087D0
  GL_VERTEX_SHADER_INVARIANTS_EXT* = 0x000087D1
  GL_VERTEX_SHADER_LOCAL_CONSTANTS_EXT* = 0x000087D2
  GL_VERTEX_SHADER_LOCALS_EXT* = 0x000087D3
  GL_VERTEX_SHADER_OPTIMIZED_EXT* = 0x000087D4
  GL_X_EXT* = 0x000087D5
  GL_Y_EXT* = 0x000087D6
  GL_Z_EXT* = 0x000087D7
  GL_W_EXT* = 0x000087D8
  GL_NEGATIVE_X_EXT* = 0x000087D9
  GL_NEGATIVE_Y_EXT* = 0x000087DA
  GL_NEGATIVE_Z_EXT* = 0x000087DB
  GL_NEGATIVE_W_EXT* = 0x000087DC
  GL_ZERO_EXT* = 0x000087DD
  GL_ONE_EXT* = 0x000087DE
  GL_NEGATIVE_ONE_EXT* = 0x000087DF
  GL_NORMALIZED_RANGE_EXT* = 0x000087E0
  GL_FULL_RANGE_EXT* = 0x000087E1
  GL_CURRENT_VERTEX_EXT* = 0x000087E2
  GL_MVP_MATRIX_EXT* = 0x000087E3
  GL_VARIANT_VALUE_EXT* = 0x000087E4
  GL_VARIANT_DATAtypEXT* = 0x000087E5
  GL_VARIANT_ARRAY_STRIDE_EXT* = 0x000087E6
  GL_VARIANT_ARRAYtyp_EXT* = 0x000087E7
  GL_VARIANT_ARRAY_EXT* = 0x000087E8
  GL_VARIANT_ARRAY_POINTER_EXT* = 0x000087E9
  GL_INVARIANT_VALUE_EXT* = 0x000087EA
  GL_INVARIANT_DATAtypEXT* = 0x000087EB
  GL_LOCAL_CONSTANT_VALUE_EXT* = 0x000087EC
  GL_LOCAL_CONSTANT_DATAtypEXT* = 0x000087ED # GL_EXT_vertex_weighting
  GL_MODELVIEW0_STACK_DEPTH_EXT* = 0x00000BA3
  GL_MODELVIEW1_STACK_DEPTH_EXT* = 0x00008502
  GL_MODELVIEW0_MATRIX_EXT* = 0x00000BA6
  GL_MODELVIEW1_MATRIX_EXT* = 0x00008506
  GL_VERTEX_WEIGHTING_EXT* = 0x00008509
  GL_MODELVIEW0_EXT* = 0x00001700
  GL_MODELVIEW1_EXT* = 0x0000850A
  GL_CURRENT_VERTEX_WEIGHT_EXT* = 0x0000850B
  GL_VERTEX_WEIGHT_ARRAY_EXT* = 0x0000850C
  GL_VERTEX_WEIGHT_ARRAY_SIZE_EXT* = 0x0000850D
  GL_VERTEX_WEIGHT_ARRAYtyp_EXT* = 0x0000850E
  GL_VERTEX_WEIGHT_ARRAY_STRIDE_EXT* = 0x0000850F
  GL_VERTEX_WEIGHT_ARRAY_POINTER_EXT* = 0x00008510 # GL_EXT_depth_bounds_test
  GL_DEPTH_BOUNDS_TEST_EXT* = 0x00008890
  cGL_DEPTH_BOUNDS_EXT* = 0x00008891 # GL_EXT_texture_mirror_clamp
  GL_MIRROR_CLAMP_EXT* = 0x00008742
  GL_MIRROR_CLAMP_TO_EDGE_EXT* = 0x00008743
  GL_MIRROR_CLAMP_TO_BORDER_EXT* = 0x00008912 # GL_EXT_blend_equation_separate
  GL_BLEND_EQUATION_RGB_EXT* = 0x00008009
  GL_BLEND_EQUATION_ALPHA_EXT* = 0x0000883D # GL_EXT_pixel_buffer_object
  GL_PIXEL_PACK_BUFFER_EXT* = 0x000088EB
  GL_PIXEL_UNPACK_BUFFER_EXT* = 0x000088EC
  GL_PIXEL_PACK_BUFFER_BINDING_EXT* = 0x000088ED
  GL_PIXEL_UNPACK_BUFFER_BINDING_EXT* = 0x000088EF # GL_EXT_stencil_clear_tag
  GL_STENCIL_TAG_BITS_EXT* = 0x000088F2
  GL_STENCIL_CLEAR_TAG_VALUE_EXT* = 0x000088F3 # GL_EXT_packed_depth_stencil
  GL_DEPTH_STENCIL_EXT* = 0x000084F9
  GL_UNSIGNED_INT_24_8_EXT* = 0x000084FA
  GL_DEPTH24_STENCIL8_EXT* = 0x000088F0
  GL_TEXTURE_STENCIL_SIZE_EXT* = 0x000088F1 # GL_EXT_texture_sRGB
  GL_SRGB_EXT* = 0x00008C40
  GL_SRGB8_EXT* = 0x00008C41
  GL_SRGB_ALPHA_EXT* = 0x00008C42
  GL_SRGB8_ALPHA8_EXT* = 0x00008C43
  GL_SLUMINANCE_ALPHA_EXT* = 0x00008C44
  GL_SLUMINANCE8_ALPHA8_EXT* = 0x00008C45
  GL_SLUMINANCE_EXT* = 0x00008C46
  GL_SLUMINANCE8_EXT* = 0x00008C47
  GL_COMPRESSED_SRGB_EXT* = 0x00008C48
  GL_COMPRESSED_SRGB_ALPHA_EXT* = 0x00008C49
  GL_COMPRESSED_SLUMINANCE_EXT* = 0x00008C4A
  GL_COMPRESSED_SLUMINANCE_ALPHA_EXT* = 0x00008C4B
  GL_COMPRESSED_SRGB_S3TC_DXT1_EXT* = 0x00008C4C
  GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT* = 0x00008C4D
  GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT* = 0x00008C4E
  GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT* = 0x00008C4F # GL_EXT_framebuffer_blit
  GL_READ_FRAMEBUFFER_EXT* = 0x00008CA8
  GL_DRAW_FRAMEBUFFER_EXT* = 0x00008CA9
  GL_READ_FRAMEBUFFER_BINDING_EXT* = GL_FRAMEBUFFER_BINDING_EXT
  GL_DRAW_FRAMEBUFFER_BINDING_EXT* = 0x00008CAA # GL_EXT_framebuffer_multisample
  GL_RENDERBUFFER_SAMPLES_EXT* = 0x00008CAB
  GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_EXT* = 0x00008D56
  GL_MAX_SAMPLES_EXT* = 0x00008D57 # GL_EXT_timer_query
  GL_TIME_ELAPSED_EXT* = 0x000088BF # GL_EXT_bindable_uniform
  GL_MAX_VERTEX_BINDABLE_UNIFORMS_EXT* = 0x00008DE2
  GL_MAX_FRAGMENT_BINDABLE_UNIFORMS_EXT* = 0x00008DE3
  GL_MAX_GEOMETRY_BINDABLE_UNIFORMS_EXT* = 0x00008DE4
  GL_MAX_BINDABLE_UNIFORM_SIZE_EXT* = 0x00008DED
  cGL_UNIFORM_BUFFER_EXT* = 0x00008DEE
  GL_UNIFORM_BUFFER_BINDING_EXT* = 0x00008DEF # GL_EXT_framebuffer_sRGB
  GLX_FRAMEBUFFER_SRGB_CAPABLE_EXT* = 0x000020B2
  WGL_FRAMEBUFFER_SRGB_CAPABLE_EXT* = 0x000020A9
  GL_FRAMEBUFFER_SRGB_EXT* = 0x00008DB9
  GL_FRAMEBUFFER_SRGB_CAPABLE_EXT* = 0x00008DBA # GL_EXT_geometry_shader4
  GL_GEOMETRY_SHADER_EXT* = 0x00008DD9
  GL_GEOMETRY_VERTICES_OUT_EXT* = 0x00008DDA
  GL_GEOMETRY_INPUTtyp_EXT* = 0x00008DDB
  GL_GEOMETRY_OUTPUTtyp_EXT* = 0x00008DDC
  GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS_EXT* = 0x00008C29
  GL_MAX_GEOMETRY_VARYING_COMPONENTS_EXT* = 0x00008DDD
  GL_MAX_VERTEX_VARYING_COMPONENTS_EXT* = 0x00008DDE
  GL_MAX_VARYING_COMPONENTS_EXT* = 0x00008B4B
  GL_MAX_GEOMETRY_UNIFORM_COMPONENTS_EXT* = 0x00008DDF
  GL_MAX_GEOMETRY_OUTPUT_VERTICES_EXT* = 0x00008DE0
  GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS_EXT* = 0x00008DE1
  GL_LINES_ADJACENCY_EXT* = 0x0000000A
  GL_LINE_STRIP_ADJACENCY_EXT* = 0x0000000B
  GL_TRIANGLES_ADJACENCY_EXT* = 0x0000000C
  GL_TRIANGLE_STRIP_ADJACENCY_EXT* = 0x0000000D
  GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS_EXT* = 0x00008DA8
  GL_FRAMEBUFFER_INCOMPLETE_LAYER_COUNT_EXT* = 0x00008DA9
  GL_FRAMEBUFFER_ATTACHMENT_LAYERED_EXT* = 0x00008DA7
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER_EXT* = 0x00008CD4
  GL_PROGRAM_POINT_SIZE_EXT* = 0x00008642 # GL_EXT_gpu_shader4
  GL_VERTEX_ATTRIB_ARRAY_INTEGER_EXT* = 0x000088FD
  GL_SAMPLER_1D_ARRAY_EXT* = 0x00008DC0
  GL_SAMPLER_2D_ARRAY_EXT* = 0x00008DC1
  GL_SAMPLER_BUFFER_EXT* = 0x00008DC2
  GL_SAMPLER_1D_ARRAY_SHADOW_EXT* = 0x00008DC3
  GL_SAMPLER_2D_ARRAY_SHADOW_EXT* = 0x00008DC4
  GL_SAMPLER_CUBE_SHADOW_EXT* = 0x00008DC5
  GL_UNSIGNED_INT_VEC2_EXT* = 0x00008DC6
  GL_UNSIGNED_INT_VEC3_EXT* = 0x00008DC7
  GL_UNSIGNED_INT_VEC4_EXT* = 0x00008DC8
  GL_INT_SAMPLER_1D_EXT* = 0x00008DC9
  GL_INT_SAMPLER_2D_EXT* = 0x00008DCA
  GL_INT_SAMPLER_3D_EXT* = 0x00008DCB
  GL_INT_SAMPLER_CUBE_EXT* = 0x00008DCC
  GL_INT_SAMPLER_2D_RECT_EXT* = 0x00008DCD
  GL_INT_SAMPLER_1D_ARRAY_EXT* = 0x00008DCE
  GL_INT_SAMPLER_2D_ARRAY_EXT* = 0x00008DCF
  GL_INT_SAMPLER_BUFFER_EXT* = 0x00008DD0
  GL_UNSIGNED_INT_SAMPLER_1D_EXT* = 0x00008DD1
  GL_UNSIGNED_INT_SAMPLER_2D_EXT* = 0x00008DD2
  GL_UNSIGNED_INT_SAMPLER_3D_EXT* = 0x00008DD3
  GL_UNSIGNED_INT_SAMPLER_CUBE_EXT* = 0x00008DD4
  GL_UNSIGNED_INT_SAMPLER_2D_RECT_EXT* = 0x00008DD5
  GL_UNSIGNED_INT_SAMPLER_1D_ARRAY_EXT* = 0x00008DD6
  GL_UNSIGNED_INT_SAMPLER_2D_ARRAY_EXT* = 0x00008DD7
  GL_UNSIGNED_INT_SAMPLER_BUFFER_EXT* = 0x00008DD8
  GL_MIN_PROGRAM_TEXEL_OFFSET_EXT* = 0x00008904
  GL_MAX_PROGRAM_TEXEL_OFFSET_EXT* = 0x00008905 # GL_EXT_packed_float
  GL_R11F_G11F_B10F_EXT* = 0x00008C3A
  GL_UNSIGNED_INT_10F_11F_11F_REV_EXT* = 0x00008C3B
  RGBA_SIGNED_COMPONENTS_EXT* = 0x00008C3C
  WGLtyp_RGBA_UNSIGNED_FLOAT_EXT* = 0x000020A8
  GLX_RGBA_UNSIGNED_FLOATtyp_EXT* = 0x000020B1
  GLX_RGBA_UNSIGNED_FLOAT_BIT_EXT* = 0x00000008 # GL_EXT_texture_array
  GL_TEXTURE_1D_ARRAY_EXT* = 0x00008C18
  GL_TEXTURE_2D_ARRAY_EXT* = 0x00008C1A
  GL_PROXY_TEXTURE_2D_ARRAY_EXT* = 0x00008C1B
  GL_PROXY_TEXTURE_1D_ARRAY_EXT* = 0x00008C19
  GL_TEXTURE_BINDING_1D_ARRAY_EXT* = 0x00008C1C
  GL_TEXTURE_BINDING_2D_ARRAY_EXT* = 0x00008C1D
  GL_MAX_ARRAY_TEXTURE_LAYERS_EXT* = 0x000088FF
  GL_COMPARE_REF_DEPTH_TO_TEXTURE_EXT* = 0x0000884E # GL_EXT_texture_buffer_object
  cGL_TEXTURE_BUFFER_EXT* = 0x00008C2A
  GL_MAX_TEXTURE_BUFFER_SIZE_EXT* = 0x00008C2B
  GL_TEXTURE_BINDING_BUFFER_EXT* = 0x00008C2C
  GL_TEXTURE_BUFFER_DATA_STORE_BINDING_EXT* = 0x00008C2D
  GL_TEXTURE_BUFFER_FORMAT_EXT* = 0x00008C2E # GL_EXT_texture_compression_latc
  GL_COMPRESSED_LUMINANCE_LATC1_EXT* = 0x00008C70
  GL_COMPRESSED_SIGNED_LUMINANCE_LATC1_EXT* = 0x00008C71
  GL_COMPRESSED_LUMINANCE_ALPHA_LATC2_EXT* = 0x00008C72
  GL_COMPRESSED_SIGNED_LUMINANCE_ALPHA_LATC2_EXT* = 0x00008C73 #
                                                               # GL_EXT_texture_compression_rgtc
  GL_COMPRESSED_RED_RGTC1_EXT* = 0x00008DBB
  GL_COMPRESSED_SIGNED_RED_RGTC1_EXT* = 0x00008DBC
  GL_COMPRESSED_RED_GREEN_RGTC2_EXT* = 0x00008DBD
  GL_COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT* = 0x00008DBE # GL_EXT_texture_integer
  GL_RGBA_INTEGER_MODE_EXT* = 0x00008D9E
  GL_RGBA32UI_EXT* = 0x00008D70
  GL_RGB32UI_EXT* = 0x00008D71
  GL_ALPHA32UI_EXT* = 0x00008D72
  GL_INTENSITY32UI_EXT* = 0x00008D73
  GL_LUMINANCE32UI_EXT* = 0x00008D74
  GL_LUMINANCE_ALPHA32UI_EXT* = 0x00008D75
  GL_RGBA16UI_EXT* = 0x00008D76
  GL_RGB16UI_EXT* = 0x00008D77
  GL_ALPHA16UI_EXT* = 0x00008D78
  GL_INTENSITY16UI_EXT* = 0x00008D79
  GL_LUMINANCE16UI_EXT* = 0x00008D7A
  GL_LUMINANCE_ALPHA16UI_EXT* = 0x00008D7B
  GL_RGBA8UI_EXT* = 0x00008D7C
  GL_RGB8UI_EXT* = 0x00008D7D
  GL_ALPHA8UI_EXT* = 0x00008D7E
  GL_INTENSITY8UI_EXT* = 0x00008D7F
  GL_LUMINANCE8UI_EXT* = 0x00008D80
  GL_LUMINANCE_ALPHA8UI_EXT* = 0x00008D81
  GL_RGBA32I_EXT* = 0x00008D82
  GL_RGB32I_EXT* = 0x00008D83
  GL_ALPHA32I_EXT* = 0x00008D84
  GL_INTENSITY32I_EXT* = 0x00008D85
  GL_LUMINANCE32I_EXT* = 0x00008D86
  GL_LUMINANCE_ALPHA32I_EXT* = 0x00008D87
  GL_RGBA16I_EXT* = 0x00008D88
  GL_RGB16I_EXT* = 0x00008D89
  GL_ALPHA16I_EXT* = 0x00008D8A
  GL_INTENSITY16I_EXT* = 0x00008D8B
  GL_LUMINANCE16I_EXT* = 0x00008D8C
  GL_LUMINANCE_ALPHA16I_EXT* = 0x00008D8D
  GL_RGBA8I_EXT* = 0x00008D8E
  GL_RGB8I_EXT* = 0x00008D8F
  GL_ALPHA8I_EXT* = 0x00008D90
  GL_INTENSITY8I_EXT* = 0x00008D91
  GL_LUMINANCE8I_EXT* = 0x00008D92
  GL_LUMINANCE_ALPHA8I_EXT* = 0x00008D93
  GL_RED_INTEGER_EXT* = 0x00008D94
  GL_GREEN_INTEGER_EXT* = 0x00008D95
  GL_BLUE_INTEGER_EXT* = 0x00008D96
  GL_ALPHA_INTEGER_EXT* = 0x00008D97
  GL_RGB_INTEGER_EXT* = 0x00008D98
  GL_RGBA_INTEGER_EXT* = 0x00008D99
  GL_BGR_INTEGER_EXT* = 0x00008D9A
  GL_BGRA_INTEGER_EXT* = 0x00008D9B
  GL_LUMINANCE_INTEGER_EXT* = 0x00008D9C
  GL_LUMINANCE_ALPHA_INTEGER_EXT* = 0x00008D9D # GL_EXT_texture_shared_exponent
  GL_RGB9_E5_EXT* = 0x00008C3D
  GL_UNSIGNED_INT_5_9_9_9_REV_EXT* = 0x00008C3E
  GL_TEXTURE_SHARED_SIZE_EXT* = 0x00008C3F # GL_EXT_transform_feedback
  GL_TRANSFORM_FEEDBACK_BUFFER_EXT* = 0x00008C8E
  GL_TRANSFORM_FEEDBACK_BUFFER_START_EXT* = 0x00008C84
  GL_TRANSFORM_FEEDBACK_BUFFER_SIZE_EXT* = 0x00008C85
  GL_TRANSFORM_FEEDBACK_BUFFER_BINDING_EXT* = 0x00008C8F
  GL_INTERLEAVED_ATTRIBS_EXT* = 0x00008C8C
  GL_SEPARATE_ATTRIBS_EXT* = 0x00008C8D
  GL_PRIMITIVES_GENERATED_EXT* = 0x00008C87
  GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN_EXT* = 0x00008C88
  GL_RASTERIZER_DISCARD_EXT* = 0x00008C89
  GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS_EXT* = 0x00008C8A
  GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS_EXT* = 0x00008C8B
  GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS_EXT* = 0x00008C80
  cGL_TRANSFORM_FEEDBACK_VARYINGS_EXT* = 0x00008C83
  GL_TRANSFORM_FEEDBACK_BUFFER_MODE_EXT* = 0x00008C7F
  GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH_EXT* = 0x00008C76 #
                                                             # GL_EXT_direct_state_access
  GL_PROGRAM_MATRIX_EXT* = 0x00008E2D
  GL_TRANSPOSE_PROGRAM_MATRIX_EXT* = 0x00008E2E
  GL_PROGRAM_MATRIX_STACK_DEPTH_EXT* = 0x00008E2F # GL_EXT_texture_swizzle
  GL_TEXTURE_SWIZZLE_R_EXT* = 0x00008E42
  GL_TEXTURE_SWIZZLE_G_EXT* = 0x00008E43
  GL_TEXTURE_SWIZZLE_B_EXT* = 0x00008E44
  GL_TEXTURE_SWIZZLE_A_EXT* = 0x00008E45
  GL_TEXTURE_SWIZZLE_RGBA_EXT* = 0x00008E46 # GL_EXT_provoking_vertex
  GL_QUADS_FOLLOW_PROVOKING_VERTEX_CONVENTION_EXT* = 0x00008E4C
  GL_FIRST_VERTEX_CONVENTION_EXT* = 0x00008E4D
  GL_LAST_VERTEX_CONVENTION_EXT* = 0x00008E4E
  GL_PROVOKING_VERTEX_EXT* = 0x00008E4F # GL_EXT_texture_snorm
  GL_ALPHA_SNORM* = 0x00009010
  GL_LUMINANCE_SNORM* = 0x00009011
  GL_LUMINANCE_ALPHA_SNORM* = 0x00009012
  GL_INTENSITY_SNORM* = 0x00009013
  GL_ALPHA8_SNORM* = 0x00009014
  GL_LUMINANCE8_SNORM* = 0x00009015
  GL_LUMINANCE8_ALPHA8_SNORM* = 0x00009016
  GL_INTENSITY8_SNORM* = 0x00009017
  GL_ALPHA16_SNORM* = 0x00009018
  GL_LUMINANCE16_SNORM* = 0x00009019
  GL_LUMINANCE16_ALPHA16_SNORM* = 0x0000901A
  GL_INTENSITY16_SNORM* = 0x0000901B # GL_EXT_separate_shader_objects
  cGL_ACTIVE_PROGRAM_EXT* = 0x00008B8D # GL_EXT_shader_image_load_store
  GL_MAX_IMAGE_UNITS_EXT* = 0x00008F38
  GL_MAX_COMBINED_IMAGE_UNITS_AND_FRAGMENT_OUTPUTS_EXT* = 0x00008F39
  GL_IMAGE_BINDING_NAME_EXT* = 0x00008F3A
  GL_IMAGE_BINDING_LEVEL_EXT* = 0x00008F3B
  GL_IMAGE_BINDING_LAYERED_EXT* = 0x00008F3C
  GL_IMAGE_BINDING_LAYER_EXT* = 0x00008F3D
  GL_IMAGE_BINDING_ACCESS_EXT* = 0x00008F3E
  GL_IMAGE_1D_EXT* = 0x0000904C
  GL_IMAGE_2D_EXT* = 0x0000904D
  GL_IMAGE_3D_EXT* = 0x0000904E
  GL_IMAGE_2D_RECT_EXT* = 0x0000904F
  GL_IMAGE_CUBE_EXT* = 0x00009050
  GL_IMAGE_BUFFER_EXT* = 0x00009051
  GL_IMAGE_1D_ARRAY_EXT* = 0x00009052
  GL_IMAGE_2D_ARRAY_EXT* = 0x00009053
  GL_IMAGE_CUBE_MAP_ARRAY_EXT* = 0x00009054
  GL_IMAGE_2D_MULTISAMPLE_EXT* = 0x00009055
  GL_IMAGE_2D_MULTISAMPLE_ARRAY_EXT* = 0x00009056
  GL_INT_IMAGE_1D_EXT* = 0x00009057
  GL_INT_IMAGE_2D_EXT* = 0x00009058
  GL_INT_IMAGE_3D_EXT* = 0x00009059
  GL_INT_IMAGE_2D_RECT_EXT* = 0x0000905A
  GL_INT_IMAGE_CUBE_EXT* = 0x0000905B
  GL_INT_IMAGE_BUFFER_EXT* = 0x0000905C
  GL_INT_IMAGE_1D_ARRAY_EXT* = 0x0000905D
  GL_INT_IMAGE_2D_ARRAY_EXT* = 0x0000905E
  GL_INT_IMAGE_CUBE_MAP_ARRAY_EXT* = 0x0000905F
  GL_INT_IMAGE_2D_MULTISAMPLE_EXT* = 0x00009060
  GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY_EXT* = 0x00009061
  GL_UNSIGNED_INT_IMAGE_1D_EXT* = 0x00009062
  GL_UNSIGNED_INT_IMAGE_2D_EXT* = 0x00009063
  GL_UNSIGNED_INT_IMAGE_3D_EXT* = 0x00009064
  GL_UNSIGNED_INT_IMAGE_2D_RECT_EXT* = 0x00009065
  GL_UNSIGNED_INT_IMAGE_CUBE_EXT* = 0x00009066
  GL_UNSIGNED_INT_IMAGE_BUFFER_EXT* = 0x00009067
  GL_UNSIGNED_INT_IMAGE_1D_ARRAY_EXT* = 0x00009068
  GL_UNSIGNED_INT_IMAGE_2D_ARRAY_EXT* = 0x00009069
  GL_UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY_EXT* = 0x0000906A
  GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_EXT* = 0x0000906B
  GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY_EXT* = 0x0000906C
  GL_MAX_IMAGE_SAMPLES_EXT* = 0x0000906D
  GL_IMAGE_BINDING_FORMAT_EXT* = 0x0000906E
  GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT_EXT* = 0x00000001
  GL_ELEMENT_ARRAY_BARRIER_BIT_EXT* = 0x00000002
  GL_UNIFORM_BARRIER_BIT_EXT* = 0x00000004
  GL_TEXTURE_FETCH_BARRIER_BIT_EXT* = 0x00000008
  GL_SHADER_IMAGE_ACCESS_BARRIER_BIT_EXT* = 0x00000020
  GL_COMMAND_BARRIER_BIT_EXT* = 0x00000040
  GL_PIXEL_BUFFER_BARRIER_BIT_EXT* = 0x00000080
  GL_TEXTURE_UPDATE_BARRIER_BIT_EXT* = 0x00000100
  GL_BUFFER_UPDATE_BARRIER_BIT_EXT* = 0x00000200
  GL_FRAMEBUFFER_BARRIER_BIT_EXT* = 0x00000400
  GL_TRANSFORM_FEEDBACK_BARRIER_BIT_EXT* = 0x00000800
  GL_ATOMIC_COUNTER_BARRIER_BIT_EXT* = 0x00001000
  GL_ALL_BARRIER_BITS_EXT* = 0xFFFFFFFF # GL_EXT_vertex_attrib_64bit
                                        # reuse GL_DOUBLE
  GL_DOUBLE_VEC2_EXT* = 0x00008FFC
  GL_DOUBLE_VEC3_EXT* = 0x00008FFD
  GL_DOUBLE_VEC4_EXT* = 0x00008FFE
  GL_DOUBLE_MAT2_EXT* = 0x00008F46
  GL_DOUBLE_MAT3_EXT* = 0x00008F47
  GL_DOUBLE_MAT4_EXT* = 0x00008F48
  GL_DOUBLE_MAT2x3_EXT* = 0x00008F49
  GL_DOUBLE_MAT2x4_EXT* = 0x00008F4A
  GL_DOUBLE_MAT3x2_EXT* = 0x00008F4B
  GL_DOUBLE_MAT3x4_EXT* = 0x00008F4C
  GL_DOUBLE_MAT4x2_EXT* = 0x00008F4D
  GL_DOUBLE_MAT4x3_EXT* = 0x00008F4E # GL_EXT_texture_sRGB_decode
  GL_TEXTURE_SRGB_DECODE_EXT* = 0x00008A48
  GL_DECODE_EXT* = 0x00008A49
  GL_SKIP_DECODE_EXT* = 0x00008A4A # GL_NV_texture_multisample
  GL_TEXTURE_COVERAGE_SAMPLES_NV* = 0x00009045
  GL_TEXTURE_COLOR_SAMPLES_NV* = 0x00009046 # GL_AMD_blend_minmax_factor
  GL_FACTOR_MIN_AMD* = 0x0000901C
  GL_FACTOR_MAX_AMD* = 0x0000901D # GL_AMD_sample_positions
  GL_SUBSAMPLE_DISTANCE_AMD* = 0x0000883F # GL_EXT_x11_sync_object
  GL_SYNC_X11_FENCE_EXT* = 0x000090E1 # GL_EXT_framebuffer_multisample_blit_scaled
  GL_SCALED_RESOLVE_FASTEST_EXT* = 0x000090BA
  GL_SCALED_RESOLVE_NICEST_EXT* = 0x000090BB # GL_FfdMaskSGIX
  GL_TEXTURE_DEFORMATION_BIT_SGIX* = 0x00000001
  GL_GEOMETRY_DEFORMATION_BIT_SGIX* = 0x00000002 # GL_HP_convolution_border_modes
  GL_IGNORE_BORDER_HP* = 0x00008150
  GL_CONSTANT_BORDER_HP* = 0x00008151
  GL_REPLICATE_BORDER_HP* = 0x00008153
  GL_CONVOLUTION_BORDER_COLOR_HP* = 0x00008154 # GL_HP_image_transform
  GL_IMAGE_SCALE_X_HP* = 0x00008155
  GL_IMAGE_SCALE_Y_HP* = 0x00008156
  GL_IMAGE_TRANSLATE_X_HP* = 0x00008157
  GL_IMAGE_TRANSLATE_Y_HP* = 0x00008158
  GL_IMAGE_ROTATE_ANGLE_HP* = 0x00008159
  GL_IMAGE_ROTATE_ORIGIN_X_HP* = 0x0000815A
  GL_IMAGE_ROTATE_ORIGIN_Y_HP* = 0x0000815B
  GL_IMAGE_MAG_FILTER_HP* = 0x0000815C
  GL_IMAGE_MIN_FILTER_HP* = 0x0000815D
  GL_IMAGE_CUBIC_WEIGHT_HP* = 0x0000815E
  GL_CUBIC_HP* = 0x0000815F
  GL_AVERAGE_HP* = 0x00008160
  GL_IMAGE_TRANSFORM_2D_HP* = 0x00008161
  GL_POST_IMAGE_TRANSFORM_COLOR_TABLE_HP* = 0x00008162
  GL_PROXY_POST_IMAGE_TRANSFORM_COLOR_TABLE_HP* = 0x00008163 #
                                                             # GL_HP_occlusion_test
  GL_OCCLUSION_TEST_HP* = 0x00008165
  GL_OCCLUSION_TEST_RESULT_HP* = 0x00008166 # GL_HP_texture_lighting
  GL_TEXTURE_LIGHTING_MODE_HP* = 0x00008167
  GL_TEXTURE_POST_SPECULAR_HP* = 0x00008168
  GL_TEXTURE_PRE_SPECULAR_HP* = 0x00008169 # GL_IBM_cull_vertex
  GL_CULL_VERTEX_IBM* = 103050 # GL_IBM_rasterpos_clip
  GL_RASTER_POSITION_UNCLIPPED_IBM* = 0x00019262 # GL_IBM_texture_mirrored_repeat
  GL_MIRRORED_REPEAT_IBM* = 0x00008370 # GL_IBM_vertex_array_lists
  GL_VERTEX_ARRAY_LIST_IBM* = 103070
  GL_NORMAL_ARRAY_LIST_IBM* = 103071
  GL_COLOR_ARRAY_LIST_IBM* = 103072
  GL_INDEX_ARRAY_LIST_IBM* = 103073
  GL_TEXTURE_COORD_ARRAY_LIST_IBM* = 103074
  GL_EDGE_FLAG_ARRAY_LIST_IBM* = 103075
  GL_FOG_COORDINATE_ARRAY_LIST_IBM* = 103076
  GL_SECONDARY_COLOR_ARRAY_LIST_IBM* = 103077
  GL_VERTEX_ARRAY_LIST_STRIDE_IBM* = 103080
  GL_NORMAL_ARRAY_LIST_STRIDE_IBM* = 103081
  GL_COLOR_ARRAY_LIST_STRIDE_IBM* = 103082
  GL_INDEX_ARRAY_LIST_STRIDE_IBM* = 103083
  GL_TEXTURE_COORD_ARRAY_LIST_STRIDE_IBM* = 103084
  GL_EDGE_FLAG_ARRAY_LIST_STRIDE_IBM* = 103085
  GL_FOG_COORDINATE_ARRAY_LIST_STRIDE_IBM* = 103086
  GL_SECONDARY_COLOR_ARRAY_LIST_STRIDE_IBM* = 103087 # GL_INGR_color_clamp
  GL_RED_MIN_CLAMP_INGR* = 0x00008560
  GL_GREEN_MIN_CLAMP_INGR* = 0x00008561
  GL_BLUE_MIN_CLAMP_INGR* = 0x00008562
  GL_ALPHA_MIN_CLAMP_INGR* = 0x00008563
  GL_RED_MAX_CLAMP_INGR* = 0x00008564
  GL_GREEN_MAX_CLAMP_INGR* = 0x00008565
  GL_BLUE_MAX_CLAMP_INGR* = 0x00008566
  GL_ALPHA_MAX_CLAMP_INGR* = 0x00008567 # GL_INGR_interlace_read
  GL_INTERLACE_READ_INGR* = 0x00008568 # GL_INTEL_parallel_arrays
  GL_PARALLEL_ARRAYS_INTEL* = 0x000083F4
  GL_VERTEX_ARRAY_PARALLEL_POINTERS_INTEL* = 0x000083F5
  GL_NORMAL_ARRAY_PARALLEL_POINTERS_INTEL* = 0x000083F6
  GL_COLOR_ARRAY_PARALLEL_POINTERS_INTEL* = 0x000083F7
  GL_TEXTURE_COORD_ARRAY_PARALLEL_POINTERS_INTEL* = 0x000083F8 #
                                                               # GL_NV_copy_depth_to_color
  GL_DEPTH_STENCIL_TO_RGBA_NV* = 0x0000886E
  GL_DEPTH_STENCIL_TO_BGRA_NV* = 0x0000886F # GL_NV_depth_clamp
  GL_DEPTH_CLAMP_NV* = 0x0000864F # GL_NV_evaluators
  GL_EVAL_2D_NV* = 0x000086C0
  GL_EVAL_TRIANGULAR_2D_NV* = 0x000086C1
  GL_MAP_TESSELLATION_NV* = 0x000086C2
  GL_MAP_ATTRIB_U_ORDER_NV* = 0x000086C3
  GL_MAP_ATTRIB_V_ORDER_NV* = 0x000086C4
  GL_EVAL_FRACTIONAL_TESSELLATION_NV* = 0x000086C5
  GL_EVAL_VERTEX_ATTRIB0_NV* = 0x000086C6
  GL_EVAL_VERTEX_ATTRIB1_NV* = 0x000086C7
  GL_EVAL_VERTEX_ATTRIB2_NV* = 0x000086C8
  GL_EVAL_VERTEX_ATTRIB3_NV* = 0x000086C9
  GL_EVAL_VERTEX_ATTRIB4_NV* = 0x000086CA
  GL_EVAL_VERTEX_ATTRIB5_NV* = 0x000086CB
  GL_EVAL_VERTEX_ATTRIB6_NV* = 0x000086CC
  GL_EVAL_VERTEX_ATTRIB7_NV* = 0x000086CD
  GL_EVAL_VERTEX_ATTRIB8_NV* = 0x000086CE
  GL_EVAL_VERTEX_ATTRIB9_NV* = 0x000086CF
  GL_EVAL_VERTEX_ATTRIB10_NV* = 0x000086D0
  GL_EVAL_VERTEX_ATTRIB11_NV* = 0x000086D1
  GL_EVAL_VERTEX_ATTRIB12_NV* = 0x000086D2
  GL_EVAL_VERTEX_ATTRIB13_NV* = 0x000086D3
  GL_EVAL_VERTEX_ATTRIB14_NV* = 0x000086D4
  GL_EVAL_VERTEX_ATTRIB15_NV* = 0x000086D5
  GL_MAX_MAP_TESSELLATION_NV* = 0x000086D6
  GL_MAX_RATIONAL_EVAL_ORDER_NV* = 0x000086D7 # GL_NV_fence
  GL_ALL_COMPLETED_NV* = 0x000084F2
  GL_FENCE_STATUS_NV* = 0x000084F3
  GL_FENCE_CONDITION_NV* = 0x000084F4 # GL_NV_float_buffer
  GL_FLOAT_R_NV* = 0x00008880
  GL_FLOAT_RG_NV* = 0x00008881
  GL_FLOAT_RGB_NV* = 0x00008882
  GL_FLOAT_RGBA_NV* = 0x00008883
  GL_FLOAT_R16_NV* = 0x00008884
  GL_FLOAT_R32_NV* = 0x00008885
  GL_FLOAT_RG16_NV* = 0x00008886
  GL_FLOAT_RG32_NV* = 0x00008887
  GL_FLOAT_RGB16_NV* = 0x00008888
  GL_FLOAT_RGB32_NV* = 0x00008889
  GL_FLOAT_RGBA16_NV* = 0x0000888A
  GL_FLOAT_RGBA32_NV* = 0x0000888B
  GL_TEXTURE_FLOAT_COMPONENTS_NV* = 0x0000888C
  GL_FLOAT_CLEAR_COLOR_VALUE_NV* = 0x0000888D
  GL_FLOAT_RGBA_MODE_NV* = 0x0000888E # GL_NV_fog_distance
  GL_FOG_DISTANCE_MODE_NV* = 0x0000855A
  GL_EYE_RADIAL_NV* = 0x0000855B
  GL_EYE_PLANE_ABSOLUTE_NV* = 0x0000855C # GL_NV_fragment_program
  GL_MAX_FRAGMENT_PROGRAM_LOCAL_PARAMETERS_NV* = 0x00008868
  GL_FRAGMENT_PROGRAM_NV* = 0x00008870
  GL_MAX_TEXTURE_COORDS_NV* = 0x00008871
  GL_MAX_TEXTURE_IMAGE_UNITS_NV* = 0x00008872
  GL_FRAGMENT_PROGRAM_BINDING_NV* = 0x00008873
  GL_PROGRAM_ERROR_STRING_NV* = 0x00008874 # GL_NV_half_float
  GL_HALF_FLOAT_NV* = 0x0000140B # GL_NV_light_max_exponent
  GL_MAX_SHININESS_NV* = 0x00008504
  GL_MAX_SPOT_EXPONENT_NV* = 0x00008505 # GL_NV_multisample_filter_hint
  GL_MULTISAMPLE_FILTER_HINT_NV* = 0x00008534 # GL_NV_occlusion_query
  GL_PIXEL_COUNTER_BITS_NV* = 0x00008864
  GL_CURRENT_OCCLUSION_QUERY_ID_NV* = 0x00008865
  GL_PIXEL_COUNT_NV* = 0x00008866
  GL_PIXEL_COUNT_AVAILABLE_NV* = 0x00008867 # GL_NV_packed_depth_stencil
  GL_DEPTH_STENCIL_NV* = 0x000084F9
  GL_UNSIGNED_INT_24_8_NV* = 0x000084FA # GL_NV_pixel_data_range
  GL_WRITE_PIXEL_DATA_RANGE_NV* = 0x00008878
  GL_READ_PIXEL_DATA_RANGE_NV* = 0x00008879
  GL_WRITE_PIXEL_DATA_RANGE_LENGTH_NV* = 0x0000887A
  GL_READ_PIXEL_DATA_RANGE_LENGTH_NV* = 0x0000887B
  GL_WRITE_PIXEL_DATA_RANGE_POINTER_NV* = 0x0000887C
  GL_READ_PIXEL_DATA_RANGE_POINTER_NV* = 0x0000887D # GL_NV_point_sprite
  GL_POINT_SPRITE_NV* = 0x00008861
  GL_COORD_REPLACE_NV* = 0x00008862
  GL_POINT_SPRITE_R_MODE_NV* = 0x00008863 # GL_NV_primitive_restart
  cGL_PRIMITIVE_RESTART_NV* = 0x00008558
  cGL_PRIMITIVE_RESTART_INDEX_NV* = 0x00008559 # GL_NV_register_combiners
  GL_REGISTER_COMBINERS_NV* = 0x00008522
  GL_VARIABLE_A_NV* = 0x00008523
  GL_VARIABLE_B_NV* = 0x00008524
  GL_VARIABLE_C_NV* = 0x00008525
  GL_VARIABLE_D_NV* = 0x00008526
  GL_VARIABLE_E_NV* = 0x00008527
  GL_VARIABLE_F_NV* = 0x00008528
  GL_VARIABLE_G_NV* = 0x00008529
  GL_CONSTANT_COLOR0_NV* = 0x0000852A
  GL_CONSTANT_COLOR1_NV* = 0x0000852B
  GL_PRIMARY_COLOR_NV* = 0x0000852C
  GL_SECONDARY_COLOR_NV* = 0x0000852D
  GL_SPARE0_NV* = 0x0000852E
  GL_SPARE1_NV* = 0x0000852F
  GL_DISCARD_NV* = 0x00008530
  GL_E_TIMES_F_NV* = 0x00008531
  GL_SPARE0_PLUS_SECONDARY_COLOR_NV* = 0x00008532
  GL_UNSIGNED_IDENTITY_NV* = 0x00008536
  GL_UNSIGNED_INVERT_NV* = 0x00008537
  GL_EXPAND_NORMAL_NV* = 0x00008538
  GL_EXPAND_NEGATE_NV* = 0x00008539
  GL_HALF_BIAS_NORMAL_NV* = 0x0000853A
  GL_HALF_BIAS_NEGATE_NV* = 0x0000853B
  GL_SIGNED_IDENTITY_NV* = 0x0000853C
  GL_SIGNED_NEGATE_NV* = 0x0000853D
  GL_SCALE_BY_TWO_NV* = 0x0000853E
  GL_SCALE_BY_FOUR_NV* = 0x0000853F
  GL_SCALE_BY_ONE_HALF_NV* = 0x00008540
  GL_BIAS_BY_NEGATIVE_ONE_HALF_NV* = 0x00008541
  cGL_COMBINER_INPUT_NV* = 0x00008542
  GL_COMBINER_MAPPING_NV* = 0x00008543
  GL_COMBINER_COMPONENT_USAGE_NV* = 0x00008544
  GL_COMBINER_AB_DOT_PRODUCT_NV* = 0x00008545
  GL_COMBINER_CD_DOT_PRODUCT_NV* = 0x00008546
  GL_COMBINER_MUX_SUM_NV* = 0x00008547
  GL_COMBINER_SCALE_NV* = 0x00008548
  GL_COMBINER_BIAS_NV* = 0x00008549
  GL_COMBINER_AB_OUTPUT_NV* = 0x0000854A
  GL_COMBINER_CD_OUTPUT_NV* = 0x0000854B
  GL_COMBINER_SUM_OUTPUT_NV* = 0x0000854C
  GL_MAX_GENERAL_COMBINERS_NV* = 0x0000854D
  GL_NUM_GENERAL_COMBINERS_NV* = 0x0000854E
  GL_COLOR_SUM_CLAMP_NV* = 0x0000854F
  GL_COMBINER0_NV* = 0x00008550
  GL_COMBINER1_NV* = 0x00008551
  GL_COMBINER2_NV* = 0x00008552
  GL_COMBINER3_NV* = 0x00008553
  GL_COMBINER4_NV* = 0x00008554
  GL_COMBINER5_NV* = 0x00008555
  GL_COMBINER6_NV* = 0x00008556
  GL_COMBINER7_NV* = 0x00008557 # GL_NV_register_combiners2
  GL_PER_STAGE_CONSTANTS_NV* = 0x00008535 # GL_NV_texgen_emboss
  GL_EMBOSS_LIGHT_NV* = 0x0000855D
  GL_EMBOSS_CONSTANT_NV* = 0x0000855E
  GL_EMBOSS_MAP_NV* = 0x0000855F # GL_NV_texgen_reflection
  GL_NORMAL_MAP_NV* = 0x00008511
  GL_REFLECTION_MAP_NV* = 0x00008512 # GL_NV_texture_env_combine4
  GL_COMBINE4_NV* = 0x00008503
  GL_SOURCE3_RGB_NV* = 0x00008583
  GL_SOURCE3_ALPHA_NV* = 0x0000858B
  GL_OPERAND3_RGB_NV* = 0x00008593
  GL_OPERAND3_ALPHA_NV* = 0x0000859B # GL_NV_texture_expand_normal
  GL_TEXTURE_UNSIGNED_REMAP_MODE_NV* = 0x0000888F # GL_NV_texture_rectangle
  GL_TEXTURE_RECTANGLE_NV* = 0x000084F5
  GL_TEXTURE_BINDING_RECTANGLE_NV* = 0x000084F6
  GL_PROXY_TEXTURE_RECTANGLE_NV* = 0x000084F7
  GL_MAX_RECTANGLE_TEXTURE_SIZE_NV* = 0x000084F8 # GL_NV_texture_shader
  GL_OFFSET_TEXTURE_RECTANGLE_NV* = 0x0000864C
  GL_OFFSET_TEXTURE_RECTANGLE_SCALE_NV* = 0x0000864D
  GL_DOT_PRODUCT_TEXTURE_RECTANGLE_NV* = 0x0000864E
  GL_RGBA_UNSIGNED_DOT_PRODUCT_MAPPING_NV* = 0x000086D9
  GL_UNSIGNED_INT_S8_S8_8_8_NV* = 0x000086DA
  GL_UNSIGNED_INT_8_8_S8_S8_REV_NV* = 0x000086DB
  GL_DSDT_MAG_INTENSITY_NV* = 0x000086DC
  GL_SHADER_CONSISTENT_NV* = 0x000086DD
  GL_TEXTURE_SHADER_NV* = 0x000086DE
  GL_SHADER_OPERATION_NV* = 0x000086DF
  GL_CULL_MODES_NV* = 0x000086E0
  GL_OFFSET_TEXTURE_MATRIX_NV* = 0x000086E1
  GL_OFFSET_TEXTURE_SCALE_NV* = 0x000086E2
  GL_OFFSET_TEXTURE_BIAS_NV* = 0x000086E3
  GL_OFFSET_TEXTURE_2D_MATRIX_NV* = GL_OFFSET_TEXTURE_MATRIX_NV
  GL_OFFSET_TEXTURE_2D_SCALE_NV* = GL_OFFSET_TEXTURE_SCALE_NV
  GL_OFFSET_TEXTURE_2D_BIAS_NV* = GL_OFFSET_TEXTURE_BIAS_NV
  GL_PREVIOUS_TEXTURE_INPUT_NV* = 0x000086E4
  GL_CONST_EYE_NV* = 0x000086E5
  GL_PASS_THROUGH_NV* = 0x000086E6
  GL_CULL_FRAGMENT_NV* = 0x000086E7
  GL_OFFSET_TEXTURE_2D_NV* = 0x000086E8
  GL_DEPENDENT_AR_TEXTURE_2D_NV* = 0x000086E9
  GL_DEPENDENT_GB_TEXTURE_2D_NV* = 0x000086EA
  GL_DOT_PRODUCT_NV* = 0x000086EC
  GL_DOT_PRODUCT_DEPTH_REPLACE_NV* = 0x000086ED
  GL_DOT_PRODUCT_TEXTURE_2D_NV* = 0x000086EE
  GL_DOT_PRODUCT_TEXTURE_CUBE_MAP_NV* = 0x000086F0
  GL_DOT_PRODUCT_DIFFUSE_CUBE_MAP_NV* = 0x000086F1
  GL_DOT_PRODUCT_REFLECT_CUBE_MAP_NV* = 0x000086F2
  GL_DOT_PRODUCT_CONST_EYE_REFLECT_CUBE_MAP_NV* = 0x000086F3
  GL_HILO_NV* = 0x000086F4
  GL_DSDT_NV* = 0x000086F5
  GL_DSDT_MAG_NV* = 0x000086F6
  GL_DSDT_MAG_VIB_NV* = 0x000086F7
  GL_HILO16_NV* = 0x000086F8
  GL_SIGNED_HILO_NV* = 0x000086F9
  GL_SIGNED_HILO16_NV* = 0x000086FA
  GL_SIGNED_RGBA_NV* = 0x000086FB
  GL_SIGNED_RGBA8_NV* = 0x000086FC
  GL_SIGNED_RGB_NV* = 0x000086FE
  GL_SIGNED_RGB8_NV* = 0x000086FF
  GL_SIGNED_LUMINANCE_NV* = 0x00008701
  GL_SIGNED_LUMINANCE8_NV* = 0x00008702
  GL_SIGNED_LUMINANCE_ALPHA_NV* = 0x00008703
  GL_SIGNED_LUMINANCE8_ALPHA8_NV* = 0x00008704
  GL_SIGNED_ALPHA_NV* = 0x00008705
  GL_SIGNED_ALPHA8_NV* = 0x00008706
  GL_SIGNED_INTENSITY_NV* = 0x00008707
  GL_SIGNED_INTENSITY8_NV* = 0x00008708
  GL_DSDT8_NV* = 0x00008709
  GL_DSDT8_MAG8_NV* = 0x0000870A
  GL_DSDT8_MAG8_INTENSITY8_NV* = 0x0000870B
  GL_SIGNED_RGB_UNSIGNED_ALPHA_NV* = 0x0000870C
  GL_SIGNED_RGB8_UNSIGNED_ALPHA8_NV* = 0x0000870D
  GL_HI_SCALE_NV* = 0x0000870E
  GL_LO_SCALE_NV* = 0x0000870F
  GL_DS_SCALE_NV* = 0x00008710
  GL_DT_SCALE_NV* = 0x00008711
  GL_MAGNITUDE_SCALE_NV* = 0x00008712
  GL_VIBRANCE_SCALE_NV* = 0x00008713
  GL_HI_BIAS_NV* = 0x00008714
  GL_LO_BIAS_NV* = 0x00008715
  GL_DS_BIAS_NV* = 0x00008716
  GL_DT_BIAS_NV* = 0x00008717
  GL_MAGNITUDE_BIAS_NV* = 0x00008718
  GL_VIBRANCE_BIAS_NV* = 0x00008719
  GL_TEXTURE_BORDER_VALUES_NV* = 0x0000871A
  GL_TEXTURE_HI_SIZE_NV* = 0x0000871B
  GL_TEXTURE_LO_SIZE_NV* = 0x0000871C
  GL_TEXTURE_DS_SIZE_NV* = 0x0000871D
  GL_TEXTURE_DT_SIZE_NV* = 0x0000871E
  GL_TEXTURE_MAG_SIZE_NV* = 0x0000871F # GL_NV_texture_shader2
  GL_DOT_PRODUCT_TEXTURE_3D_NV* = 0x000086EF # GL_NV_texture_shader3
  GL_OFFSET_PROJECTIVE_TEXTURE_2D_NV* = 0x00008850
  GL_OFFSET_PROJECTIVE_TEXTURE_2D_SCALE_NV* = 0x00008851
  GL_OFFSET_PROJECTIVE_TEXTURE_RECTANGLE_NV* = 0x00008852
  GL_OFFSET_PROJECTIVE_TEXTURE_RECTANGLE_SCALE_NV* = 0x00008853
  GL_OFFSET_HILO_TEXTURE_2D_NV* = 0x00008854
  GL_OFFSET_HILO_TEXTURE_RECTANGLE_NV* = 0x00008855
  GL_OFFSET_HILO_PROJECTIVE_TEXTURE_2D_NV* = 0x00008856
  GL_OFFSET_HILO_PROJECTIVE_TEXTURE_RECTANGLE_NV* = 0x00008857
  GL_DEPENDENT_HILO_TEXTURE_2D_NV* = 0x00008858
  GL_DEPENDENT_RGB_TEXTURE_3D_NV* = 0x00008859
  GL_DEPENDENT_RGB_TEXTURE_CUBE_MAP_NV* = 0x0000885A
  GL_DOT_PRODUCT_PASS_THROUGH_NV* = 0x0000885B
  GL_DOT_PRODUCT_TEXTURE_1D_NV* = 0x0000885C
  GL_DOT_PRODUCT_AFFINE_DEPTH_REPLACE_NV* = 0x0000885D
  GL_HILO8_NV* = 0x0000885E
  GL_SIGNED_HILO8_NV* = 0x0000885F
  GL_FORCE_BLUE_TO_ONE_NV* = 0x00008860 # GL_NV_vertex_array_range
  cGL_VERTEX_ARRAY_RANGE_NV* = 0x0000851D
  GL_VERTEX_ARRAY_RANGE_LENGTH_NV* = 0x0000851E
  GL_VERTEX_ARRAY_RANGE_VALID_NV* = 0x0000851F
  GL_MAX_VERTEX_ARRAY_RANGE_ELEMENT_NV* = 0x00008520
  GL_VERTEX_ARRAY_RANGE_POINTER_NV* = 0x00008521 # GL_NV_vertex_array_range2
  GL_VERTEX_ARRAY_RANGE_WITHOUT_FLUSH_NV* = 0x00008533 # GL_NV_vertex_program
  GL_VERTEX_PROGRAM_NV* = 0x00008620
  GL_VERTEX_STATE_PROGRAM_NV* = 0x00008621
  GL_ATTRIB_ARRAY_SIZE_NV* = 0x00008623
  GL_ATTRIB_ARRAY_STRIDE_NV* = 0x00008624
  GL_ATTRIB_ARRAYtyp_NV* = 0x00008625
  GL_CURRENT_ATTRIB_NV* = 0x00008626
  GL_PROGRAM_LENGTH_NV* = 0x00008627
  GL_PROGRAM_STRING_NV* = 0x00008628
  GL_MODELVIEW_PROJECTION_NV* = 0x00008629
  GL_IDENTITY_NV* = 0x0000862A
  GL_INVERSE_NV* = 0x0000862B
  GL_TRANSPOSE_NV* = 0x0000862C
  GL_INVERSE_TRANSPOSE_NV* = 0x0000862D
  GL_MAX_TRACK_MATRIX_STACK_DEPTH_NV* = 0x0000862E
  GL_MAX_TRACK_MATRICES_NV* = 0x0000862F
  GL_MATRIX0_NV* = 0x00008630
  GL_MATRIX1_NV* = 0x00008631
  GL_MATRIX2_NV* = 0x00008632
  GL_MATRIX3_NV* = 0x00008633
  GL_MATRIX4_NV* = 0x00008634
  GL_MATRIX5_NV* = 0x00008635
  GL_MATRIX6_NV* = 0x00008636
  GL_MATRIX7_NV* = 0x00008637
  GL_CURRENT_MATRIX_STACK_DEPTH_NV* = 0x00008640
  GL_CURRENT_MATRIX_NV* = 0x00008641
  GL_VERTEX_PROGRAM_POINT_SIZE_NV* = 0x00008642
  GL_VERTEX_PROGRAM_TWO_SIDE_NV* = 0x00008643
  GL_PROGRAM_PARAMETER_NV* = 0x00008644
  GL_ATTRIB_ARRAY_POINTER_NV* = 0x00008645
  GL_PROGRAM_TARGET_NV* = 0x00008646
  GL_PROGRAM_RESIDENT_NV* = 0x00008647
  cGL_TRACK_MATRIX_NV* = 0x00008648
  GL_TRACK_MATRIX_TRANSFORM_NV* = 0x00008649
  GL_VERTEX_PROGRAM_BINDING_NV* = 0x0000864A
  GL_PROGRAM_ERROR_POSITION_NV* = 0x0000864B
  GL_VERTEX_ATTRIB_ARRAY0_NV* = 0x00008650
  GL_VERTEX_ATTRIB_ARRAY1_NV* = 0x00008651
  GL_VERTEX_ATTRIB_ARRAY2_NV* = 0x00008652
  GL_VERTEX_ATTRIB_ARRAY3_NV* = 0x00008653
  GL_VERTEX_ATTRIB_ARRAY4_NV* = 0x00008654
  GL_VERTEX_ATTRIB_ARRAY5_NV* = 0x00008655
  GL_VERTEX_ATTRIB_ARRAY6_NV* = 0x00008656
  GL_VERTEX_ATTRIB_ARRAY7_NV* = 0x00008657
  GL_VERTEX_ATTRIB_ARRAY8_NV* = 0x00008658
  GL_VERTEX_ATTRIB_ARRAY9_NV* = 0x00008659
  GL_VERTEX_ATTRIB_ARRAY10_NV* = 0x0000865A
  GL_VERTEX_ATTRIB_ARRAY11_NV* = 0x0000865B
  GL_VERTEX_ATTRIB_ARRAY12_NV* = 0x0000865C
  GL_VERTEX_ATTRIB_ARRAY13_NV* = 0x0000865D
  GL_VERTEX_ATTRIB_ARRAY14_NV* = 0x0000865E
  GL_VERTEX_ATTRIB_ARRAY15_NV* = 0x0000865F
  GL_MAP1_VERTEX_ATTRIB0_4_NV* = 0x00008660
  GL_MAP1_VERTEX_ATTRIB1_4_NV* = 0x00008661
  GL_MAP1_VERTEX_ATTRIB2_4_NV* = 0x00008662
  GL_MAP1_VERTEX_ATTRIB3_4_NV* = 0x00008663
  GL_MAP1_VERTEX_ATTRIB4_4_NV* = 0x00008664
  GL_MAP1_VERTEX_ATTRIB5_4_NV* = 0x00008665
  GL_MAP1_VERTEX_ATTRIB6_4_NV* = 0x00008666
  GL_MAP1_VERTEX_ATTRIB7_4_NV* = 0x00008667
  GL_MAP1_VERTEX_ATTRIB8_4_NV* = 0x00008668
  GL_MAP1_VERTEX_ATTRIB9_4_NV* = 0x00008669
  GL_MAP1_VERTEX_ATTRIB10_4_NV* = 0x0000866A
  GL_MAP1_VERTEX_ATTRIB11_4_NV* = 0x0000866B
  GL_MAP1_VERTEX_ATTRIB12_4_NV* = 0x0000866C
  GL_MAP1_VERTEX_ATTRIB13_4_NV* = 0x0000866D
  GL_MAP1_VERTEX_ATTRIB14_4_NV* = 0x0000866E
  GL_MAP1_VERTEX_ATTRIB15_4_NV* = 0x0000866F
  GL_MAP2_VERTEX_ATTRIB0_4_NV* = 0x00008670
  GL_MAP2_VERTEX_ATTRIB1_4_NV* = 0x00008671
  GL_MAP2_VERTEX_ATTRIB2_4_NV* = 0x00008672
  GL_MAP2_VERTEX_ATTRIB3_4_NV* = 0x00008673
  GL_MAP2_VERTEX_ATTRIB4_4_NV* = 0x00008674
  GL_MAP2_VERTEX_ATTRIB5_4_NV* = 0x00008675
  GL_MAP2_VERTEX_ATTRIB6_4_NV* = 0x00008676
  GL_MAP2_VERTEX_ATTRIB7_4_NV* = 0x00008677
  GL_MAP2_VERTEX_ATTRIB8_4_NV* = 0x00008678
  GL_MAP2_VERTEX_ATTRIB9_4_NV* = 0x00008679
  GL_MAP2_VERTEX_ATTRIB10_4_NV* = 0x0000867A
  GL_MAP2_VERTEX_ATTRIB11_4_NV* = 0x0000867B
  GL_MAP2_VERTEX_ATTRIB12_4_NV* = 0x0000867C
  GL_MAP2_VERTEX_ATTRIB13_4_NV* = 0x0000867D
  GL_MAP2_VERTEX_ATTRIB14_4_NV* = 0x0000867E
  GL_MAP2_VERTEX_ATTRIB15_4_NV* = 0x0000867F # GL_NV_fragment_program2 and GL_NV_vertex_program2_option
  GL_MAX_PROGRAM_EXEC_INSTRUCTIONS_NV* = 0x000088F4
  GL_MAX_PROGRAM_CALL_DEPTH_NV* = 0x000088F5 # GL_NV_fragment_program2
  GL_MAX_PROGRAM_IF_DEPTH_NV* = 0x000088F6
  GL_MAX_PROGRAM_LOOP_DEPTH_NV* = 0x000088F7
  GL_MAX_PROGRAM_LOOP_COUNT_NV* = 0x000088F8 # GL_NV_vertex_program3
  MAX_VERTEX_TEXTURE_IMAGE_UNITS_ARB* = 0x00008B4C # GL_NV_depth_buffer_float
  GL_FLOAT_32_UNSIGNED_INT_24_8_REV_NV* = 0x00008DAD
  GL_DEPTH_BUFFER_FLOAT_MODE_NV* = 0x00008DAF #
                                              # GL_NV_framebuffer_multisample_coverage
  GL_RENDERBUFFER_COVERAGE_SAMPLES_NV* = 0x00008CAB
  GL_RENDERBUFFER_COLOR_SAMPLES_NV* = 0x00008E10 # GL_NV_geometry_program4
  GL_GEOMETRY_PROGRAM_NV* = 0x00008C26
  GL_MAX_PROGRAM_OUTPUT_VERTICES_NV* = 0x00008C27
  GL_MAX_PROGRAM_TOTAL_OUTPUT_COMPONENTS_NV* = 0x00008C28 # GL_NV_gpu_program4
  GL_PROGRAM_ATTRIB_COMPONENTS_NV* = 0x00008906
  GL_PROGRAM_RESULT_COMPONENTS_NV* = 0x00008907
  GL_MAX_PROGRAM_ATTRIB_COMPONENTS_NV* = 0x00008908
  GL_MAX_PROGRAM_RESULT_COMPONENTS_NV* = 0x00008909
  GL_MAX_PROGRAM_GENERIC_ATTRIBS_NV* = 0x00008DA5
  GL_MAX_PROGRAM_GENERIC_RESULTS_NV* = 0x00008DA6 # GL_NV_parameter_buffer_object
  GL_MAX_PROGRAM_PARAMETER_BUFFER_BINDINGS_NV* = 0x00008DA0
  GL_MAX_PROGRAM_PARAMETER_BUFFER_SIZE_NV* = 0x00008DA1
  GL_VERTEX_PROGRAM_PARAMETER_BUFFER_NV* = 0x00008DA2
  GL_GEOMETRY_PROGRAM_PARAMETER_BUFFER_NV* = 0x00008DA3
  GL_FRAGMENT_PROGRAM_PARAMETER_BUFFER_NV* = 0x00008DA4 # GL_NV_transform_feedback
  GL_TRANSFORM_FEEDBACK_BUFFER_NV* = 0x00008C8E
  GL_TRANSFORM_FEEDBACK_BUFFER_START_NV* = 0x00008C84
  GL_TRANSFORM_FEEDBACK_BUFFER_SIZE_NV* = 0x00008C85
  GL_TRANSFORM_FEEDBACK_RECORD_NV* = 0x00008C86
  GL_TRANSFORM_FEEDBACK_BUFFER_BINDING_NV* = 0x00008C8F
  GL_INTERLEAVED_ATTRIBS_NV* = 0x00008C8C
  GL_SEPARATE_ATTRIBS_NV* = 0x00008C8D
  GL_PRIMITIVES_GENERATED_NV* = 0x00008C87
  GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN_NV* = 0x00008C88
  GL_RASTERIZER_DISCARD_NV* = 0x00008C89
  GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS_NV* = 0x00008C8A
  GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS_NV* = 0x00008C8B
  GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS_NV* = 0x00008C80
  cGL_TRANSFORM_FEEDBACK_ATTRIBS_NV* = 0x00008C7E
  GL_ACTIVE_VARYINGS_NV* = 0x00008C81
  GL_ACTIVE_VARYING_MAX_LENGTH_NV* = 0x00008C82
  cGL_TRANSFORM_FEEDBACK_VARYINGS_NV* = 0x00008C83
  GL_TRANSFORM_FEEDBACK_BUFFER_MODE_NV* = 0x00008C7F
  GL_BACK_PRIMARY_COLOR_NV* = 0x00008C77
  GL_BACK_SECONDARY_COLOR_NV* = 0x00008C78
  GL_TEXTURE_COORD_NV* = 0x00008C79
  GL_CLIP_DISTANCE_NV* = 0x00008C7A
  GL_VERTEX_ID_NV* = 0x00008C7B
  GL_PRIMITIVE_ID_NV* = 0x00008C7C
  GL_GENERIC_ATTRIB_NV* = 0x00008C7D
  GL_LAYER_NV* = 0x00008DAA
  GL_NEXT_BUFFER_NV* = - 2
  GL_SKIP_COMPONENTS4_NV* = - 3
  GL_SKIP_COMPONENTS3_NV* = - 4
  GL_SKIP_COMPONENTS2_NV* = - 5
  GL_SKIP_COMPONENTS1_NV* = - 6 # GL_NV_conditional_render
  GL_QUERY_WAIT_NV* = 0x00008E13
  GL_QUERY_NO_WAIT_NV* = 0x00008E14
  GL_QUERY_BY_REGION_WAIT_NV* = 0x00008E15
  GL_QUERY_BY_REGION_NO_WAIT_NV* = 0x00008E16 # GL_NV_present_video
  GL_FRAME_NV* = 0x00008E26
  GL_FIELDS_NV* = 0x00008E27
  GL_CURRENT_TIME_NV* = 0x00008E28
  GL_NUM_FILL_STREAMS_NV* = 0x00008E29
  GL_PRESENT_TIME_NV* = 0x00008E2A
  GL_PRESENT_DURATION_NV* = 0x00008E2B # GL_NV_explicit_multisample
  GL_SAMPLE_POSITION_NV* = 0x00008E50
  GL_SAMPLE_MASK_NV* = 0x00008E51
  GL_SAMPLE_MASK_VALUE_NV* = 0x00008E52
  GL_TEXTURE_BINDING_RENDERBUFFER_NV* = 0x00008E53
  GL_TEXTURE_RENDERBUFFER_DATA_STORE_BINDING_NV* = 0x00008E54
  GL_TEXTURE_RENDERBUFFER_NV* = 0x00008E55
  GL_SAMPLER_RENDERBUFFER_NV* = 0x00008E56
  GL_INT_SAMPLER_RENDERBUFFER_NV* = 0x00008E57
  GL_UNSIGNED_INT_SAMPLER_RENDERBUFFER_NV* = 0x00008E58
  GL_MAX_SAMPLE_MASK_WORDS_NV* = 0x00008E59 # GL_NV_transform_feedback2
  GL_TRANSFORM_FEEDBACK_NV* = 0x00008E22
  GL_TRANSFORM_FEEDBACK_BUFFER_PAUSED_NV* = 0x00008E23
  GL_TRANSFORM_FEEDBACK_BUFFER_ACTIVE_NV* = 0x00008E24
  GL_TRANSFORM_FEEDBACK_BINDING_NV* = 0x00008E25 # GL_NV_video_capture
  GL_VIDEO_BUFFER_NV* = 0x00009020
  GL_VIDEO_BUFFER_BINDING_NV* = 0x00009021
  GL_FIELD_UPPER_NV* = 0x00009022
  GL_FIELD_LOWER_NV* = 0x00009023
  GL_NUM_VIDEO_CAPTURE_STREAMS_NV* = 0x00009024
  GL_NEXT_VIDEO_CAPTURE_BUFFER_STATUS_NV* = 0x00009025
  GL_VIDEO_CAPTURE_TO_422_SUPPORTED_NV* = 0x00009026
  GL_LAST_VIDEO_CAPTURE_STATUS_NV* = 0x00009027
  GL_VIDEO_BUFFER_PITCH_NV* = 0x00009028
  GL_VIDEO_COLOR_CONVERSION_MATRIX_NV* = 0x00009029
  GL_VIDEO_COLOR_CONVERSION_MAX_NV* = 0x0000902A
  GL_VIDEO_COLOR_CONVERSION_MIN_NV* = 0x0000902B
  GL_VIDEO_COLOR_CONVERSION_OFFSET_NV* = 0x0000902C
  GL_VIDEO_BUFFER_INTERNAL_FORMAT_NV* = 0x0000902D
  GL_PARTIAL_SUCCESS_NV* = 0x0000902E
  GL_SUCCESS_NV* = 0x0000902F
  GL_FAILURE_NV* = 0x00009030
  GL_YCBYCR8_422_NV* = 0x00009031
  GL_YCBAYCR8A_4224_NV* = 0x00009032
  GL_Z6Y10Z6CB10Z6Y10Z6CR10_422_NV* = 0x00009033
  GL_Z6Y10Z6CB10Z6A10Z6Y10Z6CR10Z6A10_4224_NV* = 0x00009034
  GL_Z4Y12Z4CB12Z4Y12Z4CR12_422_NV* = 0x00009035
  GL_Z4Y12Z4CB12Z4A12Z4Y12Z4CR12Z4A12_4224_NV* = 0x00009036
  GL_Z4Y12Z4CB12Z4CR12_444_NV* = 0x00009037
  GL_VIDEO_CAPTURE_FRAME_WIDTH_NV* = 0x00009038
  GL_VIDEO_CAPTURE_FRAME_HEIGHT_NV* = 0x00009039
  GL_VIDEO_CAPTURE_FIELD_UPPER_HEIGHT_NV* = 0x0000903A
  GL_VIDEO_CAPTURE_FIELD_LOWER_HEIGHT_NV* = 0x0000903B
  GL_VIDEO_CAPTURE_SURFACE_ORIGIN_NV* = 0x0000903C # GL_NV_shader_buffer_load
  GL_BUFFER_GPU_ADDRESS_NV* = 0x00008F1D
  GL_GPU_ADDRESS_NV* = 0x00008F34
  GL_MAX_SHADER_BUFFER_ADDRESS_NV* = 0x00008F35 #
                                                # GL_NV_vertex_buffer_unified_memory
  GL_VERTEX_ATTRIB_ARRAY_UNIFIED_NV* = 0x00008F1E
  GL_ELEMENT_ARRAY_UNIFIED_NV* = 0x00008F1F
  GL_VERTEX_ATTRIB_ARRAY_ADDRESS_NV* = 0x00008F20
  GL_VERTEX_ARRAY_ADDRESS_NV* = 0x00008F21
  GL_NORMAL_ARRAY_ADDRESS_NV* = 0x00008F22
  GL_COLOR_ARRAY_ADDRESS_NV* = 0x00008F23
  GL_INDEX_ARRAY_ADDRESS_NV* = 0x00008F24
  GL_TEXTURE_COORD_ARRAY_ADDRESS_NV* = 0x00008F25
  GL_EDGE_FLAG_ARRAY_ADDRESS_NV* = 0x00008F26
  GL_SECONDARY_COLOR_ARRAY_ADDRESS_NV* = 0x00008F27
  GL_FOG_COORD_ARRAY_ADDRESS_NV* = 0x00008F28
  GL_ELEMENT_ARRAY_ADDRESS_NV* = 0x00008F29
  GL_VERTEX_ATTRIB_ARRAY_LENGTH_NV* = 0x00008F2A
  GL_VERTEX_ARRAY_LENGTH_NV* = 0x00008F2B
  GL_NORMAL_ARRAY_LENGTH_NV* = 0x00008F2C
  GL_COLOR_ARRAY_LENGTH_NV* = 0x00008F2D
  GL_INDEX_ARRAY_LENGTH_NV* = 0x00008F2E
  GL_TEXTURE_COORD_ARRAY_LENGTH_NV* = 0x00008F2F
  GL_EDGE_FLAG_ARRAY_LENGTH_NV* = 0x00008F30
  GL_SECONDARY_COLOR_ARRAY_LENGTH_NV* = 0x00008F31
  GL_FOG_COORD_ARRAY_LENGTH_NV* = 0x00008F32
  GL_ELEMENT_ARRAY_LENGTH_NV* = 0x00008F33
  GL_DRAW_INDIRECT_UNIFIED_NV* = 0x00008F40
  GL_DRAW_INDIRECT_ADDRESS_NV* = 0x00008F41
  GL_DRAW_INDIRECT_LENGTH_NV* = 0x00008F42 # GL_NV_gpu_program5
  GL_MAX_GEOMETRY_PROGRAM_INVOCATIONS_NV* = 0x00008E5A
  GL_MIN_FRAGMENT_INTERPOLATION_OFFSET_NV* = 0x00008E5B
  GL_MAX_FRAGMENT_INTERPOLATION_OFFSET_NV* = 0x00008E5C
  GL_FRAGMENT_PROGRAM_INTERPOLATION_OFFSET_BITS_NV* = 0x00008E5D
  GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET_NV* = 0x00008E5E
  GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET_NV* = 0x00008E5F
  GL_MAX_PROGRAM_SUBROUTINE_PARAMETERS_NV* = 0x00008F44
  GL_MAX_PROGRAM_SUBROUTINE_NUM_NV* = 0x00008F45 # GL_NV_gpu_shader5
  GL_INT64_NV* = 0x0000140E
  GL_UNSIGNED_INT64_NV* = 0x0000140F
  GL_INT8_NV* = 0x00008FE0
  GL_INT8_VEC2_NV* = 0x00008FE1
  GL_INT8_VEC3_NV* = 0x00008FE2
  GL_INT8_VEC4_NV* = 0x00008FE3
  GL_INT16_NV* = 0x00008FE4
  GL_INT16_VEC2_NV* = 0x00008FE5
  GL_INT16_VEC3_NV* = 0x00008FE6
  GL_INT16_VEC4_NV* = 0x00008FE7
  GL_INT64_VEC2_NV* = 0x00008FE9
  GL_INT64_VEC3_NV* = 0x00008FEA
  GL_INT64_VEC4_NV* = 0x00008FEB
  GL_UNSIGNED_INT8_NV* = 0x00008FEC
  GL_UNSIGNED_INT8_VEC2_NV* = 0x00008FED
  GL_UNSIGNED_INT8_VEC3_NV* = 0x00008FEE
  GL_UNSIGNED_INT8_VEC4_NV* = 0x00008FEF
  GL_UNSIGNED_INT16_NV* = 0x00008FF0
  GL_UNSIGNED_INT16_VEC2_NV* = 0x00008FF1
  GL_UNSIGNED_INT16_VEC3_NV* = 0x00008FF2
  GL_UNSIGNED_INT16_VEC4_NV* = 0x00008FF3
  GL_UNSIGNED_INT64_VEC2_NV* = 0x00008FF5
  GL_UNSIGNED_INT64_VEC3_NV* = 0x00008FF6
  GL_UNSIGNED_INT64_VEC4_NV* = 0x00008FF7
  GL_FLOAT16_NV* = 0x00008FF8
  GL_FLOAT16_VEC2_NV* = 0x00008FF9
  GL_FLOAT16_VEC3_NV* = 0x00008FFA
  GL_FLOAT16_VEC4_NV* = 0x00008FFB # reuse GL_PATCHES
                                   # GL_NV_shader_buffer_store
  GL_SHADER_GLOBAL_ACCESS_BARRIER_BIT_NV* = 0x00000010 # reuse GL_READ_WRITE
                                                       # reuse GL_WRITE_ONLY
                                                       #
                                                       # GL_NV_tessellation_program5
  GL_MAX_PROGRAM_PATCH_ATTRIBS_NV* = 0x000086D8
  GL_TESS_CONTROL_PROGRAM_NV* = 0x0000891E
  GL_TESS_EVALUATION_PROGRAM_NV* = 0x0000891F
  GL_TESS_CONTROL_PROGRAM_PARAMETER_BUFFER_NV* = 0x00008C74
  GL_TESS_EVALUATION_PROGRAM_PARAMETER_BUFFER_NV* = 0x00008C75 #
                                                               # GL_NV_vertex_attrib_integer_64bit
                                                               # reuse GL_INT64_NV
                                                               # reuse
                                                               # GL_UNSIGNED_INT64_NV
                                                               #
                                                               # GL_NV_multisample_coverage
  GL_COVERAGE_SAMPLES_NV* = 0x000080A9
  GL_COLOR_SAMPLES_NV* = 0x00008E20 # GL_NV_vdpau_interop
  GL_SURFACE_STATE_NV* = 0x000086EB
  GL_SURFACE_REGISTERED_NV* = 0x000086FD
  GL_SURFACE_MAPPED_NV* = 0x00008700
  GL_WRITE_DISCARD_NV* = 0x000088BE # GL_OML_interlace
  GL_INTERLACE_OML* = 0x00008980
  GL_INTERLACE_READ_OML* = 0x00008981 # GL_OML_resample
  GL_PACK_RESAMPLE_OML* = 0x00008984
  GL_UNPACK_RESAMPLE_OML* = 0x00008985
  GL_RESAMPLE_REPLICATE_OML* = 0x00008986
  GL_RESAMPLE_ZERO_FILL_OML* = 0x00008987
  GL_RESAMPLE_AVERAGE_OML* = 0x00008988
  GL_RESAMPLE_DECIMATE_OML* = 0x00008989 # GL_OML_subsample
  GL_FORMAT_SUBSAMPLE_24_24_OML* = 0x00008982
  GL_FORMAT_SUBSAMPLE_244_244_OML* = 0x00008983 # GL_PGI_misc_hints
  GL_PREFER_DOUBLEBUFFER_HINT_PGI* = 0x0001A1F8
  GL_CONSERVE_MEMORY_HINT_PGI* = 0x0001A1FD
  GL_RECLAIM_MEMORY_HINT_PGI* = 0x0001A1FE
  GL_NATIVE_GRAPHICS_HANDLE_PGI* = 0x0001A202
  GL_NATIVE_GRAPHICS_BEGIN_HINT_PGI* = 0x0001A203
  GL_NATIVE_GRAPHICS_END_HINT_PGI* = 0x0001A204
  GL_ALWAYS_FAST_HINT_PGI* = 0x0001A20C
  GL_ALWAYS_SOFT_HINT_PGI* = 0x0001A20D
  GL_ALLOW_DRAW_OBJ_HINT_PGI* = 0x0001A20E
  GL_ALLOW_DRAW_WIN_HINT_PGI* = 0x0001A20F
  GL_ALLOW_DRAW_FRG_HINT_PGI* = 0x0001A210
  GL_ALLOW_DRAW_MEM_HINT_PGI* = 0x0001A211
  GL_STRICT_DEPTHFUNC_HINT_PGI* = 0x0001A216
  GL_STRICT_LIGHTING_HINT_PGI* = 0x0001A217
  GL_STRICT_SCISSOR_HINT_PGI* = 0x0001A218
  GL_FULL_STIPPLE_HINT_PGI* = 0x0001A219
  GL_CLIP_NEAR_HINT_PGI* = 0x0001A220
  GL_CLIP_FAR_HINT_PGI* = 0x0001A221
  GL_WIDE_LINE_HINT_PGI* = 0x0001A222
  GL_BACK_NORMALS_HINT_PGI* = 0x0001A223 # GL_PGI_vertex_hints
  GL_VERTEX_DATA_HINT_PGI* = 0x0001A22A
  GL_VERTEX_CONSISTENT_HINT_PGI* = 0x0001A22B
  GL_MATERIAL_SIDE_HINT_PGI* = 0x0001A22C
  GL_MAX_VERTEX_HINT_PGI* = 0x0001A22D
  GL_COLOR3_BIT_PGI* = 0x00010000
  GL_COLOR4_BIT_PGI* = 0x00020000
  GL_EDGEFLAG_BIT_PGI* = 0x00040000
  GL_INDEX_BIT_PGI* = 0x00080000
  GL_MAT_AMBIENT_BIT_PGI* = 0x00100000
  GL_MAT_AMBIENT_AND_DIFFUSE_BIT_PGI* = 0x00200000
  GL_MAT_DIFFUSE_BIT_PGI* = 0x00400000
  GL_MAT_EMISSION_BIT_PGI* = 0x00800000
  GL_MAT_COLOR_INDEXES_BIT_PGI* = 0x01000000
  GL_MAT_SHININESS_BIT_PGI* = 0x02000000
  GL_MAT_SPECULAR_BIT_PGI* = 0x04000000
  GL_NORMAL_BIT_PGI* = 0x08000000
  GL_TEXCOORD1_BIT_PGI* = 0x10000000
  GL_TEXCOORD2_BIT_PGI* = 0x20000000
  GL_TEXCOORD3_BIT_PGI* = 0x40000000
  GL_TEXCOORD4_BIT_PGI* = 0x80000000
  GL_VERTEX23_BIT_PGI* = 0x00000004
  GL_VERTEX4_BIT_PGI* = 0x00000008 # GL_REND_screen_coordinates
  GL_SCREEN_COORDINATES_REND* = 0x00008490
  GL_INVERTED_SCREEN_W_REND* = 0x00008491 # GL_S3_s3tc
  GL_RGB_S3TC* = 0x000083A0
  GL_RGB4_S3TC* = 0x000083A1
  GL_RGBA_S3TC* = 0x000083A2
  GL_RGBA4_S3TC* = 0x000083A3 # GL_SGIS_detail_texture
  GL_DETAIL_TEXTURE_2D_SGIS* = 0x00008095
  GL_DETAIL_TEXTURE_2D_BINDING_SGIS* = 0x00008096
  GL_LINEAR_DETAIL_SGIS* = 0x00008097
  GL_LINEAR_DETAIL_ALPHA_SGIS* = 0x00008098
  GL_LINEAR_DETAIL_COLOR_SGIS* = 0x00008099
  GL_DETAIL_TEXTURE_LEVEL_SGIS* = 0x0000809A
  GL_DETAIL_TEXTURE_MODE_SGIS* = 0x0000809B
  GL_DETAIL_TEXTURE_FUNC_POINTS_SGIS* = 0x0000809C # GL_SGIS_fog_function
  cGL_FOG_FUNC_SGIS* = 0x0000812A
  GL_FOG_FUNC_POINTS_SGIS* = 0x0000812B
  GL_MAX_FOG_FUNC_POINTS_SGIS* = 0x0000812C # GL_SGIS_generate_mipmap
  GL_GENERATE_MIPMAP_SGIS* = 0x00008191
  GL_GENERATE_MIPMAP_HINT_SGIS* = 0x00008192 # GL_SGIS_multisample
  GL_MULTISAMPLE_SGIS* = 0x0000809D
  GL_SAMPLE_ALPHA_TO_MASK_SGIS* = 0x0000809E
  GL_SAMPLE_ALPHA_TO_ONE_SGIS* = 0x0000809F
  cGL_SAMPLE_MASK_SGIS* = 0x000080A0
  GL_1PASS_SGIS* = 0x000080A1
  GL_2PASS_0_SGIS* = 0x000080A2
  GL_2PASS_1_SGIS* = 0x000080A3
  GL_4PASS_0_SGIS* = 0x000080A4
  GL_4PASS_1_SGIS* = 0x000080A5
  GL_4PASS_2_SGIS* = 0x000080A6
  GL_4PASS_3_SGIS* = 0x000080A7
  GL_SAMPLE_BUFFERS_SGIS* = 0x000080A8
  GL_SAMPLES_SGIS* = 0x000080A9
  GL_SAMPLE_MASK_VALUE_SGIS* = 0x000080AA
  GL_SAMPLE_MASK_INVERT_SGIS* = 0x000080AB
  cGL_SAMPLE_PATTERN_SGIS* = 0x000080AC # GL_SGIS_pixel_texture
  GL_PIXEL_TEXTURE_SGIS* = 0x00008353
  GL_PIXEL_FRAGMENT_RGB_SOURCE_SGIS* = 0x00008354
  GL_PIXEL_FRAGMENT_ALPHA_SOURCE_SGIS* = 0x00008355
  GL_PIXEL_GROUP_COLOR_SGIS* = 0x00008356 # GL_SGIS_point_line_texgen
  GL_EYE_DISTANCE_TO_POINT_SGIS* = 0x000081F0
  GL_OBJECT_DISTANCE_TO_POINT_SGIS* = 0x000081F1
  GL_EYE_DISTANCE_TO_LINE_SGIS* = 0x000081F2
  GL_OBJECT_DISTANCE_TO_LINE_SGIS* = 0x000081F3
  GL_EYE_POINT_SGIS* = 0x000081F4
  GL_OBJECT_POINT_SGIS* = 0x000081F5
  GL_EYE_LINE_SGIS* = 0x000081F6
  GL_OBJECT_LINE_SGIS* = 0x000081F7 # GL_SGIS_point_parameters
  GL_POINT_SIZE_MIN_SGIS* = 0x00008126
  GL_POINT_SIZE_MAX_SGIS* = 0x00008127
  GL_POINT_FADE_THRESHOLD_SIZE_SGIS* = 0x00008128
  GL_DISTANCE_ATTENUATION_SGIS* = 0x00008129 # GL_SGIS_sharpen_texture
  GL_LINEAR_SHARPEN_SGIS* = 0x000080AD
  GL_LINEAR_SHARPEN_ALPHA_SGIS* = 0x000080AE
  GL_LINEAR_SHARPEN_COLOR_SGIS* = 0x000080AF
  GL_SHARPEN_TEXTURE_FUNC_POINTS_SGIS* = 0x000080B0 # GL_SGIS_texture4D
  GL_PACK_SKIP_VOLUMES_SGIS* = 0x00008130
  GL_PACK_IMAGE_DEPTH_SGIS* = 0x00008131
  GL_UNPACK_SKIP_VOLUMES_SGIS* = 0x00008132
  GL_UNPACK_IMAGE_DEPTH_SGIS* = 0x00008133
  GL_TEXTURE_4D_SGIS* = 0x00008134
  GL_PROXY_TEXTURE_4D_SGIS* = 0x00008135
  GL_TEXTURE_4DSIZE_SGIS* = 0x00008136
  GL_TEXTURE_WRAP_Q_SGIS* = 0x00008137
  GL_MAX_4D_TEXTURE_SIZE_SGIS* = 0x00008138
  GL_TEXTURE_4D_BINDING_SGIS* = 0x0000814F # GL_SGIS_texture_color_mask
  GL_TEXTURE_COLOR_WRITEMASK_SGIS* = 0x000081EF # GL_SGIS_texture_edge_clamp
  GL_CLAMP_TO_EDGE_SGIS* = 0x0000812F # GL_SGIS_texture_filter4
  GL_FILTER4_SGIS* = 0x00008146
  GL_TEXTURE_FILTER4_SIZE_SGIS* = 0x00008147 # GL_SGIS_texture_lod
  GL_TEXTURE_MIN_LOD_SGIS* = 0x0000813A
  GL_TEXTURE_MAX_LOD_SGIS* = 0x0000813B
  GL_TEXTURE_BASE_LEVEL_SGIS* = 0x0000813C
  GL_TEXTURE_MAX_LEVEL_SGIS* = 0x0000813D # GL_SGIS_texture_select
  GL_DUAL_ALPHA4_SGIS* = 0x00008110
  GL_DUAL_ALPHA8_SGIS* = 0x00008111
  GL_DUAL_ALPHA12_SGIS* = 0x00008112
  GL_DUAL_ALPHA16_SGIS* = 0x00008113
  GL_DUAL_LUMINANCE4_SGIS* = 0x00008114
  GL_DUAL_LUMINANCE8_SGIS* = 0x00008115
  GL_DUAL_LUMINANCE12_SGIS* = 0x00008116
  GL_DUAL_LUMINANCE16_SGIS* = 0x00008117
  GL_DUAL_INTENSITY4_SGIS* = 0x00008118
  GL_DUAL_INTENSITY8_SGIS* = 0x00008119
  GL_DUAL_INTENSITY12_SGIS* = 0x0000811A
  GL_DUAL_INTENSITY16_SGIS* = 0x0000811B
  GL_DUAL_LUMINANCE_ALPHA4_SGIS* = 0x0000811C
  GL_DUAL_LUMINANCE_ALPHA8_SGIS* = 0x0000811D
  GL_QUAD_ALPHA4_SGIS* = 0x0000811E
  GL_QUAD_ALPHA8_SGIS* = 0x0000811F
  GL_QUAD_LUMINANCE4_SGIS* = 0x00008120
  GL_QUAD_LUMINANCE8_SGIS* = 0x00008121
  GL_QUAD_INTENSITY4_SGIS* = 0x00008122
  GL_QUAD_INTENSITY8_SGIS* = 0x00008123
  GL_DUAL_TEXTURE_SELECT_SGIS* = 0x00008124
  GL_QUAD_TEXTURE_SELECT_SGIS* = 0x00008125 # GL_SGIX_async
  cGL_ASYNC_MARKER_SGIX* = 0x00008329 # GL_SGIX_async_histogram
  GL_ASYNC_HISTOGRAM_SGIX* = 0x0000832C
  GL_MAX_ASYNC_HISTOGRAM_SGIX* = 0x0000832D # GL_SGIX_async_pixel
  GL_ASYNC_TEX_IMAGE_SGIX* = 0x0000835C
  GL_ASYNC_DRAW_PIXELS_SGIX* = 0x0000835D
  GL_ASYNC_READ_PIXELS_SGIX* = 0x0000835E
  GL_MAX_ASYNC_TEX_IMAGE_SGIX* = 0x0000835F
  GL_MAX_ASYNC_DRAW_PIXELS_SGIX* = 0x00008360
  GL_MAX_ASYNC_READ_PIXELS_SGIX* = 0x00008361 # GL_SGIX_blend_alpha_minmax
  GL_ALPHA_MIN_SGIX* = 0x00008320
  GL_ALPHA_MAX_SGIX* = 0x00008321 # GL_SGIX_calligraphic_fragment
  GL_CALLIGRAPHIC_FRAGMENT_SGIX* = 0x00008183 # GL_SGIX_clipmap
  GL_LINEAR_CLIPMAP_LINEAR_SGIX* = 0x00008170
  GL_TEXTURE_CLIPMAP_CENTER_SGIX* = 0x00008171
  GL_TEXTURE_CLIPMAP_FRAME_SGIX* = 0x00008172
  GL_TEXTURE_CLIPMAP_OFFSET_SGIX* = 0x00008173
  GL_TEXTURE_CLIPMAP_VIRTUAL_DEPTH_SGIX* = 0x00008174
  GL_TEXTURE_CLIPMAP_LOD_OFFSET_SGIX* = 0x00008175
  GL_TEXTURE_CLIPMAP_DEPTH_SGIX* = 0x00008176
  GL_MAX_CLIPMAP_DEPTH_SGIX* = 0x00008177
  GL_MAX_CLIPMAP_VIRTUAL_DEPTH_SGIX* = 0x00008178
  GL_NEAREST_CLIPMAP_NEAREST_SGIX* = 0x0000844D
  GL_NEAREST_CLIPMAP_LINEAR_SGIX* = 0x0000844E
  GL_LINEAR_CLIPMAP_NEAREST_SGIX* = 0x0000844F # GL_SGIX_convolution_accuracy
  GL_CONVOLUTION_HINT_SGIX* = 0x00008316 # GL_SGIX_depth_texture
  GL_DEPTH_COMPONENT16_SGIX* = 0x000081A5
  GL_DEPTH_COMPONENT24_SGIX* = 0x000081A6
  GL_DEPTH_COMPONENT32_SGIX* = 0x000081A7 # GL_SGIX_fog_offset
  GL_FOG_OFFSET_SGIX* = 0x00008198
  GL_FOG_OFFSET_VALUE_SGIX* = 0x00008199 # GL_SGIX_fog_scale
  GL_FOG_SCALE_SGIX* = 0x000081FC
  GL_FOG_SCALE_VALUE_SGIX* = 0x000081FD # GL_SGIX_fragment_lighting
  GL_FRAGMENT_LIGHTING_SGIX* = 0x00008400
  cGL_FRAGMENT_COLOR_MATERIAL_SGIX* = 0x00008401
  GL_FRAGMENT_COLOR_MATERIAL_FACE_SGIX* = 0x00008402
  GL_FRAGMENT_COLOR_MATERIAL_PARAMETER_SGIX* = 0x00008403
  GL_MAX_FRAGMENT_LIGHTS_SGIX* = 0x00008404
  GL_MAX_ACTIVE_LIGHTS_SGIX* = 0x00008405
  GL_CURRENT_RASTER_NORMAL_SGIX* = 0x00008406
  GL_LIGHT_ENV_MODE_SGIX* = 0x00008407
  GL_FRAGMENT_LIGHT_MODEL_LOCAL_VIEWER_SGIX* = 0x00008408
  GL_FRAGMENT_LIGHT_MODEL_TWO_SIDE_SGIX* = 0x00008409
  GL_FRAGMENT_LIGHT_MODEL_AMBIENT_SGIX* = 0x0000840A
  GL_FRAGMENT_LIGHT_MODEL_NORMAL_INTERPOLATION_SGIX* = 0x0000840B
  GL_FRAGMENT_LIGHT0_SGIX* = 0x0000840C
  GL_FRAGMENT_LIGHT1_SGIX* = 0x0000840D
  GL_FRAGMENT_LIGHT2_SGIX* = 0x0000840E
  GL_FRAGMENT_LIGHT3_SGIX* = 0x0000840F
  GL_FRAGMENT_LIGHT4_SGIX* = 0x00008410
  GL_FRAGMENT_LIGHT5_SGIX* = 0x00008411
  GL_FRAGMENT_LIGHT6_SGIX* = 0x00008412
  GL_FRAGMENT_LIGHT7_SGIX* = 0x00008413 # GL_SGIX_framezoom
  cGL_FRAMEZOOM_SGIX* = 0x0000818B
  GL_FRAMEZOOM_FACTOR_SGIX* = 0x0000818C
  GL_MAX_FRAMEZOOM_FACTOR_SGIX* = 0x0000818D # GL_SGIX_impact_pixel_texture
  GL_PIXEL_TEX_GEN_Q_CEILING_SGIX* = 0x00008184
  GL_PIXEL_TEX_GEN_Q_ROUND_SGIX* = 0x00008185
  GL_PIXEL_TEX_GEN_Q_FLOOR_SGIX* = 0x00008186
  GL_PIXEL_TEX_GEN_ALPHA_REPLACE_SGIX* = 0x00008187
  GL_PIXEL_TEX_GEN_ALPHA_NO_REPLACE_SGIX* = 0x00008188
  GL_PIXEL_TEX_GEN_ALPHA_LS_SGIX* = 0x00008189
  GL_PIXEL_TEX_GEN_ALPHA_MS_SGIX* = 0x0000818A # GL_SGIX_instruments
  GL_INSTRUMENT_BUFFER_POINTER_SGIX* = 0x00008180
  GL_INSTRUMENT_MEASUREMENTS_SGIX* = 0x00008181 # GL_SGIX_interlace
  GL_INTERLACE_SGIX* = 0x00008094 # GL_SGIX_ir_instrument1
  GL_IR_INSTRUMENT1_SGIX* = 0x0000817F # GL_SGIX_list_priority
  GL_LIST_PRIORITY_SGIX* = 0x00008182 # GL_SGIX_pixel_texture
  cGL_PIXEL_TEX_GEN_SGIX* = 0x00008139
  GL_PIXEL_TEX_GEN_MODE_SGIX* = 0x0000832B # GL_SGIX_pixel_tiles
  GL_PIXEL_TILE_BEST_ALIGNMENT_SGIX* = 0x0000813E
  GL_PIXEL_TILE_CACHE_INCREMENT_SGIX* = 0x0000813F
  GL_PIXEL_TILE_WIDTH_SGIX* = 0x00008140
  GL_PIXEL_TILE_HEIGHT_SGIX* = 0x00008141
  GL_PIXEL_TILE_GRID_WIDTH_SGIX* = 0x00008142
  GL_PIXEL_TILE_GRID_HEIGHT_SGIX* = 0x00008143
  GL_PIXEL_TILE_GRID_DEPTH_SGIX* = 0x00008144
  GL_PIXEL_TILE_CACHE_SIZE_SGIX* = 0x00008145 # GL_SGIX_polynomial_ffd
  GL_GEOMETRY_DEFORMATION_SGIX* = 0x00008194
  GL_TEXTURE_DEFORMATION_SGIX* = 0x00008195
  GL_DEFORMATIONS_MASK_SGIX* = 0x00008196
  GL_MAX_DEFORMATION_ORDER_SGIX* = 0x00008197 # GL_SGIX_reference_plane
  cGL_REFERENCE_PLANE_SGIX* = 0x0000817D
  GL_REFERENCE_PLANE_EQUATION_SGIX* = 0x0000817E # GL_SGIX_resample
  GL_PACK_RESAMPLE_SGIX* = 0x0000842C
  GL_UNPACK_RESAMPLE_SGIX* = 0x0000842D
  GL_RESAMPLE_REPLICATE_SGIX* = 0x0000842E
  GL_RESAMPLE_ZERO_FILL_SGIX* = 0x0000842F
  GL_RESAMPLE_DECIMATE_SGIX* = 0x00008430 # GL_SGIX_scalebias_hint
  GL_SCALEBIAS_HINT_SGIX* = 0x00008322 # GL_SGIX_shadow
  GL_TEXTURE_COMPARE_SGIX* = 0x0000819A
  GL_TEXTURE_COMPARE_OPERATOR_SGIX* = 0x0000819B
  GL_TEXTURE_LEQUAL_R_SGIX* = 0x0000819C
  GL_TEXTURE_GEQUAL_R_SGIX* = 0x0000819D # GL_SGIX_shadow_ambient
  GL_SHADOW_AMBIENT_SGIX* = 0x000080BF # GL_SGIX_sprite
  GL_SPRITE_SGIX* = 0x00008148
  GL_SPRITE_MODE_SGIX* = 0x00008149
  GL_SPRITE_AXIS_SGIX* = 0x0000814A
  GL_SPRITE_TRANSLATION_SGIX* = 0x0000814B
  GL_SPRITE_AXIAL_SGIX* = 0x0000814C
  GL_SPRITE_OBJECT_ALIGNED_SGIX* = 0x0000814D
  GL_SPRITE_EYE_ALIGNED_SGIX* = 0x0000814E # GL_SGIX_subsample
  GL_PACK_SUBSAMPLE_RATE_SGIX* = 0x000085A0
  GL_UNPACK_SUBSAMPLE_RATE_SGIX* = 0x000085A1
  GL_PIXEL_SUBSAMPLE_4444_SGIX* = 0x000085A2
  GL_PIXEL_SUBSAMPLE_2424_SGIX* = 0x000085A3
  GL_PIXEL_SUBSAMPLE_4242_SGIX* = 0x000085A4 # GL_SGIX_texture_add_env
  GL_TEXTURE_ENV_BIAS_SGIX* = 0x000080BE # GL_SGIX_texture_coordinate_clamp
  GL_TEXTURE_MAX_CLAMP_S_SGIX* = 0x00008369
  GL_TEXTURE_MAX_CLAMP_T_SGIX* = 0x0000836A
  GL_TEXTURE_MAX_CLAMP_R_SGIX* = 0x0000836B # GL_SGIX_texture_lod_bias
  GL_TEXTURE_LOD_BIAS_S_SGIX* = 0x0000818E
  GL_TEXTURE_LOD_BIAS_T_SGIX* = 0x0000818F
  GL_TEXTURE_LOD_BIAS_R_SGIX* = 0x00008190 # GL_SGIX_texture_multi_buffer
  GL_TEXTURE_MULTI_BUFFER_HINT_SGIX* = 0x0000812E # GL_SGIX_texture_scale_bias
  GL_POST_TEXTURE_FILTER_BIAS_SGIX* = 0x00008179
  GL_POST_TEXTURE_FILTER_SCALE_SGIX* = 0x0000817A
  GL_POST_TEXTURE_FILTER_BIAS_RANGE_SGIX* = 0x0000817B
  GL_POST_TEXTURE_FILTER_SCALE_RANGE_SGIX* = 0x0000817C # GL_SGIX_vertex_preclip
  GL_VERTEX_PRECLIP_SGIX* = 0x000083EE
  GL_VERTEX_PRECLIP_HINT_SGIX* = 0x000083EF # GL_SGIX_ycrcb
  GL_YCRCB_422_SGIX* = 0x000081BB
  GL_YCRCB_444_SGIX* = 0x000081BC # GL_SGIX_ycrcba
  GL_YCRCB_SGIX* = 0x00008318
  GL_YCRCBA_SGIX* = 0x00008319 # GL_SGI_color_matrix
  GL_COLOR_MATRIX_SGI* = 0x000080B1
  GL_COLOR_MATRIX_STACK_DEPTH_SGI* = 0x000080B2
  GL_MAX_COLOR_MATRIX_STACK_DEPTH_SGI* = 0x000080B3
  GL_POST_COLOR_MATRIX_RED_SCALE_SGI* = 0x000080B4
  GL_POST_COLOR_MATRIX_GREEN_SCALE_SGI* = 0x000080B5
  GL_POST_COLOR_MATRIX_BLUE_SCALE_SGI* = 0x000080B6
  GL_POST_COLOR_MATRIX_ALPHA_SCALE_SGI* = 0x000080B7
  GL_POST_COLOR_MATRIX_RED_BIAS_SGI* = 0x000080B8
  GL_POST_COLOR_MATRIX_GREEN_BIAS_SGI* = 0x000080B9
  GL_POST_COLOR_MATRIX_BLUE_BIAS_SGI* = 0x000080BA
  GL_POST_COLOR_MATRIX_ALPHA_BIAS_SGI* = 0x000080BB # GL_SGI_color_table
  cGL_COLOR_TABLE_SGI* = 0x000080D0
  GL_POST_CONVOLUTION_COLOR_TABLE_SGI* = 0x000080D1
  GL_POST_COLOR_MATRIX_COLOR_TABLE_SGI* = 0x000080D2
  GL_PROXY_COLOR_TABLE_SGI* = 0x000080D3
  GL_PROXY_POST_CONVOLUTION_COLOR_TABLE_SGI* = 0x000080D4
  GL_PROXY_POST_COLOR_MATRIX_COLOR_TABLE_SGI* = 0x000080D5
  GL_COLOR_TABLE_SCALE_SGI* = 0x000080D6
  GL_COLOR_TABLE_BIAS_SGI* = 0x000080D7
  GL_COLOR_TABLE_FORMAT_SGI* = 0x000080D8
  GL_COLOR_TABLE_WIDTH_SGI* = 0x000080D9
  GL_COLOR_TABLE_RED_SIZE_SGI* = 0x000080DA
  GL_COLOR_TABLE_GREEN_SIZE_SGI* = 0x000080DB
  GL_COLOR_TABLE_BLUE_SIZE_SGI* = 0x000080DC
  GL_COLOR_TABLE_ALPHA_SIZE_SGI* = 0x000080DD
  GL_COLOR_TABLE_LUMINANCE_SIZE_SGI* = 0x000080DE
  GL_COLOR_TABLE_INTENSITY_SIZE_SGI* = 0x000080DF # GL_SGI_depth_pass_instrument
  GL_DEPTH_PASS_INSTRUMENT_SGIX* = 0x00008310
  GL_DEPTH_PASS_INSTRUMENT_COUNTERS_SGIX* = 0x00008311
  GL_DEPTH_PASS_INSTRUMENT_MAX_SGIX* = 0x00008312 # GL_SGI_texture_color_table
  GL_TEXTURE_COLOR_TABLE_SGI* = 0x000080BC
  GL_PROXY_TEXTURE_COLOR_TABLE_SGI* = 0x000080BD # GL_SUNX_constant_data
  GL_UNPACK_CONSTANT_DATA_SUNX* = 0x000081D5
  GL_TEXTURE_CONSTANT_DATA_SUNX* = 0x000081D6 # GL_SUN_convolution_border_modes
  GL_WRAP_BORDER_SUN* = 0x000081D4 # GL_SUN_global_alpha
  GL_GLOBAL_ALPHA_SUN* = 0x000081D9
  GL_GLOBAL_ALPHA_FACTOR_SUN* = 0x000081DA # GL_SUN_mesh_array
  GL_QUAD_MESH_SUN* = 0x00008614
  GL_TRIANGLE_MESH_SUN* = 0x00008615 # GL_SUN_slice_accum
  GL_SLICE_ACCUM_SUN* = 0x000085CC # GL_SUN_triangle_list
  GL_RESTART_SUN* = 0x00000001
  GL_REPLACE_MIDDLE_SUN* = 0x00000002
  GL_REPLACE_OLDEST_SUN* = 0x00000003
  GL_TRIANGLE_LIST_SUN* = 0x000081D7
  GL_REPLACEMENT_CODE_SUN* = 0x000081D8
  GL_REPLACEMENT_CODE_ARRAY_SUN* = 0x000085C0
  GL_REPLACEMENT_CODE_ARRAYtyp_SUN* = 0x000085C1
  GL_REPLACEMENT_CODE_ARRAY_STRIDE_SUN* = 0x000085C2
  GL_REPLACEMENT_CODE_ARRAY_POINTER_SUN* = 0x000085C3
  GL_R1UI_V3F_SUN* = 0x000085C4
  GL_R1UI_C4UB_V3F_SUN* = 0x000085C5
  GL_R1UI_C3F_V3F_SUN* = 0x000085C6
  GL_R1UI_N3F_V3F_SUN* = 0x000085C7
  GL_R1UI_C4F_N3F_V3F_SUN* = 0x000085C8
  GL_R1UI_T2F_V3F_SUN* = 0x000085C9
  GL_R1UI_T2F_N3F_V3F_SUN* = 0x000085CA
  GL_R1UI_T2F_C4F_N3F_V3F_SUN* = 0x000085CB # GL_WIN_phong_shading
  GL_PHONG_WIN* = 0x000080EA
  GL_PHONG_HINT_WIN* = 0x000080EB # GL_WIN_specular_fog
  GL_FOG_SPECULAR_TEXTURE_WIN* = 0x000080EC # GL_ARB_vertex_shader
  GL_VERTEX_SHADER_ARB* = 0x00008B31
  GL_MAX_VERTEX_UNIFORM_COMPONENTS_ARB* = 0x00008B4A
  GL_MAX_VARYING_FLOATS_ARB* = 0x00008B4B
  GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS_ARB* = 0x00008B4C
  GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS_ARB* = 0x00008B4D
  GL_OBJECT_ACTIVE_ATTRIBUTES_ARB* = 0x00008B89
  GL_OBJECT_ACTIVE_ATTRIBUTE_MAX_LENGTH_ARB* = 0x00008B8A # GL_ARB_fragment_shader
  GL_FRAGMENT_SHADER_ARB* = 0x00008B30
  GL_MAX_FRAGMENT_UNIFORM_COMPONENTS_ARB* = 0x00008B49 # 1.4
  GL_FRAGMENT_SHADER_DERIVATIVE_HINT_ARB* = 0x00008B8B # 1.4
                                                       # GL_ARB_occlusion_query
  GL_SAMPLES_PASSED_ARB* = 0x00008914
  GL_QUERY_COUNTER_BITS_ARB* = 0x00008864
  GL_CURRENT_QUERY_ARB* = 0x00008865
  GL_QUERY_RESULT_ARB* = 0x00008866
  GL_QUERY_RESULT_AVAILABLE_ARB* = 0x00008867 # GL_ARB_point_sprite
  GL_POINT_SPRITE_ARB* = 0x00008861
  GL_COORD_REPLACE_ARB* = 0x00008862 # GL_ARB_shading_language_100
  GL_SHADING_LANGUAGE_VERSION_ARB* = 0x00008B8C # 1.4
                                                # GL_ARB_shader_objects
  GL_PROGRAM_OBJECT_ARB* = 0x00008B40
  GL_OBJECTtyp_ARB* = 0x00008B4E
  GL_OBJECT_SUBtypARB* = 0x00008B4F
  GL_OBJECT_DELETE_STATUS_ARB* = 0x00008B80
  GL_OBJECT_COMPILE_STATUS_ARB* = 0x00008B81
  GL_OBJECT_LINK_STATUS_ARB* = 0x00008B82
  GL_OBJECT_VALIDATE_STATUS_ARB* = 0x00008B83
  GL_OBJECT_INFO_LOG_LENGTH_ARB* = 0x00008B84
  GL_OBJECT_ATTACHED_OBJECTS_ARB* = 0x00008B85
  GL_OBJECT_ACTIVE_UNIFORMS_ARB* = 0x00008B86
  GL_OBJECT_ACTIVE_UNIFORM_MAX_LENGTH_ARB* = 0x00008B87
  GL_OBJECT_SHADER_SOURCE_LENGTH_ARB* = 0x00008B88
  GL_SHADER_OBJECT_ARB* = 0x00008B48
  GL_FLOAT_VEC2_ARB* = 0x00008B50
  GL_FLOAT_VEC3_ARB* = 0x00008B51
  GL_FLOAT_VEC4_ARB* = 0x00008B52
  GL_INT_VEC2_ARB* = 0x00008B53
  GL_INT_VEC3_ARB* = 0x00008B54
  GL_INT_VEC4_ARB* = 0x00008B55
  GL_BOOL_ARB* = 0x00008B56
  GL_BOOL_VEC2_ARB* = 0x00008B57
  GL_BOOL_VEC3_ARB* = 0x00008B58
  GL_BOOL_VEC4_ARB* = 0x00008B59
  GL_FLOAT_MAT2_ARB* = 0x00008B5A
  GL_FLOAT_MAT3_ARB* = 0x00008B5B
  GL_FLOAT_MAT4_ARB* = 0x00008B5C
  GL_SAMPLER_1D_ARB* = 0x00008B5D
  GL_SAMPLER_2D_ARB* = 0x00008B5E
  GL_SAMPLER_3D_ARB* = 0x00008B5F
  GL_SAMPLER_CUBE_ARB* = 0x00008B60
  GL_SAMPLER_1D_SHADOW_ARB* = 0x00008B61
  GL_SAMPLER_2D_SHADOW_ARB* = 0x00008B62
  GL_SAMPLER_2D_RECT_ARB* = 0x00008B63
  GL_SAMPLER_2D_RECT_SHADOW_ARB* = 0x00008B64 # WGL_3DFX_multisample
  WGL_SAMPLE_BUFFERS_3DFX* = 0x00002060
  WGL_SAMPLES_3DFX* = 0x00002061 # WGL_ARB_buffer_region
  WGL_FRONT_COLOR_BUFFER_BIT_ARB* = 0x00000001
  WGL_BACK_COLOR_BUFFER_BIT_ARB* = 0x00000002
  WGL_DEPTH_BUFFER_BIT_ARB* = 0x00000004
  WGL_STENCIL_BUFFER_BIT_ARB* = 0x00000008 # WGL_ARB_make_current_read
  ERROR_INVALID_PIXELtyp_ARB* = 0x00002043
  ERROR_INCOMPATIBLE_DEVICE_CONTEXTS_ARB* = 0x00002054 # WGL_ARB_multisample
  WGL_SAMPLE_BUFFERS_ARB* = 0x00002041
  WGL_SAMPLES_ARB* = 0x00002042 # WGL_ARB_pbuffer
  WGL_DRAW_TO_PBUFFER_ARB* = 0x0000202D
  WGL_MAX_PBUFFER_PIXELS_ARB* = 0x0000202E
  WGL_MAX_PBUFFER_WIDTH_ARB* = 0x0000202F
  WGL_MAX_PBUFFER_HEIGHT_ARB* = 0x00002030
  WGL_PBUFFER_LARGEST_ARB* = 0x00002033
  WGL_PBUFFER_WIDTH_ARB* = 0x00002034
  WGL_PBUFFER_HEIGHT_ARB* = 0x00002035
  WGL_PBUFFER_LOST_ARB* = 0x00002036 # WGL_ARB_pixel_format
  WGL_NUMBER_PIXEL_FORMATS_ARB* = 0x00002000
  WGL_DRAW_TO_WINDOW_ARB* = 0x00002001
  WGL_DRAW_TO_BITMAP_ARB* = 0x00002002
  WGL_ACCELERATION_ARB* = 0x00002003
  WGL_NEED_PALETTE_ARB* = 0x00002004
  WGL_NEED_SYSTEM_PALETTE_ARB* = 0x00002005
  WGL_SWAP_LAYER_BUFFERS_ARB* = 0x00002006
  WGL_SWAP_METHOD_ARB* = 0x00002007
  WGL_NUMBER_OVERLAYS_ARB* = 0x00002008
  WGL_NUMBER_UNDERLAYS_ARB* = 0x00002009
  WGL_TRANSPARENT_ARB* = 0x0000200A
  WGL_TRANSPARENT_RED_VALUE_ARB* = 0x00002037
  WGL_TRANSPARENT_GREEN_VALUE_ARB* = 0x00002038
  WGL_TRANSPARENT_BLUE_VALUE_ARB* = 0x00002039
  WGL_TRANSPARENT_ALPHA_VALUE_ARB* = 0x0000203A
  WGL_TRANSPARENT_INDEX_VALUE_ARB* = 0x0000203B
  WGL_SHARE_DEPTH_ARB* = 0x0000200C
  WGL_SHARE_STENCIL_ARB* = 0x0000200D
  WGL_SHARE_ACCUM_ARB* = 0x0000200E
  WGL_SUPPORT_GDI_ARB* = 0x0000200F
  WGL_SUPPORT_OPENGL_ARB* = 0x00002010
  WGL_DOUBLE_BUFFER_ARB* = 0x00002011
  WGL_STEREO_ARB* = 0x00002012
  WGL_PIXELtyp_ARB* = 0x00002013
  WGL_COLOR_BITS_ARB* = 0x00002014
  WGL_RED_BITS_ARB* = 0x00002015
  WGL_RED_SHIFT_ARB* = 0x00002016
  WGL_GREEN_BITS_ARB* = 0x00002017
  WGL_GREEN_SHIFT_ARB* = 0x00002018
  WGL_BLUE_BITS_ARB* = 0x00002019
  WGL_BLUE_SHIFT_ARB* = 0x0000201A
  WGL_ALPHA_BITS_ARB* = 0x0000201B
  WGL_ALPHA_SHIFT_ARB* = 0x0000201C
  WGL_ACCUM_BITS_ARB* = 0x0000201D
  WGL_ACCUM_RED_BITS_ARB* = 0x0000201E
  WGL_ACCUM_GREEN_BITS_ARB* = 0x0000201F
  WGL_ACCUM_BLUE_BITS_ARB* = 0x00002020
  WGL_ACCUM_ALPHA_BITS_ARB* = 0x00002021
  WGL_DEPTH_BITS_ARB* = 0x00002022
  WGL_STENCIL_BITS_ARB* = 0x00002023
  WGL_AUX_BUFFERS_ARB* = 0x00002024
  WGL_NO_ACCELERATION_ARB* = 0x00002025
  WGL_GENERIC_ACCELERATION_ARB* = 0x00002026
  WGL_FULL_ACCELERATION_ARB* = 0x00002027
  WGL_SWAP_EXCHANGE_ARB* = 0x00002028
  WGL_SWAP_COPY_ARB* = 0x00002029
  WGL_SWAP_UNDEFINED_ARB* = 0x0000202A
  WGLtyp_RGBA_ARB* = 0x0000202B
  WGLtyp_COLORINDEX_ARB* = 0x0000202C # WGL_ARB_pixel_format_float
  WGL_RGBA_FLOAT_MODE_ARB* = 0x00008820
  WGL_CLAMP_VERTEX_COLOR_ARB* = 0x0000891A
  WGL_CLAMP_FRAGMENT_COLOR_ARB* = 0x0000891B
  WGL_CLAMP_READ_COLOR_ARB* = 0x0000891C
  WGL_FIXED_ONLY_ARB* = 0x0000891D # WGL_ARB_render_texture
  WGL_BIND_TO_TEXTURE_RGB_ARB* = 0x00002070
  WGL_BIND_TO_TEXTURE_RGBA_ARB* = 0x00002071
  WGL_TEXTURE_FORMAT_ARB* = 0x00002072
  WGL_TEXTURE_TARGET_ARB* = 0x00002073
  WGL_MIPMAP_TEXTURE_ARB* = 0x00002074
  WGL_TEXTURE_RGB_ARB* = 0x00002075
  WGL_TEXTURE_RGBA_ARB* = 0x00002076
  WGL_NO_TEXTURE_ARB* = 0x00002077
  WGL_TEXTURE_CUBE_MAP_ARB* = 0x00002078
  WGL_TEXTURE_1D_ARB* = 0x00002079
  WGL_TEXTURE_2D_ARB* = 0x0000207A
  WGL_MIPMAP_LEVEL_ARB* = 0x0000207B
  WGL_CUBE_MAP_FACE_ARB* = 0x0000207C
  WGL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB* = 0x0000207D
  WGL_TEXTURE_CUBE_MAP_NEGATIVE_X_ARB* = 0x0000207E
  WGL_TEXTURE_CUBE_MAP_POSITIVE_Y_ARB* = 0x0000207F
  WGL_TEXTURE_CUBE_MAP_NEGATIVE_Y_ARB* = 0x00002080
  WGL_TEXTURE_CUBE_MAP_POSITIVE_Z_ARB* = 0x00002081
  WGL_TEXTURE_CUBE_MAP_NEGATIVE_Z_ARB* = 0x00002082
  WGL_FRONT_LEFT_ARB* = 0x00002083
  WGL_FRONT_RIGHT_ARB* = 0x00002084
  WGL_BACK_LEFT_ARB* = 0x00002085
  WGL_BACK_RIGHT_ARB* = 0x00002086
  WGL_AUX0_ARB* = 0x00002087
  WGL_AUX1_ARB* = 0x00002088
  WGL_AUX2_ARB* = 0x00002089
  WGL_AUX3_ARB* = 0x0000208A
  WGL_AUX4_ARB* = 0x0000208B
  WGL_AUX5_ARB* = 0x0000208C
  WGL_AUX6_ARB* = 0x0000208D
  WGL_AUX7_ARB* = 0x0000208E
  WGL_AUX8_ARB* = 0x0000208F
  WGL_AUX9_ARB* = 0x00002090  # WGL_ARB_create_context
  WGL_CONTEXT_DEBUG_BIT_ARB* = 0x00000001
  WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB* = 0x00000002
  WGL_CONTEXT_MAJOR_VERSION_ARB* = 0x00002091
  WGL_CONTEXT_MINOR_VERSION_ARB* = 0x00002092
  WGL_CONTEXT_LAYER_PLANE_ARB* = 0x00002093
  WGL_CONTEXT_FLAGS_ARB* = 0x00002094
  ERROR_INVALID_VERSION_ARB* = 0x00002095 # WGL_ARB_create_context_profile
  WGL_CONTEXT_PROFILE_MASK_ARB* = 0x00009126
  WGL_CONTEXT_CORE_PROFILE_BIT_ARB* = 0x00000001
  WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB* = 0x00000002
  ERROR_INVALID_PROFILE_ARB* = 0x00002096 # WGL_ARB_framebuffer_sRGB
  WGL_FRAMEBUFFER_SRGB_CAPABLE_ARB* = 0x000020A9 #
                                                 # WGL_ARB_create_context_robustness
  WGL_CONTEXT_ROBUST_ACCESS_BIT_ARB* = 0x00000004
  WGL_LOSE_CONTEXT_ON_RESET_ARB* = 0x00008252
  WGL_CONTEXT_RESET_NOTIFICATION_STRATEGY_ARB* = 0x00008256
  WGL_NO_RESET_NOTIFICATION_ARB* = 0x00008261 # WGL_ATI_pixel_format_float
  WGLtyp_RGBA_FLOAT_ATI* = 0x000021A0
  GLtyp_RGBA_FLOAT_ATI* = 0x00008820
  GL_COLOR_CLEAR_UNCLAMPED_VALUE_ATI* = 0x00008835 # WGL_AMD_gpu_association
  WGL_GPU_VENDOR_AMD* = 0x00001F00
  WGL_GPU_RENDERER_STRING_AMD* = 0x00001F01
  WGL_GPU_OPENGL_VERSION_STRING_AMD* = 0x00001F02
  WGL_GPU_FASTEST_TARGET_GPUS_AMD* = 0x000021A2
  WGL_GPU_RAM_AMD* = 0x000021A3
  WGL_GPU_CLOCK_AMD* = 0x000021A4
  WGL_GPU_NUM_PIPES_AMD* = 0x000021A5
  WGL_GPU_NUM_SIMD_AMD* = 0x000021A6
  WGL_GPU_NUM_RB_AMD* = 0x000021A7
  WGL_GPU_NUM_SPI_AMD* = 0x000021A8 # WGL_EXT_depth_float
  WGL_DEPTH_FLOAT_EXT* = 0x00002040 # WGL_EXT_make_current_read
  ERROR_INVALID_PIXELtyp_EXT* = 0x00002043 # WGL_EXT_multisample
  WGL_SAMPLE_BUFFERS_EXT* = 0x00002041
  WGL_SAMPLES_EXT* = 0x00002042 # WGL_EXT_pbuffer
  WGL_DRAW_TO_PBUFFER_EXT* = 0x0000202D
  WGL_MAX_PBUFFER_PIXELS_EXT* = 0x0000202E
  WGL_MAX_PBUFFER_WIDTH_EXT* = 0x0000202F
  WGL_MAX_PBUFFER_HEIGHT_EXT* = 0x00002030
  WGL_OPTIMAL_PBUFFER_WIDTH_EXT* = 0x00002031
  WGL_OPTIMAL_PBUFFER_HEIGHT_EXT* = 0x00002032
  WGL_PBUFFER_LARGEST_EXT* = 0x00002033
  WGL_PBUFFER_WIDTH_EXT* = 0x00002034
  WGL_PBUFFER_HEIGHT_EXT* = 0x00002035 # WGL_EXT_pixel_format
  WGL_NUMBER_PIXEL_FORMATS_EXT* = 0x00002000
  WGL_DRAW_TO_WINDOW_EXT* = 0x00002001
  WGL_DRAW_TO_BITMAP_EXT* = 0x00002002
  WGL_ACCELERATION_EXT* = 0x00002003
  WGL_NEED_PALETTE_EXT* = 0x00002004
  WGL_NEED_SYSTEM_PALETTE_EXT* = 0x00002005
  WGL_SWAP_LAYER_BUFFERS_EXT* = 0x00002006
  WGL_SWAP_METHOD_EXT* = 0x00002007
  WGL_NUMBER_OVERLAYS_EXT* = 0x00002008
  WGL_NUMBER_UNDERLAYS_EXT* = 0x00002009
  WGL_TRANSPARENT_EXT* = 0x0000200A
  WGL_TRANSPARENT_VALUE_EXT* = 0x0000200B
  WGL_SHARE_DEPTH_EXT* = 0x0000200C
  WGL_SHARE_STENCIL_EXT* = 0x0000200D
  WGL_SHARE_ACCUM_EXT* = 0x0000200E
  WGL_SUPPORT_GDI_EXT* = 0x0000200F
  WGL_SUPPORT_OPENGL_EXT* = 0x00002010
  WGL_DOUBLE_BUFFER_EXT* = 0x00002011
  WGL_STEREO_EXT* = 0x00002012
  WGL_PIXELtyp_EXT* = 0x00002013
  WGL_COLOR_BITS_EXT* = 0x00002014
  WGL_RED_BITS_EXT* = 0x00002015
  WGL_RED_SHIFT_EXT* = 0x00002016
  WGL_GREEN_BITS_EXT* = 0x00002017
  WGL_GREEN_SHIFT_EXT* = 0x00002018
  WGL_BLUE_BITS_EXT* = 0x00002019
  WGL_BLUE_SHIFT_EXT* = 0x0000201A
  WGL_ALPHA_BITS_EXT* = 0x0000201B
  WGL_ALPHA_SHIFT_EXT* = 0x0000201C
  WGL_ACCUM_BITS_EXT* = 0x0000201D
  WGL_ACCUM_RED_BITS_EXT* = 0x0000201E
  WGL_ACCUM_GREEN_BITS_EXT* = 0x0000201F
  WGL_ACCUM_BLUE_BITS_EXT* = 0x00002020
  WGL_ACCUM_ALPHA_BITS_EXT* = 0x00002021
  WGL_DEPTH_BITS_EXT* = 0x00002022
  WGL_STENCIL_BITS_EXT* = 0x00002023
  WGL_AUX_BUFFERS_EXT* = 0x00002024
  WGL_NO_ACCELERATION_EXT* = 0x00002025
  WGL_GENERIC_ACCELERATION_EXT* = 0x00002026
  WGL_FULL_ACCELERATION_EXT* = 0x00002027
  WGL_SWAP_EXCHANGE_EXT* = 0x00002028
  WGL_SWAP_COPY_EXT* = 0x00002029
  WGL_SWAP_UNDEFINED_EXT* = 0x0000202A
  WGLtyp_RGBA_EXT* = 0x0000202B
  WGLtyp_COLORINDEX_EXT* = 0x0000202C # WGL_I3D_digital_video_control
  WGL_DIGITAL_VIDEO_CURSOR_ALPHA_FRAMEBUFFER_I3D* = 0x00002050
  WGL_DIGITAL_VIDEO_CURSOR_ALPHA_VALUE_I3D* = 0x00002051
  WGL_DIGITAL_VIDEO_CURSOR_INCLUDED_I3D* = 0x00002052
  WGL_DIGITAL_VIDEO_GAMMA_CORRECTED_I3D* = 0x00002053 # WGL_I3D_gamma
  WGL_GAMMA_TABLE_SIZE_I3D* = 0x0000204E
  WGL_GAMMA_EXCLUDE_DESKTOP_I3D* = 0x0000204F # WGL_I3D_genlock
  WGL_GENLOCK_SOURCE_MULTIVIEW_I3D* = 0x00002044
  WGL_GENLOCK_SOURCE_EXTENAL_SYNC_I3D* = 0x00002045
  WGL_GENLOCK_SOURCE_EXTENAL_FIELD_I3D* = 0x00002046
  WGL_GENLOCK_SOURCE_EXTENAL_TTL_I3D* = 0x00002047
  WGL_GENLOCK_SOURCE_DIGITAL_SYNC_I3D* = 0x00002048
  WGL_GENLOCK_SOURCE_DIGITAL_FIELD_I3D* = 0x00002049
  WGL_GENLOCK_SOURCE_EDGE_FALLING_I3D* = 0x0000204A
  WGL_GENLOCK_SOURCE_EDGE_RISING_I3D* = 0x0000204B
  WGL_GENLOCK_SOURCE_EDGE_BOTH_I3D* = 0x0000204C # WGL_I3D_image_buffer
  WGL_IMAGE_BUFFER_MIN_ACCESS_I3D* = 0x00000001
  WGL_IMAGE_BUFFER_LOCK_I3D* = 0x00000002 # WGL_NV_float_buffer
  WGL_FLOAT_COMPONENTS_NV* = 0x000020B0
  WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_R_NV* = 0x000020B1
  WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RG_NV* = 0x000020B2
  WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RGB_NV* = 0x000020B3
  WGL_BIND_TO_TEXTURE_RECTANGLE_FLOAT_RGBA_NV* = 0x000020B4
  WGL_TEXTURE_FLOAT_R_NV* = 0x000020B5
  WGL_TEXTURE_FLOAT_RG_NV* = 0x000020B6
  WGL_TEXTURE_FLOAT_RGB_NV* = 0x000020B7
  WGL_TEXTURE_FLOAT_RGBA_NV* = 0x000020B8 # WGL_NV_render_depth_texture
  WGL_BIND_TO_TEXTURE_DEPTH_NV* = 0x000020A3
  WGL_BIND_TO_TEXTURE_RECTANGLE_DEPTH_NV* = 0x000020A4
  WGL_DEPTH_TEXTURE_FORMAT_NV* = 0x000020A5
  WGL_TEXTURE_DEPTH_COMPONENT_NV* = 0x000020A6
  WGL_DEPTH_COMPONENT_NV* = 0x000020A7 # WGL_NV_render_texture_rectangle
  WGL_BIND_TO_TEXTURE_RECTANGLE_RGB_NV* = 0x000020A0
  WGL_BIND_TO_TEXTURE_RECTANGLE_RGBA_NV* = 0x000020A1
  WGL_TEXTURE_RECTANGLE_NV* = 0x000020A2 # WGL_NV_present_video
  WGL_NUM_VIDEO_SLOTS_NV* = 0x000020F0 # WGL_NV_video_output
  WGL_BIND_TO_VIDEO_RGB_NV* = 0x000020C0
  WGL_BIND_TO_VIDEO_RGBA_NV* = 0x000020C1
  WGL_BIND_TO_VIDEO_RGB_AND_DEPTH_NV* = 0x000020C2
  WGL_VIDEO_OUT_COLOR_NV* = 0x000020C3
  WGL_VIDEO_OUT_ALPHA_NV* = 0x000020C4
  WGL_VIDEO_OUT_DEPTH_NV* = 0x000020C5
  WGL_VIDEO_OUT_COLOR_AND_ALPHA_NV* = 0x000020C6
  WGL_VIDEO_OUT_COLOR_AND_DEPTH_NV* = 0x000020C7
  WGL_VIDEO_OUT_FRAME* = 0x000020C8
  WGL_VIDEO_OUT_FIELD_1* = 0x000020C9
  WGL_VIDEO_OUT_FIELD_2* = 0x000020CA
  WGL_VIDEO_OUT_STACKED_FIELDS_1_2* = 0x000020CB
  WGL_VIDEO_OUT_STACKED_FIELDS_2_1* = 0x000020CC # WGL_NV_gpu_affinity
  WGL_ERROR_INCOMPATIBLE_AFFINITY_MASKS_NV* = 0x000020D0
  WGL_ERROR_MISSING_AFFINITY_MASK_NV* = 0x000020D1 # WGL_NV_video_capture
  WGL_UNIQUE_ID_NV* = 0x000020CE
  WGL_NUM_VIDEO_CAPTURE_SLOTS_NV* = 0x000020CF # WGL_NV_multisample_coverage
  WGL_COVERAGE_SAMPLES_NV* = 0x00002042
  WGL_COLOR_SAMPLES_NV* = 0x000020B9 # WGL_EXT_create_context_es2_profile
  WGL_CONTEXT_ES2_PROFILE_BIT_EXT* = 0x00000004 # WGL_NV_DX_interop
  WGL_ACCESS_READ_ONLY_NV* = 0x00000000
  WGL_ACCESS_READ_WRITE_NV* = 0x00000001
  WGL_ACCESS_WRITE_DISCARD_NV* = 0x00000002 # WIN_draw_range_elements
  GL_MAX_ELEMENTS_VERTICES_WIN* = 0x000080E8
  GL_MAX_ELEMENTS_INDICES_WIN* = 0x000080E9 # GLX 1.1 and later:
  GLX_VENDOR* = 1
  GLX_VERSION* = 2
  GLX_EXTENSIONS* = 3
  GLX_USE_GL* = 1
  GLX_BUFFER_SIZE* = 2
  GLX_LEVEL* = 3
  GLX_RGBA* = 4
  GLX_DOUBLEBUFFER* = 5
  GLX_STEREO* = 6
  GLX_AUX_BUFFERS* = 7
  GLX_RED_SIZE* = 8
  GLX_GREEN_SIZE* = 9
  GLX_BLUE_SIZE* = 10
  GLX_ALPHA_SIZE* = 11
  GLX_DEPTH_SIZE* = 12
  GLX_STENCIL_SIZE* = 13
  GLX_ACCUM_RED_SIZE* = 14
  GLX_ACCUM_GREEN_SIZE* = 15
  GLX_ACCUM_BLUE_SIZE* = 16
  GLX_ACCUM_ALPHA_SIZE* = 17  # GLX_VERSION_1_3
  GLX_WINDOW_BIT* = 0x00000001
  GLX_PIXMAP_BIT* = 0x00000002
  GLX_PBUFFER_BIT* = 0x00000004
  GLX_RGBA_BIT* = 0x00000001
  GLX_COLOR_INDEX_BIT* = 0x00000002
  GLX_PBUFFER_CLOBBER_MASK* = 0x08000000
  GLX_FRONT_LEFT_BUFFER_BIT* = 0x00000001
  GLX_FRONT_RIGHT_BUFFER_BIT* = 0x00000002
  GLX_BACK_LEFT_BUFFER_BIT* = 0x00000004
  GLX_BACK_RIGHT_BUFFER_BIT* = 0x00000008
  GLX_AUX_BUFFERS_BIT* = 0x00000010
  GLX_DEPTH_BUFFER_BIT* = 0x00000020
  GLX_STENCIL_BUFFER_BIT* = 0x00000040
  GLX_ACCUM_BUFFER_BIT* = 0x00000080
  GLX_CONFIG_CAVEAT* = 0x00000020
  GLX_X_VISUALtyp* = 0x00000022
  GLX_TRANSPARENTtyp* = 0x00000023
  GLX_TRANSPARENT_INDEX_VALUE* = 0x00000024
  GLX_TRANSPARENT_RED_VALUE* = 0x00000025
  GLX_TRANSPARENT_GREEN_VALUE* = 0x00000026
  GLX_TRANSPARENT_BLUE_VALUE* = 0x00000027
  GLX_TRANSPARENT_ALPHA_VALUE* = 0x00000028
  GLX_DONT_CARE* = 0xFFFFFFFF
  GLX_NONE* = 0x00008000
  GLX_SLOW_CONFIG* = 0x00008001
  GLX_TRUE_COLOR* = 0x00008002
  GLX_DIRECT_COLOR* = 0x00008003
  GLX_PSEUDO_COLOR* = 0x00008004
  GLX_STATIC_COLOR* = 0x00008005
  GLX_GRAY_SCALE* = 0x00008006
  GLX_STATIC_GRAY* = 0x00008007
  GLX_TRANSPARENT_RGB* = 0x00008008
  GLX_TRANSPARENT_INDEX* = 0x00008009
  GLX_VISUAL_ID* = 0x0000800B
  GLX_SCREEN* = 0x0000800C
  GLX_NON_CONFORMANT_CONFIG* = 0x0000800D
  GLX_DRAWABLEtyp* = 0x00008010
  GLX_RENDERtyp* = 0x00008011
  GLX_X_RENDERABLE* = 0x00008012
  GLX_FBCONFIG_ID* = 0x00008013
  GLX_RGBAtyp* = 0x00008014
  GLX_COLOR_INDEXtyp* = 0x00008015
  GLX_MAX_PBUFFER_WIDTH* = 0x00008016
  GLX_MAX_PBUFFER_HEIGHT* = 0x00008017
  GLX_MAX_PBUFFER_PIXELS* = 0x00008018
  GLX_PRESERVED_CONTENTS* = 0x0000801B
  GLX_LARGEST_PBUFFER* = 0x0000801C
  GLX_WIDTH* = 0x0000801D
  GLX_HEIGHT* = 0x0000801E
  GLX_EVENT_MASK* = 0x0000801F
  GLX_DAMAGED* = 0x00008020
  GLX_SAVED* = 0x00008021
  cGLX_WINDOW* = 0x00008022
  cGLX_PBUFFER* = 0x00008023
  GLX_PBUFFER_HEIGHT* = 0x00008040
  GLX_PBUFFER_WIDTH* = 0x00008041 # GLX_VERSION_1_4
  GLX_SAMPLE_BUFFERS* = 100000
  GLX_SAMPLES* = 100001       # GLX_ARB_multisample
  GLX_SAMPLE_BUFFERS_ARB* = 100000
  GLX_SAMPLES_ARB* = 100001   # GLX_ARB_fbconfig_float
  GLX_RGBA_FLOATtyp_ARB* = 0x000020B9
  GLX_RGBA_FLOAT_BIT_ARB* = 0x00000004 # GLX_ARB_create_context
  GLX_CONTEXT_DEBUG_BIT_ARB* = 0x00000001
  GLX_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB* = 0x00000002
  GLX_CONTEXT_MAJOR_VERSION_ARB* = 0x00002091
  GLX_CONTEXT_MINOR_VERSION_ARB* = 0x00002092
  GLX_CONTEXT_FLAGS_ARB* = 0x00002094 # GLX_ARB_create_context_profile
  GLX_CONTEXT_CORE_PROFILE_BIT_ARB* = 0x00000001
  GLX_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB* = 0x00000002
  GLX_CONTEXT_PROFILE_MASK_ARB* = 0x00009126 # GLX_ARB_vertex_buffer_object
  GLX_CONTEXT_ALLOW_BUFFER_BYTE_ORDER_MISMATCH_ARB* = 0x00002095 #
                                                                 # GLX_ARB_framebuffer_sRGB
  GLX_FRAMEBUFFER_SRGB_CAPABLE_ARB* = 0x000020B2 #
                                                 # GLX_ARB_create_context_robustness
  GLX_CONTEXT_ROBUST_ACCESS_BIT_ARB* = 0x00000004
  GLX_LOSE_CONTEXT_ON_RESET_ARB* = 0x00008252
  GLX_CONTEXT_RESET_NOTIFICATION_STRATEGY_ARB* = 0x00008256
  GLX_NO_RESET_NOTIFICATION_ARB* = 0x00008261 # GLX_EXT_visual_info
  GLX_X_VISUALtyp_EXT* = 0x00000022
  GLX_TRANSPARENTtyp_EXT* = 0x00000023
  GLX_TRANSPARENT_INDEX_VALUE_EXT* = 0x00000024
  GLX_TRANSPARENT_RED_VALUE_EXT* = 0x00000025
  GLX_TRANSPARENT_GREEN_VALUE_EXT* = 0x00000026
  GLX_TRANSPARENT_BLUE_VALUE_EXT* = 0x00000027
  GLX_TRANSPARENT_ALPHA_VALUE_EXT* = 0x00000028
  GLX_NONE_EXT* = 0x00008000
  GLX_TRUE_COLOR_EXT* = 0x00008002
  GLX_DIRECT_COLOR_EXT* = 0x00008003
  GLX_PSEUDO_COLOR_EXT* = 0x00008004
  GLX_STATIC_COLOR_EXT* = 0x00008005
  GLX_GRAY_SCALE_EXT* = 0x00008006
  GLX_STATIC_GRAY_EXT* = 0x00008007
  GLX_TRANSPARENT_RGB_EXT* = 0x00008008
  GLX_TRANSPARENT_INDEX_EXT* = 0x00008009 # GLX_EXT_visual_rating
  GLX_VISUAL_CAVEAT_EXT* = 0x00000020
  GLX_SLOW_VISUAL_EXT* = 0x00008001
  GLX_NON_CONFORMANT_VISUAL_EXT* = 0x0000800D # reuse GLX_NONE_EXT
                                              # GLX_EXT_import_context
  GLX_SHARE_CONTEXT_EXT* = 0x0000800A
  GLX_VISUAL_ID_EXT* = 0x0000800B
  GLX_SCREEN_EXT* = 0x0000800C # GLX_EXT_fbconfig_packed_float
                               #  GLX_RGBA_UNSIGNED_FLOATtyp_EXT = $20B1;
                               #  GLX_RGBA_UNSIGNED_FLOAT_BIT_EXT = $00000008;
                               # GLX_EXT_framebuffer_sRGB
                               #  GLX_FRAMEBUFFER_SRGB_CAPABLE_EXT = $20B2;
                               # GLX_EXT_texture_from_pixmap
  GLX_TEXTURE_1D_BIT_EXT* = 0x00000001
  GLX_TEXTURE_2D_BIT_EXT* = 0x00000002
  GLX_TEXTURE_RECTANGLE_BIT_EXT* = 0x00000004
  GLX_BIND_TO_TEXTURE_RGB_EXT* = 0x000020D0
  GLX_BIND_TO_TEXTURE_RGBA_EXT* = 0x000020D1
  GLX_BIND_TO_MIPMAP_TEXTURE_EXT* = 0x000020D2
  GLX_BIND_TO_TEXTURE_TARGETS_EXT* = 0x000020D3
  GLX_Y_INVERTED_EXT* = 0x000020D4
  GLX_TEXTURE_FORMAT_EXT* = 0x000020D5
  GLX_TEXTURE_TARGET_EXT* = 0x000020D6
  GLX_MIPMAP_TEXTURE_EXT* = 0x000020D7
  GLX_TEXTURE_FORMAT_NONE_EXT* = 0x000020D8
  GLX_TEXTURE_FORMAT_RGB_EXT* = 0x000020D9
  GLX_TEXTURE_FORMAT_RGBA_EXT* = 0x000020DA
  GLX_TEXTURE_1D_EXT* = 0x000020DB
  GLX_TEXTURE_2D_EXT* = 0x000020DC
  GLX_TEXTURE_RECTANGLE_EXT* = 0x000020DD
  GLX_FRONT_LEFT_EXT* = 0x000020DE
  GLX_FRONT_RIGHT_EXT* = 0x000020DF
  GLX_BACK_LEFT_EXT* = 0x000020E0
  GLX_BACK_RIGHT_EXT* = 0x000020E1
  GLX_FRONT_EXT* = GLX_FRONT_LEFT_EXT
  GLX_BACK_EXT* = GLX_BACK_LEFT_EXT
  GLX_AUX0_EXT* = 0x000020E2
  GLX_AUX1_EXT* = 0x000020E3
  GLX_AUX2_EXT* = 0x000020E4
  GLX_AUX3_EXT* = 0x000020E5
  GLX_AUX4_EXT* = 0x000020E6
  GLX_AUX5_EXT* = 0x000020E7
  GLX_AUX6_EXT* = 0x000020E8
  GLX_AUX7_EXT* = 0x000020E9
  GLX_AUX8_EXT* = 0x000020EA
  GLX_AUX9_EXT* = 0x000020EB  # GLX_EXT_swap_control
  GLX_SWAP_INTERVAL_EXT* = 0x000020F1
  GLX_MAX_SWAP_INTERVAL_EXT* = 0x000020F2 # GLX_EXT_create_context_es2_profile
  GLX_CONTEXT_ES2_PROFILE_BIT_EXT* = 0x00000004 # GLU
  GLU_INVALID_ENUM* = 100900
  GLU_INVALID_VALUE* = 100901
  GLU_OUT_OF_MEMORY* = 100902
  GLU_INCOMPATIBLE_GL_VERSION* = 100903
  GLU_VERSION* = 100800
  GLU_EXTENSIONS* = 100801
  GLU_TRUE* = GL_TRUE
  GLU_FALSE* = GL_FALSE
  GLU_SMOOTH* = 100000
  GLU_FLAT* = 100001
  GLU_NONE* = 100002
  GLU_POINT* = 100010
  GLU_LINE* = 100011
  GLU_FILL* = 100012
  GLU_SILHOUETTE* = 100013
  GLU_OUTSIDE* = 100020
  GLU_INSIDE* = 100021
  GLU_TESS_MAX_COORD* = 1.0000000000000005e+150
  GLU_TESS_WINDING_RULE* = 100140
  GLU_TESS_BOUNDARY_ONLY* = 100141
  GLU_TESS_TOLERANCE* = 100142
  GLU_TESS_WINDING_ODD* = 100130
  GLU_TESS_WINDING_NONZERO* = 100131
  GLU_TESS_WINDING_POSITIVE* = 100132
  GLU_TESS_WINDING_NEGATIVE* = 100133
  GLU_TESS_WINDING_ABS_GEQ_TWO* = 100134
  GLU_TESS_BEGIN* = 100100    # TGLUTessBeginProc
  cGLU_TESS_VERTEX* = 100101   # TGLUTessVertexProc
  GLU_TESS_END* = 100102      # TGLUTessEndProc
  GLU_TESS_ERROR* = 100103    # TGLUTessErrorProc
  GLU_TESS_EDGE_FLAG* = 100104 # TGLUTessEdgeFlagProc
  GLU_TESS_COMBINE* = 100105  # TGLUTessCombineProc
  GLU_TESS_BEGIN_DATA* = 100106 # TGLUTessBeginDataProc
  GLU_TESS_VERTEX_DATA* = 100107 # TGLUTessVertexDataProc
  GLU_TESS_END_DATA* = 100108 # TGLUTessEndDataProc
  GLU_TESS_ERROR_DATA* = 100109 # TGLUTessErrorDataProc
  GLU_TESS_EDGE_FLAG_DATA* = 100110 # TGLUTessEdgeFlagDataProc
  GLU_TESS_COMBINE_DATA* = 100111 # TGLUTessCombineDataProc
  GLU_TESS_ERROR1* = 100151
  GLU_TESS_ERROR2* = 100152
  GLU_TESS_ERROR3* = 100153
  GLU_TESS_ERROR4* = 100154
  GLU_TESS_ERROR5* = 100155
  GLU_TESS_ERROR6* = 100156
  GLU_TESS_ERROR7* = 100157
  GLU_TESS_ERROR8* = 100158
  GLU_TESS_MISSING_BEGIN_POLYGON* = GLU_TESS_ERROR1
  GLU_TESS_MISSING_BEGIN_CONTOUR* = GLU_TESS_ERROR2
  GLU_TESS_MISSING_END_POLYGON* = GLU_TESS_ERROR3
  GLU_TESS_MISSING_END_CONTOUR* = GLU_TESS_ERROR4
  GLU_TESS_COORD_TOO_LARGE* = GLU_TESS_ERROR5
  GLU_TESS_NEED_COMBINE_CALLBACK* = GLU_TESS_ERROR6
  GLU_AUTO_LOAD_MATRIX* = 100200
  GLU_CULLING* = 100201
  GLU_SAMPLING_TOLERANCE* = 100203
  GLU_DISPLAY_MODE* = 100204
  GLU_PARAMETRIC_TOLERANCE* = 100202
  GLU_SAMPLING_METHOD* = 100205
  GLU_U_STEP* = 100206
  GLU_V_STEP* = 100207
  GLU_PATH_LENGTH* = 100215
  GLU_PARAMETRIC_ERROR* = 100216
  GLU_DOMAIN_DISTANCE* = 100217
  GLU_MAP1_TRIM_2* = 100210
  GLU_MAP1_TRIM_3* = 100211
  GLU_OUTLINE_POLYGON* = 100240
  GLU_OUTLINE_PATCH* = 100241
  GLU_NURBS_ERROR1* = 100251
  GLU_NURBS_ERROR2* = 100252
  GLU_NURBS_ERROR3* = 100253
  GLU_NURBS_ERROR4* = 100254
  GLU_NURBS_ERROR5* = 100255
  GLU_NURBS_ERROR6* = 100256
  GLU_NURBS_ERROR7* = 100257
  GLU_NURBS_ERROR8* = 100258
  GLU_NURBS_ERROR9* = 100259
  GLU_NURBS_ERROR10* = 100260
  GLU_NURBS_ERROR11* = 100261
  GLU_NURBS_ERROR12* = 100262
  GLU_NURBS_ERROR13* = 100263
  GLU_NURBS_ERROR14* = 100264
  GLU_NURBS_ERROR15* = 100265
  GLU_NURBS_ERROR16* = 100266
  GLU_NURBS_ERROR17* = 100267
  GLU_NURBS_ERROR18* = 100268
  GLU_NURBS_ERROR19* = 100269
  GLU_NURBS_ERROR20* = 100270
  GLU_NURBS_ERROR21* = 100271
  GLU_NURBS_ERROR22* = 100272
  GLU_NURBS_ERROR23* = 100273
  GLU_NURBS_ERROR24* = 100274
  GLU_NURBS_ERROR25* = 100275
  GLU_NURBS_ERROR26* = 100276
  GLU_NURBS_ERROR27* = 100277
  GLU_NURBS_ERROR28* = 100278
  GLU_NURBS_ERROR29* = 100279
  GLU_NURBS_ERROR30* = 100280
  GLU_NURBS_ERROR31* = 100281
  GLU_NURBS_ERROR32* = 100282
  GLU_NURBS_ERROR33* = 100283
  GLU_NURBS_ERROR34* = 100284
  GLU_NURBS_ERROR35* = 100285
  GLU_NURBS_ERROR36* = 100286
  GLU_NURBS_ERROR37* = 100287
  GLU_CW* = 100120
  GLU_CCW* = 100121
  GLU_INTERIOR* = 100122
  GLU_EXTERIOR* = 100123
  GLU_UNKNOWN* = 100124
  GLU_BEGIN* = GLU_TESS_BEGIN
  GLU_VERTEX* = cGLU_TESS_VERTEX
  GLU_END* = GLU_TESS_END
  GLU_ERROR* = GLU_TESS_ERROR
  GLU_EDGE_FLAG* = GLU_TESS_EDGE_FLAG

proc glCullFace*(mode: GLenum){.stdcall, importc, ogl.}
proc glFrontFace*(mode: GLenum){.stdcall, importc, ogl.}
proc glHint*(target: GLenum, mode: GLenum){.stdcall, importc, ogl.}
proc glLineWidth*(width: GLfloat){.stdcall, importc, ogl.}
proc glPointSize*(size: GLfloat){.stdcall, importc, ogl.}
proc glPolygonMode*(face: GLenum, mode: GLenum){.stdcall, importc, ogl.}
proc glScissor*(x: GLint, y: GLint, width: GLsizei, height: GLsizei){.stdcall, importc, ogl.}
proc glTexParameterf*(target: GLenum, pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glTexParameterfv*(target: GLenum, pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glTexParameteri*(target: GLenum, pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glTexParameteriv*(target: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glTexImage1D*(target: GLenum, level: GLint, internalformat: GLint,
                   width: GLsizei, border: GLint, format: GLenum, typ: GLenum,
                   pixels: PGLvoid){.stdcall, importc, ogl.}
proc glTexImage2D*(target: GLenum, level: GLint, internalformat: GLint,
                   width: GLsizei, height: GLsizei, border: GLint,
                   format: GLenum, typ: GLenum, pixels: PGLvoid){.stdcall, importc, ogl.}
proc glDrawBuffer*(mode: GLenum){.stdcall, importc, ogl.}
proc glClear*(mask: GLbitfield){.stdcall, importc, ogl.}
proc glClearColor*(red: GLclampf, green: GLclampf, blue: GLclampf,
                   alpha: GLclampf){.stdcall, importc, ogl.}
proc glClearStencil*(s: GLint){.stdcall, importc, ogl.}
proc glClearDepth*(depth: GLclampd){.stdcall, importc, ogl.}
proc glStencilMask*(mask: GLuint){.stdcall, importc, ogl.}
proc glColorMask*(red: GLboolean, green: GLboolean, blue: GLboolean,
                  alpha: GLboolean){.stdcall, importc, ogl.}
proc glDepthMask*(flag: GLboolean){.stdcall, importc, ogl.}
proc glDisable*(cap: GLenum){.stdcall, importc, ogl.}
proc glEnable*(cap: GLenum){.stdcall, importc, ogl.}
proc glFinish*(){.stdcall, importc, ogl.}
proc glFlush*(){.stdcall, importc, ogl.}
proc glBlendFunc*(sfactor: GLenum, dfactor: GLenum){.stdcall, importc, ogl.}
proc glLogicOp*(opcode: GLenum){.stdcall, importc, ogl.}
proc glStencilFunc*(func: GLenum, theRef: GLint, mask: GLuint){.stdcall, importc, ogl.}
proc glStencilOp*(fail: GLenum, zfail: GLenum, zpass: GLenum){.stdcall, importc, ogl.}
proc glDepthFunc*(func: GLenum){.stdcall, importc, ogl.}
proc glPixelStoref*(pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glPixelStorei*(pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glReadBuffer*(mode: GLenum){.stdcall, importc, ogl.}
proc glReadPixels*(x: GLint, y: GLint, width: GLsizei, height: GLsizei,
                   format: GLenum, typ: GLenum, pixels: PGLvoid){.stdcall, importc, ogl.}
proc glGetBooleanv*(pname: GLenum, params: PGLboolean){.stdcall, importc, ogl.}
proc glGetDoublev*(pname: GLenum, params: PGLdouble){.stdcall, importc, ogl.}
proc glGetError*(): GLenum{.stdcall, importc, ogl.}
proc glGetFloatv*(pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glGetIntegerv*(pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetString*(name: GLenum): cstring{.stdcall, importc, ogl.}
proc glGetTexImage*(target: GLenum, level: GLint, format: GLenum, typ: GLenum,
                    pixels: PGLvoid){.stdcall, importc, ogl.}
proc glGetTexParameteriv*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetTexParameterfv*(target: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetTexLevelParameterfv*(target: GLenum, level: GLint, pname: GLenum,
                               params: PGLfloat){.stdcall, importc, ogl.}
proc glGetTexLevelParameteriv*(target: GLenum, level: GLint, pname: GLenum,
                               params: PGLint){.stdcall, importc, ogl.}
proc glIsEnabled*(cap: GLenum): GLboolean{.stdcall, importc, ogl.}
proc glDepthRange*(zNear: GLclampd, zFar: GLclampd){.stdcall, importc, ogl.}
proc glViewport*(x: GLint, y: GLint, width: GLsizei, height: GLsizei){.stdcall, importc, ogl.}
  # GL_VERSION_1_1
proc glDrawArrays*(mode: GLenum, first: GLint, count: GLsizei){.stdcall, importc, ogl.}
proc glDrawElements*(mode: GLenum, count: GLsizei, typ: GLenum, indices: PGLvoid){.
    stdcall, importc, ogl.}
proc glGetPointerv*(pname: GLenum, params: PGLvoid){.stdcall, importc, ogl.}
proc glPolygonOffset*(factor: GLfloat, units: GLfloat){.stdcall, importc, ogl.}
proc glCopyTexImage1D*(target: GLenum, level: GLint, internalFormat: GLenum,
                       x: GLint, y: GLint, width: GLsizei, border: GLint){.
    stdcall, importc, ogl.}
proc glCopyTexImage2D*(target: GLenum, level: GLint, internalFormat: GLenum,
                       x: GLint, y: GLint, width: GLsizei, height: GLsizei,
                       border: GLint){.stdcall, importc, ogl.}
proc glCopyTexSubImage1D*(target: GLenum, level: GLint, xoffset: GLint,
                          x: GLint, y: GLint, width: GLsizei){.stdcall, importc, ogl.}
proc glCopyTexSubImage2D*(target: GLenum, level: GLint, xoffset: GLint,
                          yoffset: GLint, x: GLint, y: GLint, width: GLsizei,
                          height: GLsizei){.stdcall, importc, ogl.}
proc glTexSubImage1D*(target: GLenum, level: GLint, xoffset: GLint,
                      width: GLsizei, format: GLenum, typ: GLenum,
                      pixels: PGLvoid){.stdcall, importc, ogl.}
proc glTexSubImage2D*(target: GLenum, level: GLint, xoffset: GLint,
                      yoffset: GLint, width: GLsizei, height: GLsizei,
                      format: GLenum, typ: GLenum, pixels: PGLvoid){.stdcall, importc, ogl.}
proc glBindTexture*(target: GLenum, texture: GLuint){.stdcall, importc, ogl.}
proc glDeleteTextures*(n: GLsizei, textures: PGLuint){.stdcall, importc, ogl.}
proc glGenTextures*(n: GLsizei, textures: PGLuint){.stdcall, importc, ogl.}
proc glAccum*(op: GLenum, value: GLfloat){.stdcall, importc, ogl.}
proc glAlphaFunc*(func: GLenum, theRef: GLclampf){.stdcall, importc, ogl.}
proc glAreTexturesResident*(n: GLsizei, textures: PGLuint,
                            residences: PGLboolean): GLboolean{.stdcall, importc, ogl.}
proc glArrayElement*(i: GLint){.stdcall, importc, ogl.}
proc glBegin*(mode: GLenum){.stdcall, importc, ogl.}
proc glBitmap*(width: GLsizei, height: GLsizei, xorig: GLfloat, yorig: GLfloat,
               xmove: GLfloat, ymove: GLfloat, bitmap: PGLubyte){.stdcall, importc, ogl.}
proc glCallList*(list: GLuint){.stdcall, importc, ogl.}
proc glCallLists*(n: GLsizei, typ: GLenum, lists: PGLvoid){.stdcall, importc, ogl.}
proc glClearAccum*(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat){.
    stdcall, importc, ogl.}
proc glClearIndex*(c: GLfloat){.stdcall, importc, ogl.}
proc glClipPlane*(plane: GLenum, equation: PGLdouble){.stdcall, importc, ogl.}
proc glColor3b*(red: GLbyte, green: GLbyte, blue: GLbyte){.stdcall, importc, ogl.}
proc glColor3bv*(v: PGLbyte){.stdcall, importc, ogl.}
proc glColor3bv*(v: TGLVectorb3){.stdcall, importc, ogl.}
proc glColor3d*(red: GLdouble, green: GLdouble, blue: GLdouble){.stdcall, importc, ogl.}
proc glColor3dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glColor3dv*(v: TGLVectord3){.stdcall, importc, ogl.}
proc glColor3f*(red: GLfloat, green: GLfloat, blue: GLfloat){.stdcall, importc, ogl.}
proc glColor3fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glColor3fv*(v: TGLVectorf3){.stdcall, importc, ogl.}
proc glColor3i*(red: GLint, green: GLint, blue: GLint){.stdcall, importc, ogl.}
proc glColor3iv*(v: PGLint){.stdcall, importc, ogl.}
proc glColor3iv*(v: TGLVectori3){.stdcall, importc, ogl.}
proc glColor3s*(red: GLshort, green: GLshort, blue: GLshort){.stdcall, importc, ogl.}
proc glColor3sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glColor3sv*(v: TGLVectors3){.stdcall, importc, ogl.}
proc glColor3ub*(red: GLubyte, green: GLubyte, blue: GLubyte){.stdcall, importc, ogl.}
proc glColor3ubv*(v: PGLubyte){.stdcall, importc, ogl.}
proc glColor3ubv*(v: TGLVectorub3){.stdcall, importc, ogl.}
proc glColor3ui*(red: GLuint, green: GLuint, blue: GLuint){.stdcall, importc, ogl.}
proc glColor3uiv*(v: PGLuint){.stdcall, importc, ogl.}
proc glColor3uiv*(v: TGLVectorui3){.stdcall, importc, ogl.}
proc glColor3us*(red: GLushort, green: GLushort, blue: GLushort){.stdcall, importc, ogl.}
proc glColor3usv*(v: PGLushort){.stdcall, importc, ogl.}
proc glColor3usv*(v: TGLVectorus3){.stdcall, importc, ogl.}
proc glColor4b*(red: GLbyte, green: GLbyte, blue: GLbyte, alpha: GLbyte){.
    stdcall, importc, ogl.}
proc glColor4bv*(v: PGLbyte){.stdcall, importc, ogl.}
proc glColor4bv*(v: TGLVectorb4){.stdcall, importc, ogl.}
proc glColor4d*(red: GLdouble, green: GLdouble, blue: GLdouble, alpha: GLdouble){.
    stdcall, importc, ogl.}
proc glColor4dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glColor4dv*(v: TGLVectord4){.stdcall, importc, ogl.}
proc glColor4f*(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat){.
    stdcall, importc, ogl.}
proc glColor4fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glColor4fv*(v: TGLVectorf4){.stdcall, importc, ogl.}
proc glColor4i*(red: GLint, green: GLint, blue: GLint, alpha: GLint){.stdcall, importc, ogl.}
proc glColor4iv*(v: PGLint){.stdcall, importc, ogl.}
proc glColor4iv*(v: TGLVectori4){.stdcall, importc, ogl.}
proc glColor4s*(red: GLshort, green: GLshort, blue: GLshort, alpha: GLshort){.
    stdcall, importc, ogl.}
proc glColor4sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glColor4sv*(v: TGLVectors4){.stdcall, importc, ogl.}
proc glColor4ub*(red: GLubyte, green: GLubyte, blue: GLubyte, alpha: GLubyte){.
    stdcall, importc, ogl.}
proc glColor4ubv*(v: PGLubyte){.stdcall, importc, ogl.}
proc glColor4ubv*(v: TGLVectorub4){.stdcall, importc, ogl.}
proc glColor4ui*(red: GLuint, green: GLuint, blue: GLuint, alpha: GLuint){.
    stdcall, importc, ogl.}
proc glColor4uiv*(v: PGLuint){.stdcall, importc, ogl.}
proc glColor4uiv*(v: TGLVectorui4){.stdcall, importc, ogl.}
proc glColor4us*(red: GLushort, green: GLushort, blue: GLushort, alpha: GLushort){.
    stdcall, importc, ogl.}
proc glColor4usv*(v: PGLushort){.stdcall, importc, ogl.}
proc glColorMaterial*(face: GLenum, mode: GLenum){.stdcall, importc, ogl.}
proc glColorPointer*(size: GLint, typ: GLenum, stride: GLsizei, pointer: PGLvoid){.
    stdcall, importc, ogl.}
proc glCopyPixels*(x: GLint, y: GLint, width: GLsizei, height: GLsizei,
                   typ: GLenum){.stdcall, importc, ogl.}
proc glDeleteLists*(list: GLuint, range: GLsizei){.stdcall, importc, ogl.}
proc glDisableClientState*(arr: GLenum){.stdcall, importc, ogl.}
proc glDrawPixels*(width: GLsizei, height: GLsizei, format: GLenum, typ: GLenum,
                   pixels: PGLvoid){.stdcall, importc, ogl.}
proc glEdgeFlag*(flag: GLboolean){.stdcall, importc, ogl.}
proc glEdgeFlagPointer*(stride: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glEdgeFlagv*(flag: PGLboolean){.stdcall, importc, ogl.}
proc glEnableClientState*(arr: GLenum){.stdcall, importc, ogl.}
proc glEnd*(){.stdcall, importc, ogl.}
proc glEndList*(){.stdcall, importc, ogl.}
proc glEvalCoord1d*(u: GLdouble){.stdcall, importc, ogl.}
proc glEvalCoord1dv*(u: PGLdouble){.stdcall, importc, ogl.}
proc glEvalCoord1f*(u: GLfloat){.stdcall, importc, ogl.}
proc glEvalCoord1fv*(u: PGLfloat){.stdcall, importc, ogl.}
proc glEvalCoord2d*(u: GLdouble, v: GLdouble){.stdcall, importc, ogl.}
proc glEvalCoord2dv*(u: PGLdouble){.stdcall, importc, ogl.}
proc glEvalCoord2f*(u: GLfloat, v: GLfloat){.stdcall, importc, ogl.}
proc glEvalCoord2fv*(u: PGLfloat){.stdcall, importc, ogl.}
proc glEvalMesh1*(mode: GLenum, i1: GLint, i2: GLint){.stdcall, importc, ogl.}
proc glEvalMesh2*(mode: GLenum, i1: GLint, i2: GLint, j1: GLint, j2: GLint){.
    stdcall, importc, ogl.}
proc glEvalPoint1*(i: GLint){.stdcall, importc, ogl.}
proc glEvalPoint2*(i: GLint, j: GLint){.stdcall, importc, ogl.}
proc glFeedbackBuffer*(size: GLsizei, typ: GLenum, buffer: PGLfloat){.stdcall, importc, ogl.}
proc glFogf*(pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glFogfv*(pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glFogi*(pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glFogiv*(pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glFrustum*(left: GLdouble, right: GLdouble, bottom: GLdouble,
                top: GLdouble, zNear: GLdouble, zFar: GLdouble){.stdcall, importc, ogl.}
proc glGenLists*(range: GLsizei): GLuint{.stdcall, importc, ogl.}
proc glGetClipPlane*(plane: GLenum, equation: PGLdouble){.stdcall, importc, ogl.}
proc glGetLightfv*(light: GLenum, pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glGetLightiv*(light: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetMapdv*(target: GLenum, query: GLenum, v: PGLdouble){.stdcall, importc, ogl.}
proc glGetMapfv*(target: GLenum, query: GLenum, v: PGLfloat){.stdcall, importc, ogl.}
proc glGetMapiv*(target: GLenum, query: GLenum, v: PGLint){.stdcall, importc, ogl.}
proc glGetMaterialfv*(face: GLenum, pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glGetMaterialiv*(face: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetPixelMapfv*(map: GLenum, values: PGLfloat){.stdcall, importc, ogl.}
proc glGetPixelMapuiv*(map: GLenum, values: PGLuint){.stdcall, importc, ogl.}
proc glGetPixelMapusv*(map: GLenum, values: PGLushort){.stdcall, importc, ogl.}
proc glGetPolygonStipple*(mask: PGLubyte){.stdcall, importc, ogl.}
proc glGetTexEnvfv*(target: GLenum, pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glGetTexEnviv*(target: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetTexGendv*(coord: GLenum, pname: GLenum, params: PGLdouble){.stdcall, importc, ogl.}
proc glGetTexGenfv*(coord: GLenum, pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glGetTexGeniv*(coord: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glIndexMask*(mask: GLuint){.stdcall, importc, ogl.}
proc glIndexPointer*(typ: GLenum, stride: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glIndexd*(c: GLdouble){.stdcall, importc, ogl.}
proc glIndexdv*(c: PGLdouble){.stdcall, importc, ogl.}
proc glIndexf*(c: GLfloat){.stdcall, importc, ogl.}
proc glIndexfv*(c: PGLfloat){.stdcall, importc, ogl.}
proc glIndexi*(c: GLint){.stdcall, importc, ogl.}
proc glIndexiv*(c: PGLint){.stdcall, importc, ogl.}
proc glIndexs*(c: GLshort){.stdcall, importc, ogl.}
proc glIndexsv*(c: PGLshort){.stdcall, importc, ogl.}
proc glIndexub*(c: GLubyte){.stdcall, importc, ogl.}
proc glIndexubv*(c: PGLubyte){.stdcall, importc, ogl.}
proc glInitNames*(){.stdcall, importc, ogl.}
proc glInterleavedArrays*(format: GLenum, stride: GLsizei, pointer: PGLvoid){.
    stdcall, importc, ogl.}
proc glIsList*(list: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glIsTexture*(texture: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glLightModelf*(pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glLightModelfv*(pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glLightModeli*(pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glLightModeliv*(pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glLightf*(light: GLenum, pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glLightfv*(light: GLenum, pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glLighti*(light: GLenum, pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glLightiv*(light: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glLineStipple*(factor: GLint, pattern: GLushort){.stdcall, importc, ogl.}
proc glListBase*(base: GLuint){.stdcall, importc, ogl.}
proc glLoadIdentity*(){.stdcall, importc, ogl.}
proc glLoadMatrixd*(m: PGLdouble){.stdcall, importc, ogl.}
proc glLoadMatrixf*(m: PGLfloat){.stdcall, importc, ogl.}
proc glLoadName*(name: GLuint){.stdcall, importc, ogl.}
proc glMap1d*(target: GLenum, u1: GLdouble, u2: GLdouble, stride: GLint,
              order: GLint, points: PGLdouble){.stdcall, importc, ogl.}
proc glMap1f*(target: GLenum, u1: GLfloat, u2: GLfloat, stride: GLint,
              order: GLint, points: PGLfloat){.stdcall, importc, ogl.}
proc glMap2d*(target: GLenum, u1: GLdouble, u2: GLdouble, ustride: GLint,
              uorder: GLint, v1: GLdouble, v2: GLdouble, vstride: GLint,
              vorder: GLint, points: PGLdouble){.stdcall, importc, ogl.}
proc glMap2f*(target: GLenum, u1: GLfloat, u2: GLfloat, ustride: GLint,
              uorder: GLint, v1: GLfloat, v2: GLfloat, vstride: GLint,
              vorder: GLint, points: PGLfloat){.stdcall, importc, ogl.}
proc glMapGrid1d*(un: GLint, u1: GLdouble, u2: GLdouble){.stdcall, importc, ogl.}
proc glMapGrid1f*(un: GLint, u1: GLfloat, u2: GLfloat){.stdcall, importc, ogl.}
proc glMapGrid2d*(un: GLint, u1: GLdouble, u2: GLdouble, vn: GLint,
                  v1: GLdouble, v2: GLdouble){.stdcall, importc, ogl.}
proc glMapGrid2f*(un: GLint, u1: GLfloat, u2: GLfloat, vn: GLint, v1: GLfloat,
                  v2: GLfloat){.stdcall, importc, ogl.}
proc glMaterialf*(face: GLenum, pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glMaterialfv*(face: GLenum, pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glMateriali*(face: GLenum, pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glMaterialiv*(face: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glMatrixMode*(mode: GLenum){.stdcall, importc, ogl.}
proc glMultMatrixd*(m: PGLdouble){.stdcall, importc, ogl.}
proc glMultMatrixf*(m: PGLfloat){.stdcall, importc, ogl.}
proc glNewList*(list: GLuint, mode: GLenum){.stdcall, importc, ogl.}
proc glNormal3b*(nx: GLbyte, ny: GLbyte, nz: GLbyte){.stdcall, importc, ogl.}
proc glNormal3bv*(v: PGLbyte){.stdcall, importc, ogl.}
proc glNormal3d*(nx: GLdouble, ny: GLdouble, nz: GLdouble){.stdcall, importc, ogl.}
proc glNormal3dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glNormal3f*(nx: GLfloat, ny: GLfloat, nz: GLfloat){.stdcall, importc, ogl.}
proc glNormal3fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glNormal3i*(nx: GLint, ny: GLint, nz: GLint){.stdcall, importc, ogl.}
proc glNormal3iv*(v: PGLint){.stdcall, importc, ogl.}
proc glNormal3s*(nx: GLshort, ny: GLshort, nz: GLshort){.stdcall, importc, ogl.}
proc glNormal3sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glNormalPointer*(typ: GLenum, stride: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glOrtho*(left: GLdouble, right: GLdouble, bottom: GLdouble, top: GLdouble,
              zNear: GLdouble, zFar: GLdouble){.stdcall, importc, ogl.}
proc glPassThrough*(token: GLfloat){.stdcall, importc, ogl.}
proc glPixelMapfv*(map: GLenum, mapsize: GLsizei, values: PGLfloat){.stdcall, importc, ogl.}
proc glPixelMapuiv*(map: GLenum, mapsize: GLsizei, values: PGLuint){.stdcall, importc, ogl.}
proc glPixelMapusv*(map: GLenum, mapsize: GLsizei, values: PGLushort){.stdcall, importc, ogl.}
proc glPixelTransferf*(pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glPixelTransferi*(pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glPixelZoom*(xfactor: GLfloat, yfactor: GLfloat){.stdcall, importc, ogl.}
proc glPolygonStipple*(mask: PGLubyte){.stdcall, importc, ogl.}
proc glPopAttrib*(){.stdcall, importc, ogl.}
proc glPopClientAttrib*(){.stdcall, importc, ogl.}
proc glPopMatrix*(){.stdcall, importc, ogl.}
proc glPopName*(){.stdcall, importc, ogl.}
proc glPrioritizeTextures*(n: GLsizei, textures: PGLuint, priorities: PGLclampf){.
    stdcall, importc, ogl.}
proc glPushAttrib*(mask: GLbitfield){.stdcall, importc, ogl.}
proc glPushClientAttrib*(mask: GLbitfield){.stdcall, importc, ogl.}
proc glPushMatrix*(){.stdcall, importc, ogl.}
proc glPushName*(name: GLuint){.stdcall, importc, ogl.}
proc glRasterPos2d*(x: GLdouble, y: GLdouble){.stdcall, importc, ogl.}
proc glRasterPos2dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glRasterPos2f*(x: GLfloat, y: GLfloat){.stdcall, importc, ogl.}
proc glRasterPos2fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glRasterPos2i*(x: GLint, y: GLint){.stdcall, importc, ogl.}
proc glRasterPos2iv*(v: PGLint){.stdcall, importc, ogl.}
proc glRasterPos2s*(x: GLshort, y: GLshort){.stdcall, importc, ogl.}
proc glRasterPos2sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glRasterPos3d*(x: GLdouble, y: GLdouble, z: GLdouble){.stdcall, importc, ogl.}
proc glRasterPos3dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glRasterPos3f*(x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glRasterPos3fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glRasterPos3i*(x: GLint, y: GLint, z: GLint){.stdcall, importc, ogl.}
proc glRasterPos3iv*(v: PGLint){.stdcall, importc, ogl.}
proc glRasterPos3s*(x: GLshort, y: GLshort, z: GLshort){.stdcall, importc, ogl.}
proc glRasterPos3sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glRasterPos4d*(x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble){.stdcall, importc, ogl.}
proc glRasterPos4dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glRasterPos4f*(x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat){.stdcall, importc, ogl.}
proc glRasterPos4fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glRasterPos4i*(x: GLint, y: GLint, z: GLint, w: GLint){.stdcall, importc, ogl.}
proc glRasterPos4iv*(v: PGLint){.stdcall, importc, ogl.}
proc glRasterPos4s*(x: GLshort, y: GLshort, z: GLshort, w: GLshort){.stdcall, importc, ogl.}
proc glRasterPos4sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glRectd*(x1: GLdouble, y1: GLdouble, x2: GLdouble, y2: GLdouble){.stdcall, importc, ogl.}
proc glRectdv*(v1: PGLdouble, v2: PGLdouble){.stdcall, importc, ogl.}
proc glRectf*(x1: GLfloat, y1: GLfloat, x2: GLfloat, y2: GLfloat){.stdcall, importc, ogl.}
proc glRectfv*(v1: PGLfloat, v2: PGLfloat){.stdcall, importc, ogl.}
proc glRecti*(x1: GLint, y1: GLint, x2: GLint, y2: GLint){.stdcall, importc, ogl.}
proc glRectiv*(v1: PGLint, v2: PGLint){.stdcall, importc, ogl.}
proc glRects*(x1: GLshort, y1: GLshort, x2: GLshort, y2: GLshort){.stdcall, importc, ogl.}
proc glRectsv*(v1: PGLshort, v2: PGLshort){.stdcall, importc, ogl.}
proc glRenderMode*(mode: GLenum): GLint{.stdcall, importc, ogl.}
proc glRotated*(angle: GLdouble, x: GLdouble, y: GLdouble, z: GLdouble){.stdcall, importc, ogl.}
proc glRotatef*(angle: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glScaled*(x: GLdouble, y: GLdouble, z: GLdouble){.stdcall, importc, ogl.}
proc glScalef*(x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glSelectBuffer*(size: GLsizei, buffer: PGLuint){.stdcall, importc, ogl.}
proc glShadeModel*(mode: GLenum){.stdcall, importc, ogl.}
proc glTexCoord1d*(s: GLdouble){.stdcall, importc, ogl.}
proc glTexCoord1dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glTexCoord1f*(s: GLfloat){.stdcall, importc, ogl.}
proc glTexCoord1fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glTexCoord1i*(s: GLint){.stdcall, importc, ogl.}
proc glTexCoord1iv*(v: PGLint){.stdcall, importc, ogl.}
proc glTexCoord1s*(s: GLshort){.stdcall, importc, ogl.}
proc glTexCoord1sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glTexCoord2d*(s: GLdouble, t: GLdouble){.stdcall, importc, ogl.}
proc glTexCoord2dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glTexCoord2f*(s: GLfloat, t: GLfloat){.stdcall, importc, ogl.}
proc glTexCoord2fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glTexCoord2i*(s: GLint, t: GLint){.stdcall, importc, ogl.}
proc glTexCoord2iv*(v: PGLint){.stdcall, importc, ogl.}
proc glTexCoord2s*(s: GLshort, t: GLshort){.stdcall, importc, ogl.}
proc glTexCoord2sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glTexCoord3d*(s: GLdouble, t: GLdouble, r: GLdouble){.stdcall, importc, ogl.}
proc glTexCoord3dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glTexCoord3f*(s: GLfloat, t: GLfloat, r: GLfloat){.stdcall, importc, ogl.}
proc glTexCoord3fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glTexCoord3i*(s: GLint, t: GLint, r: GLint){.stdcall, importc, ogl.}
proc glTexCoord3iv*(v: PGLint){.stdcall, importc, ogl.}
proc glTexCoord3s*(s: GLshort, t: GLshort, r: GLshort){.stdcall, importc, ogl.}
proc glTexCoord3sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glTexCoord4d*(s: GLdouble, t: GLdouble, r: GLdouble, q: GLdouble){.stdcall, importc, ogl.}
proc glTexCoord4dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glTexCoord4f*(s: GLfloat, t: GLfloat, r: GLfloat, q: GLfloat){.stdcall, importc, ogl.}
proc glTexCoord4fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glTexCoord4i*(s: GLint, t: GLint, r: GLint, q: GLint){.stdcall, importc, ogl.}
proc glTexCoord4iv*(v: PGLint){.stdcall, importc, ogl.}
proc glTexCoord4s*(s: GLshort, t: GLshort, r: GLshort, q: GLshort){.stdcall, importc, ogl.}
proc glTexCoord4sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glTexCoordPointer*(size: GLint, typ: GLenum, stride: GLsizei,
                        pointer: PGLvoid){.stdcall, importc, ogl.}
proc glTexEnvf*(target: GLenum, pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glTexEnvfv*(target: GLenum, pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glTexEnvi*(target: GLenum, pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glTexEnviv*(target: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glTexGend*(coord: GLenum, pname: GLenum, param: GLdouble){.stdcall, importc, ogl.}
proc glTexGendv*(coord: GLenum, pname: GLenum, params: PGLdouble){.stdcall, importc, ogl.}
proc glTexGenf*(coord: GLenum, pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glTexGenfv*(coord: GLenum, pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glTexGeni*(coord: GLenum, pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glTexGeniv*(coord: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glTranslated*(x: GLdouble, y: GLdouble, z: GLdouble){.stdcall, importc, ogl.}
proc glTranslatef*(x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glVertex2d*(x: GLdouble, y: GLdouble){.stdcall, importc, ogl.}
proc glVertex2dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glVertex2f*(x: GLfloat, y: GLfloat){.stdcall, importc, ogl.}
proc glVertex2fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glVertex2i*(x: GLint, y: GLint){.stdcall, importc, ogl.}
proc glVertex2iv*(v: PGLint){.stdcall, importc, ogl.}
proc glVertex2s*(x: GLshort, y: GLshort){.stdcall, importc, ogl.}
proc glVertex2sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glVertex3d*(x: GLdouble, y: GLdouble, z: GLdouble){.stdcall, importc, ogl.}
proc glVertex3dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glVertex3f*(x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glVertex3fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glVertex3i*(x: GLint, y: GLint, z: GLint){.stdcall, importc, ogl.}
proc glVertex3iv*(v: PGLint){.stdcall, importc, ogl.}
proc glVertex3s*(x: GLshort, y: GLshort, z: GLshort){.stdcall, importc, ogl.}
proc glVertex3sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glVertex4d*(x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble){.stdcall, importc, ogl.}
proc glVertex4dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glVertex4f*(x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat){.stdcall, importc, ogl.}
proc glVertex4fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glVertex4i*(x: GLint, y: GLint, z: GLint, w: GLint){.stdcall, importc, ogl.}
proc glVertex4iv*(v: PGLint){.stdcall, importc, ogl.}
proc glVertex4s*(x: GLshort, y: GLshort, z: GLshort, w: GLshort){.stdcall, importc, ogl.}
proc glVertex4sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glVertexPointer*(size: GLint, typ: GLenum, stride: GLsizei,
                      pointer: PGLvoid){.stdcall, importc, ogl.}
  # GL_VERSION_1_2
proc glBlendColor*(red: GLclampf, green: GLclampf, blue: GLclampf,
                   alpha: GLclampf){.stdcall, importc, ogl.}
proc glBlendEquation*(mode: GLenum){.stdcall, importc, ogl.}
proc glDrawRangeElements*(mode: GLenum, start: GLuint, ending: GLuint,
                          count: GLsizei, typ: GLenum, indices: PGLvoid){.
    stdcall, importc, ogl.}
proc glTexImage3D*(target: GLenum, level: GLint, internalformat: GLint,
                   width: GLsizei, height: GLsizei, depth: GLsizei,
                   border: GLint, format: GLenum, typ: GLenum, pixels: PGLvoid){.
    stdcall, importc, ogl.}
proc glTexSubImage3D*(target: GLenum, level: GLint, xoffset: GLint,
                      yoffset: GLint, zoffset: GLint, width: GLsizei,
                      height: GLsizei, depth: GLsizei, format: GLenum,
                      typ: GLenum, pixels: PGLvoid){.stdcall, importc, ogl.}
proc glCopyTexSubImage3D*(target: GLenum, level: GLint, xoffset: GLint,
                          yoffset: GLint, zoffset: GLint, x: GLint, y: GLint,
                          width: GLsizei, height: GLsizei){.stdcall, importc, ogl.}
proc glColorTable*(target: GLenum, internalformat: GLenum, width: GLsizei,
                   format: GLenum, typ: GLenum, table: PGLvoid){.stdcall, importc, ogl.}
proc glColorTableParameterfv*(target: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glColorTableParameteriv*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glCopyColorTable*(target: GLenum, internalformat: GLenum, x: GLint,
                       y: GLint, width: GLsizei){.stdcall, importc, ogl.}
proc glGetColorTable*(target: GLenum, format: GLenum, typ: GLenum,
                      table: PGLvoid){.stdcall, importc, ogl.}
proc glGetColorTableParameterfv*(target: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetColorTableParameteriv*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glColorSubTable*(target: GLenum, start: GLsizei, count: GLsizei,
                      format: GLenum, typ: GLenum, data: PGLvoid){.stdcall, importc, ogl.}
proc glCopyColorSubTable*(target: GLenum, start: GLsizei, x: GLint, y: GLint,
                          width: GLsizei){.stdcall, importc, ogl.}
proc glConvolutionFilter1D*(target: GLenum, internalformat: GLenum,
                            width: GLsizei, format: GLenum, typ: GLenum,
                            image: PGLvoid){.stdcall, importc, ogl.}
proc glConvolutionFilter2D*(target: GLenum, internalformat: GLenum,
                            width: GLsizei, height: GLsizei, format: GLenum,
                            typ: GLenum, image: PGLvoid){.stdcall, importc, ogl.}
proc glConvolutionParameterf*(target: GLenum, pname: GLenum, params: GLfloat){.
    stdcall, importc, ogl.}
proc glConvolutionParameterfv*(target: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glConvolutionParameteri*(target: GLenum, pname: GLenum, params: GLint){.
    stdcall, importc, ogl.}
proc glConvolutionParameteriv*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glCopyConvolutionFilter1D*(target: GLenum, internalformat: GLenum,
                                x: GLint, y: GLint, width: GLsizei){.stdcall, importc, ogl.}
proc glCopyConvolutionFilter2D*(target: GLenum, internalformat: GLenum,
                                x: GLint, y: GLint, width: GLsizei,
                                height: GLsizei){.stdcall, importc, ogl.}
proc glGetConvolutionFilter*(target: GLenum, format: GLenum, typ: GLenum,
                             image: PGLvoid){.stdcall, importc, ogl.}
proc glGetConvolutionParameterfv*(target: GLenum, pname: GLenum,
                                  params: PGLfloat){.stdcall, importc, ogl.}
proc glGetConvolutionParameteriv*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetSeparableFilter*(target: GLenum, format: GLenum, typ: GLenum,
                           row: PGLvoid, column: PGLvoid, span: PGLvoid){.
    stdcall, importc, ogl.}
proc glSeparableFilter2D*(target: GLenum, internalformat: GLenum,
                          width: GLsizei, height: GLsizei, format: GLenum,
                          typ: GLenum, row: PGLvoid, column: PGLvoid){.stdcall, importc, ogl.}
proc glGetHistogram*(target: GLenum, reset: GLboolean, format: GLenum,
                     typ: GLenum, values: PGLvoid){.stdcall, importc, ogl.}
proc glGetHistogramParameterfv*(target: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetHistogramParameteriv*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetMinmax*(target: GLenum, reset: GLboolean, format: GLenum, typ: GLenum,
                  values: PGLvoid){.stdcall, importc, ogl.}
proc glGetMinmaxParameterfv*(target: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetMinmaxParameteriv*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glHistogram*(target: GLenum, width: GLsizei, internalformat: GLenum,
                  sink: GLboolean){.stdcall, importc, ogl.}
proc glMinmax*(target: GLenum, internalformat: GLenum, sink: GLboolean){.stdcall, importc, ogl.}
proc glResetHistogram*(target: GLenum){.stdcall, importc, ogl.}
proc glResetMinmax*(target: GLenum){.stdcall, importc, ogl.}
  # GL_VERSION_1_3
proc glActiveTexture*(texture: GLenum){.stdcall, importc, ogl.}
proc glSampleCoverage*(value: GLclampf, invert: GLboolean){.stdcall, importc, ogl.}
proc glCompressedTexImage3D*(target: GLenum, level: GLint,
                             internalformat: GLenum, width: GLsizei,
                             height: GLsizei, depth: GLsizei, border: GLint,
                             imageSize: GLsizei, data: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedTexImage2D*(target: GLenum, level: GLint,
                             internalformat: GLenum, width: GLsizei,
                             height: GLsizei, border: GLint, imageSize: GLsizei,
                             data: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedTexImage1D*(target: GLenum, level: GLint,
                             internalformat: GLenum, width: GLsizei,
                             border: GLint, imageSize: GLsizei, data: PGLvoid){.
    stdcall, importc, ogl.}
proc glCompressedTexSubImage3D*(target: GLenum, level: GLint, xoffset: GLint,
                                yoffset: GLint, zoffset: GLint, width: GLsizei,
                                height: GLsizei, depth: GLsizei, format: GLenum,
                                imageSize: GLsizei, data: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedTexSubImage2D*(target: GLenum, level: GLint, xoffset: GLint,
                                yoffset: GLint, width: GLsizei, height: GLsizei,
                                format: GLenum, imageSize: GLsizei,
                                data: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedTexSubImage1D*(target: GLenum, level: GLint, xoffset: GLint,
                                width: GLsizei, format: GLenum,
                                imageSize: GLsizei, data: PGLvoid){.stdcall, importc, ogl.}
proc glGetCompressedTexImage*(target: GLenum, level: GLint, img: PGLvoid){.
    stdcall, importc, ogl.}
proc glClientActiveTexture*(texture: GLenum){.stdcall, importc, ogl.}
proc glMultiTexCoord1d*(target: GLenum, s: GLdouble){.stdcall, importc, ogl.}
proc glMultiTexCoord1dv*(target: GLenum, v: PGLdouble){.stdcall, importc, ogl.}
proc glMultiTexCoord1f*(target: GLenum, s: GLfloat){.stdcall, importc, ogl.}
proc glMultiTexCoord1fv*(target: GLenum, v: PGLfloat){.stdcall, importc, ogl.}
proc glMultiTexCoord1i*(target: GLenum, s: GLint){.stdcall, importc, ogl.}
proc glMultiTexCoord1iv*(target: GLenum, v: PGLint){.stdcall, importc, ogl.}
proc glMultiTexCoord1s*(target: GLenum, s: GLshort){.stdcall, importc, ogl.}
proc glMultiTexCoord1sv*(target: GLenum, v: PGLshort){.stdcall, importc, ogl.}
proc glMultiTexCoord2d*(target: GLenum, s: GLdouble, t: GLdouble){.stdcall, importc, ogl.}
proc glMultiTexCoord2dv*(target: GLenum, v: PGLdouble){.stdcall, importc, ogl.}
proc glMultiTexCoord2f*(target: GLenum, s: GLfloat, t: GLfloat){.stdcall, importc, ogl.}
proc glMultiTexCoord2fv*(target: GLenum, v: PGLfloat){.stdcall, importc, ogl.}
proc glMultiTexCoord2i*(target: GLenum, s: GLint, t: GLint){.stdcall, importc, ogl.}
proc glMultiTexCoord2iv*(target: GLenum, v: PGLint){.stdcall, importc, ogl.}
proc glMultiTexCoord2s*(target: GLenum, s: GLshort, t: GLshort){.stdcall, importc, ogl.}
proc glMultiTexCoord2sv*(target: GLenum, v: PGLshort){.stdcall, importc, ogl.}
proc glMultiTexCoord3d*(target: GLenum, s: GLdouble, t: GLdouble, r: GLdouble){.
    stdcall, importc, ogl.}
proc glMultiTexCoord3dv*(target: GLenum, v: PGLdouble){.stdcall, importc, ogl.}
proc glMultiTexCoord3f*(target: GLenum, s: GLfloat, t: GLfloat, r: GLfloat){.
    stdcall, importc, ogl.}
proc glMultiTexCoord3fv*(target: GLenum, v: PGLfloat){.stdcall, importc, ogl.}
proc glMultiTexCoord3i*(target: GLenum, s: GLint, t: GLint, r: GLint){.stdcall, importc, ogl.}
proc glMultiTexCoord3iv*(target: GLenum, v: PGLint){.stdcall, importc, ogl.}
proc glMultiTexCoord3s*(target: GLenum, s: GLshort, t: GLshort, r: GLshort){.
    stdcall, importc, ogl.}
proc glMultiTexCoord3sv*(target: GLenum, v: PGLshort){.stdcall, importc, ogl.}
proc glMultiTexCoord4d*(target: GLenum, s: GLdouble, t: GLdouble, r: GLdouble,
                        q: GLdouble){.stdcall, importc, ogl.}
proc glMultiTexCoord4dv*(target: GLenum, v: PGLdouble){.stdcall, importc, ogl.}
proc glMultiTexCoord4f*(target: GLenum, s: GLfloat, t: GLfloat, r: GLfloat,
                        q: GLfloat){.stdcall, importc, ogl.}
proc glMultiTexCoord4fv*(target: GLenum, v: PGLfloat){.stdcall, importc, ogl.}
proc glMultiTexCoord4i*(target: GLenum, s: GLint, t: GLint, r: GLint, q: GLint){.
    stdcall, importc, ogl.}
proc glMultiTexCoord4iv*(target: GLenum, v: PGLint){.stdcall, importc, ogl.}
proc glMultiTexCoord4s*(target: GLenum, s: GLshort, t: GLshort, r: GLshort,
                        q: GLshort){.stdcall, importc, ogl.}
proc glMultiTexCoord4sv*(target: GLenum, v: PGLshort){.stdcall, importc, ogl.}
proc glLoadTransposeMatrixf*(m: PGLfloat){.stdcall, importc, ogl.}
proc glLoadTransposeMatrixd*(m: PGLdouble){.stdcall, importc, ogl.}
proc glMultTransposeMatrixf*(m: PGLfloat){.stdcall, importc, ogl.}
proc glMultTransposeMatrixd*(m: PGLdouble){.stdcall, importc, ogl.}
  # GL_VERSION_1_4
proc glBlendFuncSeparate*(sfactorRGB: GLenum, dfactorRGB: GLenum,
                          sfactorAlpha: GLenum, dfactorAlpha: GLenum){.stdcall, importc, ogl.}
proc glMultiDrawArrays*(mode: GLenum, first: PGLint, count: PGLsizei,
                        primcount: GLsizei){.stdcall, importc, ogl.}
proc glMultiDrawElements*(mode: GLenum, count: PGLsizei, typ: GLenum,
                          indices: PGLvoid, primcount: GLsizei){.stdcall, importc, ogl.}
proc glPointParameterf*(pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glPointParameterfv*(pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glPointParameteri*(pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glPointParameteriv*(pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glFogCoordf*(coord: GLfloat){.stdcall, importc, ogl.}
proc glFogCoordfv*(coord: PGLfloat){.stdcall, importc, ogl.}
proc glFogCoordd*(coord: GLdouble){.stdcall, importc, ogl.}
proc glFogCoorddv*(coord: PGLdouble){.stdcall, importc, ogl.}
proc glFogCoordPointer*(typ: GLenum, stride: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glSecondaryColor3b*(red: GLbyte, green: GLbyte, blue: GLbyte){.stdcall, importc, ogl.}
proc glSecondaryColor3bv*(v: PGLbyte){.stdcall, importc, ogl.}
proc glSecondaryColor3d*(red: GLdouble, green: GLdouble, blue: GLdouble){.
    stdcall, importc, ogl.}
proc glSecondaryColor3dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glSecondaryColor3f*(red: GLfloat, green: GLfloat, blue: GLfloat){.stdcall, importc, ogl.}
proc glSecondaryColor3fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glSecondaryColor3i*(red: GLint, green: GLint, blue: GLint){.stdcall, importc, ogl.}
proc glSecondaryColor3iv*(v: PGLint){.stdcall, importc, ogl.}
proc glSecondaryColor3s*(red: GLshort, green: GLshort, blue: GLshort){.stdcall, importc, ogl.}
proc glSecondaryColor3sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glSecondaryColor3ub*(red: GLubyte, green: GLubyte, blue: GLubyte){.stdcall, importc, ogl.}
proc glSecondaryColor3ubv*(v: PGLubyte){.stdcall, importc, ogl.}
proc glSecondaryColor3ui*(red: GLuint, green: GLuint, blue: GLuint){.stdcall, importc, ogl.}
proc glSecondaryColor3uiv*(v: PGLuint){.stdcall, importc, ogl.}
proc glSecondaryColor3us*(red: GLushort, green: GLushort, blue: GLushort){.
    stdcall, importc, ogl.}
proc glSecondaryColor3usv*(v: PGLushort){.stdcall, importc, ogl.}
proc glSecondaryColorPointer*(size: GLint, typ: GLenum, stride: GLsizei,
                              pointer: PGLvoid){.stdcall, importc, ogl.}
proc glWindowPos2d*(x: GLdouble, y: GLdouble){.stdcall, importc, ogl.}
proc glWindowPos2dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glWindowPos2f*(x: GLfloat, y: GLfloat){.stdcall, importc, ogl.}
proc glWindowPos2fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glWindowPos2i*(x: GLint, y: GLint){.stdcall, importc, ogl.}
proc glWindowPos2iv*(v: PGLint){.stdcall, importc, ogl.}
proc glWindowPos2s*(x: GLshort, y: GLshort){.stdcall, importc, ogl.}
proc glWindowPos2sv*(v: PGLshort){.stdcall, importc, ogl.}
proc glWindowPos3d*(x: GLdouble, y: GLdouble, z: GLdouble){.stdcall, importc, ogl.}
proc glWindowPos3dv*(v: PGLdouble){.stdcall, importc, ogl.}
proc glWindowPos3f*(x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glWindowPos3fv*(v: PGLfloat){.stdcall, importc, ogl.}
proc glWindowPos3i*(x: GLint, y: GLint, z: GLint){.stdcall, importc, ogl.}
proc glWindowPos3iv*(v: PGLint){.stdcall, importc, ogl.}
proc glWindowPos3s*(x: GLshort, y: GLshort, z: GLshort){.stdcall, importc, ogl.}
proc glWindowPos3sv*(v: PGLshort){.stdcall, importc, ogl.}
  # GL_VERSION_1_5
proc glGenQueries*(n: GLsizei, ids: PGLuint){.stdcall, importc, ogl.}
proc glDeleteQueries*(n: GLsizei, ids: PGLuint){.stdcall, importc, ogl.}
proc glIsQuery*(id: GLuint): bool{.stdcall, importc, ogl.}
proc glBeginQuery*(target: GLenum, id: GLuint){.stdcall, importc, ogl.}
proc glEndQuery*(target: GLenum){.stdcall, importc, ogl.}
proc glGetQueryiv*(target, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetQueryObjectiv*(id: GLuint, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetQueryObjectuiv*(id: GLuint, pname: GLenum, params: PGLuint){.stdcall, importc, ogl.}
proc glBindBuffer*(target: GLenum, buffer: GLuint){.stdcall, importc, ogl.}
proc glDeleteBuffers*(n: GLsizei, buffers: PGLuint){.stdcall, importc, ogl.}
proc glGenBuffers*(n: GLsizei, buffers: PGLuint){.stdcall, importc, ogl.}
proc glIsBuffer*(buffer: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glBufferData*(target: GLenum, size: GLsizeiptr, data: PGLvoid,
                   usage: GLenum){.stdcall, importc, ogl.}
proc glBufferSubData*(target: GLenum, offset: GLintptr, size: GLsizeiptr,
                      data: PGLvoid){.stdcall, importc, ogl.}
proc glGetBufferSubData*(target: GLenum, offset: GLintptr, size: GLsizeiptr,
                         data: PGLvoid){.stdcall, importc, ogl.}
proc glMapBuffer*(target: GLenum, access: GLenum): PGLvoid{.stdcall, importc, ogl.}
proc glUnmapBuffer*(target: GLenum): GLboolean{.stdcall, importc, ogl.}
proc glGetBufferParameteriv*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetBufferPointerv*(target: GLenum, pname: GLenum, params: PGLvoid){.
    stdcall, importc, ogl.}
  # GL_VERSION_2_0
proc glBlendEquationSeparate*(modeRGB: GLenum, modeAlpha: GLenum){.stdcall, importc, ogl.}
proc glDrawBuffers*(n: GLsizei, bufs: PGLenum){.stdcall, importc, ogl.}
proc glStencilOpSeparate*(face: GLenum, sfail: GLenum, dpfail: GLenum,
                          dppass: GLenum){.stdcall, importc, ogl.}
proc glStencilFuncSeparate*(face: GLenum, func: GLenum, theRef: GLint, mask: GLuint){.
    stdcall, importc, ogl.}
proc glStencilMaskSeparate*(face: GLenum, mask: GLuint){.stdcall, importc, ogl.}
proc glAttachShader*(programObj, shaderObj: GLhandle){.stdcall, importc, ogl.}
proc glBindAttribLocation*(programObj: GLhandle, index: GLuint, name: PGLChar){.
    stdcall, importc, ogl.}
proc glCompileShader*(shaderObj: GLhandle){.stdcall, importc, ogl.}
proc glCreateProgram*(): GLhandle{.stdcall, importc, ogl.}
proc glCreateShader*(shaderType: GLenum): GLhandle{.stdcall, importc, ogl.}
proc glDeleteProgram*(programObj: GLhandle){.stdcall, importc, ogl.}
proc glDeleteShader*(shaderObj: GLhandle){.stdcall, importc, ogl.}
proc glDetachShader*(programObj, shaderObj: GLhandle){.stdcall, importc, ogl.}
proc glDisableVertexAttribArray*(index: GLuint){.stdcall, importc, ogl.}
proc glEnableVertexAttribArray*(index: GLuint){.stdcall, importc, ogl.}
proc glGetActiveAttrib*(programObj: GLhandle, index: GLuint, maxlength: GLsizei,
                        len: var GLint, size: var GLint, typ: var GLenum,
                        name: PGLChar){.stdcall, importc, ogl.}
proc glGetActiveUniform*(programObj: GLhandle, index: GLuint,
                         maxLength: GLsizei, len: var GLsizei, size: var GLint,
                         typ: var GLenum, name: PGLChar){.stdcall, importc, ogl.}
proc glGetAttachedShaders*(programObj: GLhandle, MaxCount: GLsizei,
                           Count: var GLint, shaders: PGLuint){.stdcall, importc, ogl.}
proc glGetAttribLocation*(programObj: GLhandle, char: PGLChar): glint{.stdcall, importc, ogl.}
proc glGetProgramiv*(programObj: GLhandle, pname: GLenum, params: PGLInt){.
    stdcall, importc, ogl.}
proc glGetProgramInfoLog*(programObj: GLHandle, maxLength: glsizei,
                          len: var GLint, infoLog: PGLChar){.stdcall, importc, ogl.}
proc glGetShaderiv*(shaderObj: GLhandle, pname: GLenum, params: PGLInt){.stdcall, importc, ogl.}
proc glGetShaderInfoLog*(shaderObj: GLHandle, maxLength: glsizei,
                         len: var glint, infoLog: PGLChar){.stdcall, importc, ogl.}
proc glGetShaderSource*(shaderObj: GLhandle, maxlength: GLsizei,
                        len: var GLsizei, source: PGLChar){.stdcall, importc, ogl.}
proc glGetUniformLocation*(programObj: GLhandle, char: PGLChar): glint{.stdcall, importc, ogl.}
proc glGetUniformfv*(programObj: GLhandle, location: GLint, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetUniformiv*(programObj: GLhandle, location: GLint, params: PGLInt){.
    stdcall, importc, ogl.}
proc glGetVertexAttribfv*(index: GLuint, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetVertexAttribiv*(index: GLuint, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetVertexAttribPointerv*(index: GLuint, pname: GLenum, pointer: PGLvoid){.
    stdcall, importc, ogl.}
proc glIsProgram*(programObj: GLhandle): GLboolean{.stdcall, importc, ogl.}
proc glIsShader*(shaderObj: GLhandle): GLboolean{.stdcall, importc, ogl.}
proc glLinkProgram*(programObj: GLHandle){.stdcall, importc, ogl.}
proc glShaderSource*(shaderObj: GLHandle, count: glsizei, string: cstringArray,
                     lengths: pglint){.stdcall, importc, ogl.}
proc glUseProgram*(programObj: GLhandle){.stdcall, importc, ogl.}
proc glUniform1f*(location: GLint, v0: GLfloat){.stdcall, importc, ogl.}
proc glUniform2f*(location: GLint, v0, v1: GLfloat){.stdcall, importc, ogl.}
proc glUniform3f*(location: GLint, v0, v1, v2: GLfloat){.stdcall, importc, ogl.}
proc glUniform4f*(location: GLint, v0, v1, v2, v3: GLfloat){.stdcall, importc, ogl.}
proc glUniform1i*(location: GLint, v0: GLint){.stdcall, importc, ogl.}
proc glUniform2i*(location: GLint, v0, v1: GLint){.stdcall, importc, ogl.}
proc glUniform3i*(location: GLint, v0, v1, v2: GLint){.stdcall, importc, ogl.}
proc glUniform4i*(location: GLint, v0, v1, v2, v3: GLint){.stdcall, importc, ogl.}
proc glUniform1fv*(location: GLint, count: GLsizei, value: PGLfloat){.stdcall, importc, ogl.}
proc glUniform2fv*(location: GLint, count: GLsizei, value: PGLfloat){.stdcall, importc, ogl.}
proc glUniform3fv*(location: GLint, count: GLsizei, value: PGLfloat){.stdcall, importc, ogl.}
proc glUniform4fv*(location: GLint, count: GLsizei, value: PGLfloat){.stdcall, importc, ogl.}
proc glUniform1iv*(location: GLint, count: GLsizei, value: PGLint){.stdcall, importc, ogl.}
proc glUniform2iv*(location: GLint, count: GLsizei, value: PGLint){.stdcall, importc, ogl.}
proc glUniform3iv*(location: GLint, count: GLsizei, value: PGLint){.stdcall, importc, ogl.}
proc glUniform4iv*(location: GLint, count: GLsizei, value: PGLint){.stdcall, importc, ogl.}
proc glUniformMatrix2fv*(location: GLint, count: GLsizei, transpose: GLboolean,
                         value: PGLfloat){.stdcall, importc, ogl.}
proc glUniformMatrix3fv*(location: GLint, count: GLsizei, transpose: GLboolean,
                         value: PGLfloat){.stdcall, importc, ogl.}
proc glUniformMatrix4fv*(location: GLint, count: GLsizei, transpose: GLboolean,
                         value: PGLfloat){.stdcall, importc, ogl.}
proc glValidateProgram*(programObj: GLhandle){.stdcall, importc, ogl.}
proc glVertexAttrib1d*(index: GLuint, x: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib1dv*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib1f*(index: GLuint, x: GLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib1fv*(index: GLuint, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib1s*(index: GLuint, x: GLshort){.stdcall, importc, ogl.}
proc glVertexAttrib1sv*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttrib2d*(index: GLuint, x: GLdouble, y: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib2dv*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib2f*(index: GLuint, x: GLfloat, y: GLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib2fv*(index: GLuint, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib2s*(index: GLuint, x: GLshort, y: GLshort){.stdcall, importc, ogl.}
proc glVertexAttrib2sv*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttrib3d*(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble){.
    stdcall, importc, ogl.}
proc glVertexAttrib3dv*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib3f*(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat){.
    stdcall, importc, ogl.}
proc glVertexAttrib3fv*(index: GLuint, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib3s*(index: GLuint, x: GLshort, y: GLshort, z: GLshort){.
    stdcall, importc, ogl.}
proc glVertexAttrib3sv*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttrib4Nbv*(index: GLuint, v: PGLbyte){.stdcall, importc, ogl.}
proc glVertexAttrib4Niv*(index: GLuint, v: PGLint){.stdcall, importc, ogl.}
proc glVertexAttrib4Nsv*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttrib4Nub*(index: GLuint, x: GLubyte, y: GLubyte, z: GLubyte,
                         w: GLubyte){.stdcall, importc, ogl.}
proc glVertexAttrib4Nubv*(index: GLuint, v: PGLubyte){.stdcall, importc, ogl.}
proc glVertexAttrib4Nuiv*(index: GLuint, v: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttrib4Nusv*(index: GLuint, v: PGLushort){.stdcall, importc, ogl.}
proc glVertexAttrib4bv*(index: GLuint, v: PGLbyte){.stdcall, importc, ogl.}
proc glVertexAttrib4d*(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble,
                       w: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib4dv*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib4f*(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat,
                       w: GLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib4fv*(index: GLuint, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib4iv*(index: GLuint, v: PGLint){.stdcall, importc, ogl.}
proc glVertexAttrib4s*(index: GLuint, x: GLshort, y: GLshort, z: GLshort,
                       w: GLshort){.stdcall, importc, ogl.}
proc glVertexAttrib4sv*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttrib4ubv*(index: GLuint, v: PGLubyte){.stdcall, importc, ogl.}
proc glVertexAttrib4uiv*(index: GLuint, v: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttrib4usv*(index: GLuint, v: PGLushort){.stdcall, importc, ogl.}
proc glVertexAttribPointer*(index: GLuint, size: GLint, typ: GLenum,
                            normalized: GLboolean, stride: GLsizei,
                            pointer: PGLvoid){.stdcall, importc, ogl.}
  # GL_VERSION_2_1
proc glUniformMatrix2x3fv*(location: GLint, count: GLsizei,
                           transpose: GLboolean, value: PGLfloat){.stdcall, importc, ogl.}
proc glUniformMatrix3x2fv*(location: GLint, count: GLsizei,
                           transpose: GLboolean, value: PGLfloat){.stdcall, importc, ogl.}
proc glUniformMatrix2x4fv*(location: GLint, count: GLsizei,
                           transpose: GLboolean, value: PGLfloat){.stdcall, importc, ogl.}
proc glUniformMatrix4x2fv*(location: GLint, count: GLsizei,
                           transpose: GLboolean, value: PGLfloat){.stdcall, importc, ogl.}
proc glUniformMatrix3x4fv*(location: GLint, count: GLsizei,
                           transpose: GLboolean, value: PGLfloat){.stdcall, importc, ogl.}
proc glUniformMatrix4x3fv*(location: GLint, count: GLsizei,
                           transpose: GLboolean, value: PGLfloat){.stdcall, importc, ogl.}
  # GL_VERSION_3_0
  # OpenGL 3.0 also reuses entry points from these extensions:
  # ARB_framebuffer_object
  # ARB_map_buffer_range
  # ARB_vertex_array_object
proc glColorMaski*(index: GLuint, r: GLboolean, g: GLboolean, b: GLboolean,
                   a: GLboolean){.stdcall, importc, ogl.}
proc glGetBooleani_v*(target: GLenum, index: GLuint, data: PGLboolean){.stdcall, importc, ogl.}
proc glGetIntegeri_v*(target: GLenum, index: GLuint, data: PGLint){.stdcall, importc, ogl.}
proc glEnablei*(target: GLenum, index: GLuint){.stdcall, importc, ogl.}
proc glDisablei*(target: GLenum, index: GLuint){.stdcall, importc, ogl.}
proc glIsEnabledi*(target: GLenum, index: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glBeginTransformFeedback*(primitiveMode: GLenum){.stdcall, importc, ogl.}
proc glEndTransformFeedback*(){.stdcall, importc, ogl.}
proc glBindBufferRange*(target: GLenum, index: GLuint, buffer: GLuint,
                        offset: GLintptr, size: GLsizeiptr){.stdcall, importc, ogl.}
proc glBindBufferBase*(target: GLenum, index: GLuint, buffer: GLuint){.stdcall, importc, ogl.}
proc glTransformFeedbackVaryings*(prog: GLuint, count: GLsizei,
                                  varyings: cstringArray, bufferMode: GLenum){.
    stdcall, importc, ogl.}
proc glGetTransformFeedbackVarying*(prog: GLuint, index: GLuint,
                                    bufSize: GLsizei, len: PGLsizei,
                                    size: PGLsizei, typ: PGLsizei, name: PGLchar){.
    stdcall, importc, ogl.}
proc glClampColor*(targe: GLenum, clamp: GLenum){.stdcall, importc, ogl.}
proc glBeginConditionalRender*(id: GLuint, mode: GLenum){.stdcall, importc, ogl.}
proc glEndConditionalRender*(){.stdcall, importc, ogl.}
proc glVertexAttribIPointer*(index: GLuint, size: GLint, typ: GLenum,
                             stride: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glGetVertexAttribIiv*(index: GLuint, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetVertexAttribIuiv*(index: GLuint, pname: GLenum, params: PGLuint){.
    stdcall, importc, ogl.}
proc glVertexAttribI1i*(index: GLuint, x: GLint){.stdcall, importc, ogl.}
proc glVertexAttribI2i*(index: GLuint, x: GLint, y: GLint){.stdcall, importc, ogl.}
proc glVertexAttribI3i*(index: GLuint, x: GLint, y: GLint, z: GLint){.stdcall, importc, ogl.}
proc glVertexAttribI4i*(index: GLuint, x: GLint, y: GLint, z: GLint, w: GLint){.
    stdcall, importc, ogl.}
proc glVertexAttribI1ui*(index: GLuint, x: GLuint){.stdcall, importc, ogl.}
proc glVertexAttribI2ui*(index: GLuint, x: GLuint, y: GLuint){.stdcall, importc, ogl.}
proc glVertexAttribI3ui*(index: GLuint, x: GLuint, y: GLuint, z: GLuint){.
    stdcall, importc, ogl.}
proc glVertexAttribI4ui*(index: GLuint, x: GLuint, y: GLuint, z: GLuint,
                         w: GLuint){.stdcall, importc, ogl.}
proc glVertexAttribI1iv*(index: GLuint, v: PGLint){.stdcall, importc, ogl.}
proc glVertexAttribI2iv*(index: GLuint, v: PGLint){.stdcall, importc, ogl.}
proc glVertexAttribI3iv*(index: GLuint, v: PGLint){.stdcall, importc, ogl.}
proc glVertexAttribI4iv*(index: GLuint, v: PGLint){.stdcall, importc, ogl.}
proc glVertexAttribI1uiv*(index: GLuint, v: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttribI2uiv*(index: GLuint, v: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttribI3uiv*(index: GLuint, v: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttribI4uiv*(index: GLuint, v: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttribI4bv*(index: GLuint, v: PGLbyte){.stdcall, importc, ogl.}
proc glVertexAttribI4sv*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttribI4ubv*(index: GLuint, v: PGLubyte){.stdcall, importc, ogl.}
proc glVertexAttribI4usv*(index: GLuint, v: PGLushort){.stdcall, importc, ogl.}
proc glGetUniformuiv*(prog: GLuint, location: GLint, params: PGLuint){.stdcall, importc, ogl.}
proc glBindFragDataLocation*(prog: GLuint, color: GLuint, name: PGLChar){.
    stdcall, importc, ogl.}
proc glGetFragDataLocation*(prog: GLuint, name: PGLChar): GLint{.stdcall, importc, ogl.}
proc glUniform1ui*(location: GLint, v0: GLuint){.stdcall, importc, ogl.}
proc glUniform2ui*(location: GLint, v0: GLuint, v1: GLuint){.stdcall, importc, ogl.}
proc glUniform3ui*(location: GLint, v0: GLuint, v1: GLuint, v2: GLuint){.stdcall, importc, ogl.}
proc glUniform4ui*(location: GLint, v0: GLuint, v1: GLuint, v2: GLuint,
                   v3: GLuint){.stdcall, importc, ogl.}
proc glUniform1uiv*(location: GLint, count: GLsizei, value: PGLuint){.stdcall, importc, ogl.}
proc glUniform2uiv*(location: GLint, count: GLsizei, value: PGLuint){.stdcall, importc, ogl.}
proc glUniform3uiv*(location: GLint, count: GLsizei, value: PGLuint){.stdcall, importc, ogl.}
proc glUniform4uiv*(location: GLint, count: GLsizei, value: PGLuint){.stdcall, importc, ogl.}
proc glTexParameterIiv*(target: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glTexParameterIuiv*(target: GLenum, pname: GLenum, params: PGLuint){.
    stdcall, importc, ogl.}
proc glGetTexParameterIiv*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetTexParameterIuiv*(target: GLenum, pname: GLenum, params: PGLuint){.
    stdcall, importc, ogl.}
proc glClearBufferiv*(buffer: GLenum, drawbuffer: GLint, value: PGLint){.stdcall, importc, ogl.}
proc glClearBufferuiv*(buffer: GLenum, drawbuffer: GLint, value: PGLuint){.
    stdcall, importc, ogl.}
proc glClearBufferfv*(buffer: GLenum, drawbuffer: GLint, value: PGLfloat){.
    stdcall, importc, ogl.}
proc glClearBufferfi*(buffer: GLenum, drawbuffer: GLint, depth: GLfloat,
                      stencil: GLint){.stdcall, importc, ogl.}
proc glGetStringi*(name: GLenum, index: GLuint): PGLubyte{.stdcall, importc, ogl.}
  # GL_VERSION_3_1
  # OpenGL 3.1 also reuses entry points from these extensions:
  # ARB_copy_buffer
  # ARB_uniform_buffer_object
proc glDrawArraysInstanced*(mode: GLenum, first: GLint, count: GLsizei,
                            primcount: GLsizei){.stdcall, importc, ogl.}
proc glDrawElementsInstanced*(mode: GLenum, count: GLsizei, typ: GLenum,
                              indices: PGLvoid, primcount: GLsizei){.stdcall, importc, ogl.}
proc glTexBuffer*(target: GLenum, internalformat: GLenum, buffer: GLuint){.
    stdcall, importc, ogl.}
proc glPrimitiveRestartIndex*(index: GLuint){.stdcall, importc, ogl.}
  # GL_VERSION_3_2
  # OpenGL 3.2 also reuses entry points from these extensions:
  # ARB_draw_elements_base_vertex
  # ARB_provoking_vertex
  # ARB_sync
  # ARB_texture_multisample
proc glGetInteger64i_v*(target: GLenum, index: GLuint, data: PGLint64){.stdcall, importc, ogl.}
proc glGetBufferParameteri64v*(target: GLenum, pname: GLenum, params: PGLint64){.
    stdcall, importc, ogl.}
proc glFramebufferTexture*(target: GLenum, attachment: GLenum, texture: GLuint,
                           level: GLint){.stdcall, importc, ogl.}
  #procedure glFramebufferTextureFace(target: GLenum; attachment: GLenum; texture: GLuint; level: GLint; face: GLenum); stdcall, importc, ogl;
  # GL_VERSION_3_3
  # OpenGL 3.3 also reuses entry points from these extensions:
  # ARB_blend_func_extended
  # ARB_sampler_objects
  # ARB_explicit_attrib_location, but it has none
  # ARB_occlusion_query2 (no entry points)
  # ARB_shader_bit_encoding (no entry points)
  # ARB_texture_rgb10_a2ui (no entry points)
  # ARB_texture_swizzle (no entry points)
  # ARB_timer_query
  # ARB_vertextyp_2_10_10_10_rev
proc glVertexAttribDivisor*(index: GLuint, divisor: GLuint){.stdcall, importc, ogl.}
  # GL_VERSION_4_0
  # OpenGL 4.0 also reuses entry points from these extensions:
  # ARB_texture_query_lod (no entry points)
  # ARB_draw_indirect
  # ARB_gpu_shader5 (no entry points)
  # ARB_gpu_shader_fp64
  # ARB_shader_subroutine
  # ARB_tessellation_shader
  # ARB_texture_buffer_object_rgb32 (no entry points)
  # ARB_texture_cube_map_array (no entry points)
  # ARB_texture_gather (no entry points)
  # ARB_transform_feedback2
  # ARB_transform_feedback3
proc glMinSampleShading*(value: GLclampf){.stdcall, importc, ogl.}
proc glBlendEquationi*(buf: GLuint, mode: GLenum){.stdcall, importc, ogl.}
proc glBlendEquationSeparatei*(buf: GLuint, modeRGB: GLenum, modeAlpha: GLenum){.
    stdcall, importc, ogl.}
proc glBlendFunci*(buf: GLuint, src: GLenum, dst: GLenum){.stdcall, importc, ogl.}
proc glBlendFuncSeparatei*(buf: GLuint, srcRGB: GLenum, dstRGB: GLenum,
                           srcAlpha: GLenum, dstAlpha: GLenum){.stdcall, importc, ogl.}
  # GL_VERSION_4_1
  # OpenGL 4.1 also reuses entry points from these extensions:
  # ARB_ES2_compatibility
  # ARB_get_program_binary
  # ARB_separate_shader_objects
  # ARB_shader_precision (no entry points)
  # ARB_vertex_attrib_64bit
  # ARB_viewport_array
  # GL_3DFX_tbuffer
proc glTbufferMask3DFX*(mask: GLuint){.stdcall, importc, ogl.}
  # GL_APPLE_element_array
proc glElementPointerAPPLE*(typ: GLenum, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glDrawElementArrayAPPLE*(mode: GLenum, first: GLint, count: GLsizei){.
    stdcall, importc, ogl.}
proc glDrawRangeElementArrayAPPLE*(mode: GLenum, start: GLuint, ending: GLuint,
                                   first: GLint, count: GLsizei){.stdcall, importc, ogl.}
proc glMultiDrawElementArrayAPPLE*(mode: GLenum, first: PGLint, count: PGLsizei,
                                   primcount: GLsizei){.stdcall, importc, ogl.}
proc glMultiDrawRangeElementArrayAPPLE*(mode: GLenum, start: GLuint,
                                        ending: GLuint, first: PGLint,
                                        count: PGLsizei, primcount: GLsizei){.
    stdcall, importc, ogl.}
  # GL_APPLE_fence
proc glGenFencesAPPLE*(n: GLsizei, fences: PGLuint){.stdcall, importc, ogl.}
proc glDeleteFencesAPPLE*(n: GLsizei, fences: PGLuint){.stdcall, importc, ogl.}
proc glSetFenceAPPLE*(fence: GLuint){.stdcall, importc, ogl.}
proc glIsFenceAPPLE*(fence: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glTestFenceAPPLE*(fence: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glFinishFenceAPPLE*(fence: GLuint){.stdcall, importc, ogl.}
proc glTestObjectAPPLE*(obj: GLenum, name: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glFinishObjectAPPLE*(obj: GLenum, name: GLint){.stdcall, importc, ogl.}
  # GL_APPLE_vertex_array_object
proc glBindVertexArrayAPPLE*(arr: GLuint){.stdcall, importc, ogl.}
proc glDeleteVertexArraysAPPLE*(n: GLsizei, arrays: PGLuint){.stdcall, importc, ogl.}
proc glGenVertexArraysAPPLE*(n: GLsizei, arrays: PGLuint){.stdcall, importc, ogl.}
proc glIsVertexArrayAPPLE*(arr: GLuint): GLboolean{.stdcall, importc, ogl.}
  # GL_APPLE_vertex_array_range
proc glVertexArrayRangeAPPLE*(len: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glFlushVertexArrayRangeAPPLE*(len: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glVertexArrayParameteriAPPLE*(pname: GLenum, param: GLint){.stdcall, importc, ogl.}
  # GL_APPLE_texture_range
proc glTextureRangeAPPLE*(target: GLenum, len: GLsizei, Pointer: PGLvoid){.
    stdcall, importc, ogl.}
proc glGetTexParameterPointervAPPLE*(target: GLenum, pname: GLenum,
                                     params: PPGLvoid){.stdcall, importc, ogl.}
  # GL_APPLE_vertex_program_evaluators
proc glEnableVertexAttribAPPLE*(index: GLuint, pname: GLenum){.stdcall, importc, ogl.}
proc glDisableVertexAttribAPPLE*(index: GLuint, pname: GLenum){.stdcall, importc, ogl.}
proc glIsVertexAttribEnabledAPPLE*(index: GLuint, pname: GLenum): GLboolean{.
    stdcall, importc, ogl.}
proc glMapVertexAttrib1dAPPLE*(index: GLuint, size: GLuint, u1: GLdouble,
                               u2: GLdouble, stride: GLint, order: GLint,
                               points: PGLdouble){.stdcall, importc, ogl.}
proc glMapVertexAttrib1fAPPLE*(index: GLuint, size: GLuint, u1: GLfloat,
                               u2: GLfloat, stride: GLint, order: GLint,
                               points: PGLfloat){.stdcall, importc, ogl.}
proc glMapVertexAttrib2dAPPLE*(index: GLuint, size: GLuint, u1: GLdouble,
                               u2: GLdouble, ustride: GLint, uorder: GLint,
                               v1: GLdouble, v2: GLdouble, vstride: GLint,
                               vorder: GLint, points: PGLdouble){.stdcall, importc, ogl.}
proc glMapVertexAttrib2fAPPLE*(index: GLuint, size: GLuint, u1: GLfloat,
                               u2: GLfloat, ustride: GLint, order: GLint,
                               v1: GLfloat, v2: GLfloat, vstride: GLint,
                               vorder: GLint, points: GLfloat){.stdcall, importc, ogl.}
  # GL_APPLE_object_purgeable
proc glObjectPurgeableAPPLE*(objectType: GLenum, name: GLuint, option: GLenum): GLenum{.
    stdcall, importc, ogl.}
proc glObjectUnpurgeableAPPLE*(objectType: GLenum, name: GLuint, option: GLenum): GLenum{.
    stdcall, importc, ogl.}
proc glGetObjectParameterivAPPLE*(objectType: GLenum, name: GLuint,
                                  pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
  # GL_ARB_matrix_palette
proc glCurrentPaletteMatrixARB*(index: GLint){.stdcall, importc, ogl.}
proc glMatrixIndexubvARB*(size: GLint, indices: PGLubyte){.stdcall, importc, ogl.}
proc glMatrixIndexusvARB*(size: GLint, indices: PGLushort){.stdcall, importc, ogl.}
proc glMatrixIndexuivARB*(size: GLint, indices: PGLuint){.stdcall, importc, ogl.}
proc glMatrixIndexPointerARB*(size: GLint, typ: GLenum, stride: GLsizei,
                              pointer: PGLvoid){.stdcall, importc, ogl.}
  # GL_ARB_multisample
proc glSampleCoverageARB*(value: GLclampf, invert: GLboolean){.stdcall, importc, ogl.}
  # GL_ARB_multitexture
proc glActiveTextureARB*(texture: GLenum){.stdcall, importc, ogl.}
proc glClientActiveTextureARB*(texture: GLenum){.stdcall, importc, ogl.}
proc glMultiTexCoord1dARB*(target: GLenum, s: GLdouble){.stdcall, importc, ogl.}
proc glMultiTexCoord1dvARB*(target: GLenum, v: PGLdouble){.stdcall, importc, ogl.}
proc glMultiTexCoord1fARB*(target: GLenum, s: GLfloat){.stdcall, importc, ogl.}
proc glMultiTexCoord1fvARB*(target: GLenum, v: PGLfloat){.stdcall, importc, ogl.}
proc glMultiTexCoord1iARB*(target: GLenum, s: GLint){.stdcall, importc, ogl.}
proc glMultiTexCoord1ivARB*(target: GLenum, v: PGLint){.stdcall, importc, ogl.}
proc glMultiTexCoord1sARB*(target: GLenum, s: GLshort){.stdcall, importc, ogl.}
proc glMultiTexCoord1svARB*(target: GLenum, v: PGLshort){.stdcall, importc, ogl.}
proc glMultiTexCoord2dARB*(target: GLenum, s: GLdouble, t: GLdouble){.stdcall, importc, ogl.}
proc glMultiTexCoord2dvARB*(target: GLenum, v: PGLdouble){.stdcall, importc, ogl.}
proc glMultiTexCoord2fARB*(target: GLenum, s: GLfloat, t: GLfloat){.stdcall, importc, ogl.}
proc glMultiTexCoord2fvARB*(target: GLenum, v: PGLfloat){.stdcall, importc, ogl.}
proc glMultiTexCoord2iARB*(target: GLenum, s: GLint, t: GLint){.stdcall, importc, ogl.}
proc glMultiTexCoord2ivARB*(target: GLenum, v: PGLint){.stdcall, importc, ogl.}
proc glMultiTexCoord2sARB*(target: GLenum, s: GLshort, t: GLshort){.stdcall, importc, ogl.}
proc glMultiTexCoord2svARB*(target: GLenum, v: PGLshort){.stdcall, importc, ogl.}
proc glMultiTexCoord3dARB*(target: GLenum, s: GLdouble, t: GLdouble, r: GLdouble){.
    stdcall, importc, ogl.}
proc glMultiTexCoord3dvARB*(target: GLenum, v: PGLdouble){.stdcall, importc, ogl.}
proc glMultiTexCoord3fARB*(target: GLenum, s: GLfloat, t: GLfloat, r: GLfloat){.
    stdcall, importc, ogl.}
proc glMultiTexCoord3fvARB*(target: GLenum, v: PGLfloat){.stdcall, importc, ogl.}
proc glMultiTexCoord3iARB*(target: GLenum, s: GLint, t: GLint, r: GLint){.
    stdcall, importc, ogl.}
proc glMultiTexCoord3ivARB*(target: GLenum, v: PGLint){.stdcall, importc, ogl.}
proc glMultiTexCoord3sARB*(target: GLenum, s: GLshort, t: GLshort, r: GLshort){.
    stdcall, importc, ogl.}
proc glMultiTexCoord3svARB*(target: GLenum, v: PGLshort){.stdcall, importc, ogl.}
proc glMultiTexCoord4dARB*(target: GLenum, s: GLdouble, t: GLdouble,
                           r: GLdouble, q: GLdouble){.stdcall, importc, ogl.}
proc glMultiTexCoord4dvARB*(target: GLenum, v: PGLdouble){.stdcall, importc, ogl.}
proc glMultiTexCoord4fARB*(target: GLenum, s: GLfloat, t: GLfloat, r: GLfloat,
                           q: GLfloat){.stdcall, importc, ogl.}
proc glMultiTexCoord4fvARB*(target: GLenum, v: PGLfloat){.stdcall, importc, ogl.}
proc glMultiTexCoord4iARB*(target: GLenum, s: GLint, t: GLint, r: GLint,
                           q: GLint){.stdcall, importc, ogl.}
proc glMultiTexCoord4ivARB*(target: GLenum, v: PGLint){.stdcall, importc, ogl.}
proc glMultiTexCoord4sARB*(target: GLenum, s: GLshort, t: GLshort, r: GLshort,
                           q: GLshort){.stdcall, importc, ogl.}
proc glMultiTexCoord4svARB*(target: GLenum, v: PGLshort){.stdcall, importc, ogl.}
  # GL_ARB_point_parameters
proc glPointParameterfARB*(pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glPointParameterfvARB*(pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
  # GL_ARB_texture_compression
proc glCompressedTexImage3DARB*(target: GLenum, level: GLint,
                                internalformat: GLenum, width: GLsizei,
                                height: GLsizei, depth: GLsizei, border: GLint,
                                imageSize: GLsizei, data: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedTexImage2DARB*(target: GLenum, level: GLint,
                                internalformat: GLenum, width: GLsizei,
                                height: GLsizei, border: GLint,
                                imageSize: GLsizei, data: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedTexImage1DARB*(target: GLenum, level: GLint,
                                internalformat: GLenum, width: GLsizei,
                                border: GLint, imageSize: GLsizei, data: PGLvoid){.
    stdcall, importc, ogl.}
proc glCompressedTexSubImage3DARB*(target: GLenum, level: GLint, xoffset: GLint,
                                   yoffset: GLint, zoffset: GLint,
                                   width: GLsizei, height: GLsizei,
                                   depth: GLsizei, format: GLenum,
                                   imageSize: GLsizei, data: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedTexSubImage2DARB*(target: GLenum, level: GLint, xoffset: GLint,
                                   yoffset: GLint, width: GLsizei,
                                   height: GLsizei, format: GLenum,
                                   imageSize: GLsizei, data: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedTexSubImage1DARB*(target: GLenum, level: GLint, xoffset: GLint,
                                   width: GLsizei, format: GLenum,
                                   imageSize: GLsizei, data: PGLvoid){.stdcall, importc, ogl.}
proc glGetCompressedTexImageARB*(target: GLenum, level: GLint, img: PGLvoid){.
    stdcall, importc, ogl.}
  # GL_ARB_transpose_matrix
proc glLoadTransposeMatrixfARB*(m: PGLfloat){.stdcall, importc, ogl.}
proc glLoadTransposeMatrixdARB*(m: PGLdouble){.stdcall, importc, ogl.}
proc glMultTransposeMatrixfARB*(m: PGLfloat){.stdcall, importc, ogl.}
proc glMultTransposeMatrixdARB*(m: PGLdouble){.stdcall, importc, ogl.}
  # GL_ARB_vertex_blend
proc glWeightbvARB*(size: GLint, weights: PGLbyte){.stdcall, importc, ogl.}
proc glWeightsvARB*(size: GLint, weights: PGLshort){.stdcall, importc, ogl.}
proc glWeightivARB*(size: GLint, weights: PGLint){.stdcall, importc, ogl.}
proc glWeightfvARB*(size: GLint, weights: PGLfloat){.stdcall, importc, ogl.}
proc glWeightdvARB*(size: GLint, weights: PGLdouble){.stdcall, importc, ogl.}
proc glWeightubvARB*(size: GLint, weights: PGLubyte){.stdcall, importc, ogl.}
proc glWeightusvARB*(size: GLint, weights: PGLushort){.stdcall, importc, ogl.}
proc glWeightuivARB*(size: GLint, weights: PGLuint){.stdcall, importc, ogl.}
proc glWeightPointerARB*(size: GLint, typ: GLenum, stride: GLsizei,
                         pointer: PGLvoid){.stdcall, importc, ogl.}
proc glVertexBlendARB*(count: GLint){.stdcall, importc, ogl.}
  # GL_ARB_vertex_buffer_object
proc glBindBufferARB*(target: GLenum, buffer: GLuint){.stdcall, importc, ogl.}
proc glDeleteBuffersARB*(n: GLsizei, buffers: PGLuint){.stdcall, importc, ogl.}
proc glGenBuffersARB*(n: GLsizei, buffers: PGLuint){.stdcall, importc, ogl.}
proc glIsBufferARB*(buffer: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glBufferDataARB*(target: GLenum, size: GLsizeiptrARB, data: PGLvoid,
                      usage: GLenum){.stdcall, importc, ogl.}
proc glBufferSubDataARB*(target: GLenum, offset: GLintptrARB,
                         size: GLsizeiptrARB, data: PGLvoid){.stdcall, importc, ogl.}
proc glGetBufferSubDataARB*(target: GLenum, offset: GLintptrARB,
                            size: GLsizeiptrARB, data: PGLvoid){.stdcall, importc, ogl.}
proc glMapBufferARB*(target: GLenum, access: GLenum): PGLvoid{.stdcall, importc, ogl.}
proc glUnmapBufferARB*(target: GLenum): GLboolean{.stdcall, importc, ogl.}
proc glGetBufferParameterivARB*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetBufferPointervARB*(target: GLenum, pname: GLenum, params: PGLvoid){.
    stdcall, importc, ogl.}
  # GL_ARB_vertex_program
proc glVertexAttrib1dARB*(index: GLuint, x: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib1dvARB*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib1fARB*(index: GLuint, x: GLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib1fvARB*(index: GLuint, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib1sARB*(index: GLuint, x: GLshort){.stdcall, importc, ogl.}
proc glVertexAttrib1svARB*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttrib2dARB*(index: GLuint, x: GLdouble, y: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib2dvARB*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib2fARB*(index: GLuint, x: GLfloat, y: GLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib2fvARB*(index: GLuint, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib2sARB*(index: GLuint, x: GLshort, y: GLshort){.stdcall, importc, ogl.}
proc glVertexAttrib2svARB*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttrib3dARB*(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble){.
    stdcall, importc, ogl.}
proc glVertexAttrib3dvARB*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib3fARB*(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat){.
    stdcall, importc, ogl.}
proc glVertexAttrib3fvARB*(index: GLuint, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib3sARB*(index: GLuint, x: GLshort, y: GLshort, z: GLshort){.
    stdcall, importc, ogl.}
proc glVertexAttrib3svARB*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttrib4NbvARB*(index: GLuint, v: PGLbyte){.stdcall, importc, ogl.}
proc glVertexAttrib4NivARB*(index: GLuint, v: PGLint){.stdcall, importc, ogl.}
proc glVertexAttrib4NsvARB*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttrib4NubARB*(index: GLuint, x: GLubyte, y: GLubyte, z: GLubyte,
                            w: GLubyte){.stdcall, importc, ogl.}
proc glVertexAttrib4NubvARB*(index: GLuint, v: PGLubyte){.stdcall, importc, ogl.}
proc glVertexAttrib4NuivARB*(index: GLuint, v: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttrib4NusvARB*(index: GLuint, v: PGLushort){.stdcall, importc, ogl.}
proc glVertexAttrib4bvARB*(index: GLuint, v: PGLbyte){.stdcall, importc, ogl.}
proc glVertexAttrib4dARB*(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble,
                          w: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib4dvARB*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib4fARB*(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat,
                          w: GLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib4fvARB*(index: GLuint, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib4ivARB*(index: GLuint, v: PGLint){.stdcall, importc, ogl.}
proc glVertexAttrib4sARB*(index: GLuint, x: GLshort, y: GLshort, z: GLshort,
                          w: GLshort){.stdcall, importc, ogl.}
proc glVertexAttrib4svARB*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttrib4ubvARB*(index: GLuint, v: PGLubyte){.stdcall, importc, ogl.}
proc glVertexAttrib4uivARB*(index: GLuint, v: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttrib4usvARB*(index: GLuint, v: PGLushort){.stdcall, importc, ogl.}
proc glVertexAttribPointerARB*(index: GLuint, size: GLint, typ: GLenum,
                               normalized: GLboolean, stride: GLsizei,
                               pointer: PGLvoid){.stdcall, importc, ogl.}
proc glEnableVertexAttribArrayARB*(index: GLuint){.stdcall, importc, ogl.}
proc glDisableVertexAttribArrayARB*(index: GLuint){.stdcall, importc, ogl.}
proc glProgramStringARB*(target: GLenum, format: GLenum, length: GLsizei,
                         string: PGLvoid){.stdcall, importc, ogl.}
proc glBindProgramARB*(target: GLenum, prog: GLuint){.stdcall, importc, ogl.}
proc glDeleteProgramsARB*(n: GLsizei, programs: PGLuint){.stdcall, importc, ogl.}
proc glGenProgramsARB*(n: GLsizei, programs: PGLuint){.stdcall, importc, ogl.}
proc glProgramEnvParameter4dARB*(target: GLenum, index: GLuint, x: GLdouble,
                                 y: GLdouble, z: GLdouble, w: GLdouble){.stdcall, importc, ogl.}
proc glProgramEnvParameter4dvARB*(target: GLenum, index: GLuint,
                                  params: PGLdouble){.stdcall, importc, ogl.}
proc glProgramEnvParameter4fARB*(target: GLenum, index: GLuint, x: GLfloat,
                                 y: GLfloat, z: GLfloat, w: GLfloat){.stdcall, importc, ogl.}
proc glProgramEnvParameter4fvARB*(target: GLenum, index: GLuint,
                                  params: PGLfloat){.stdcall, importc, ogl.}
proc glProgramLocalParameter4dARB*(target: GLenum, index: GLuint, x: GLdouble,
                                   y: GLdouble, z: GLdouble, w: GLdouble){.
    stdcall, importc, ogl.}
proc glProgramLocalParameter4dvARB*(target: GLenum, index: GLuint,
                                    params: PGLdouble){.stdcall, importc, ogl.}
proc glProgramLocalParameter4fARB*(target: GLenum, index: GLuint, x: GLfloat,
                                   y: GLfloat, z: GLfloat, w: GLfloat){.stdcall, importc, ogl.}
proc glProgramLocalParameter4fvARB*(target: GLenum, index: GLuint,
                                    params: PGLfloat){.stdcall, importc, ogl.}
proc glGetProgramEnvParameterdvARB*(target: GLenum, index: GLuint,
                                    params: PGLdouble){.stdcall, importc, ogl.}
proc glGetProgramEnvParameterfvARB*(target: GLenum, index: GLuint,
                                    params: PGLfloat){.stdcall, importc, ogl.}
proc glGetProgramLocalParameterdvARB*(target: GLenum, index: GLuint,
                                      params: PGLdouble){.stdcall, importc, ogl.}
proc glGetProgramLocalParameterfvARB*(target: GLenum, index: GLuint,
                                      params: PGLfloat){.stdcall, importc, ogl.}
proc glGetProgramivARB*(target: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetProgramStringARB*(target: GLenum, pname: GLenum, string: PGLvoid){.
    stdcall, importc, ogl.}
proc glGetVertexAttribdvARB*(index: GLuint, pname: GLenum, params: PGLdouble){.
    stdcall, importc, ogl.}
proc glGetVertexAttribfvARB*(index: GLuint, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetVertexAttribivARB*(index: GLuint, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetVertexAttribPointervARB*(index: GLuint, pname: GLenum,
                                   pointer: PGLvoid){.stdcall, importc, ogl.}
proc glIsProgramARB*(prog: GLuint): GLboolean{.stdcall, importc, ogl.}
  # GL_ARB_window_pos
proc glWindowPos2dARB*(x: GLdouble, y: GLdouble){.stdcall, importc, ogl.}
proc glWindowPos2dvARB*(v: PGLdouble){.stdcall, importc, ogl.}
proc glWindowPos2fARB*(x: GLfloat, y: GLfloat){.stdcall, importc, ogl.}
proc glWindowPos2fvARB*(v: PGLfloat){.stdcall, importc, ogl.}
proc glWindowPos2iARB*(x: GLint, y: GLint){.stdcall, importc, ogl.}
proc glWindowPos2ivARB*(v: PGLint){.stdcall, importc, ogl.}
proc glWindowPos2sARB*(x: GLshort, y: GLshort){.stdcall, importc, ogl.}
proc glWindowPos2svARB*(v: PGLshort){.stdcall, importc, ogl.}
proc glWindowPos3dARB*(x: GLdouble, y: GLdouble, z: GLdouble){.stdcall, importc, ogl.}
proc glWindowPos3dvARB*(v: PGLdouble){.stdcall, importc, ogl.}
proc glWindowPos3fARB*(x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glWindowPos3fvARB*(v: PGLfloat){.stdcall, importc, ogl.}
proc glWindowPos3iARB*(x: GLint, y: GLint, z: GLint){.stdcall, importc, ogl.}
proc glWindowPos3ivARB*(v: PGLint){.stdcall, importc, ogl.}
proc glWindowPos3sARB*(x: GLshort, y: GLshort, z: GLshort){.stdcall, importc, ogl.}
proc glWindowPos3svARB*(v: PGLshort){.stdcall, importc, ogl.}
  # GL_ARB_draw_buffers
proc glDrawBuffersARB*(n: GLsizei, bufs: PGLenum){.stdcall, importc, ogl.}
  # GL_ARB_color_buffer_float
proc glClampColorARB*(target: GLenum, clamp: GLenum){.stdcall, importc, ogl.}
  # GL_ARB_vertex_shader
proc glGetActiveAttribARB*(programobj: GLhandleARB, index: GLuint,
                           maxLength: GLsizei, len: var GLsizei,
                           size: var GLint, typ: var GLenum, name: PGLcharARB){.
    stdcall, importc, ogl.}
proc glGetAttribLocationARB*(programObj: GLhandleARB, char: PGLcharARB): glint{.
    stdcall, importc, ogl.}
proc glBindAttribLocationARB*(programObj: GLhandleARB, index: GLuint,
                              name: PGLcharARB){.stdcall, importc, ogl.}
  # GL_ARB_shader_objects
proc glDeleteObjectARB*(Obj: GLHandleARB){.stdcall, importc, ogl.}
proc glGetHandleARB*(pname: GlEnum): GLHandleARB{.stdcall, importc, ogl.}
proc glDetachObjectARB*(container, attached: GLHandleARB){.stdcall, importc, ogl.}
proc glCreateShaderObjectARB*(shaderType: glenum): GLHandleARB{.stdcall, importc, ogl.}
proc glShaderSourceARB*(shaderObj: GLHandleARB, count: glsizei,
                        string: cstringArray, lengths: pglint){.stdcall, importc, ogl.}
proc glCompileShaderARB*(shaderObj: GLHandleARB){.stdcall, importc, ogl.}
proc glCreateProgramObjectARB*(): GLHandleARB{.stdcall, importc, ogl.}
proc glAttachObjectARB*(programObj, shaderObj: GLhandleARB){.stdcall, importc, ogl.}
proc glLinkProgramARB*(programObj: GLHandleARB){.stdcall, importc, ogl.}
proc glUseProgramObjectARB*(programObj: GLHandleARB){.stdcall, importc, ogl.}
proc glValidateProgramARB*(programObj: GLhandleARB){.stdcall, importc, ogl.}
proc glUniform1fARB*(location: glint, v0: glfloat){.stdcall, importc, ogl.}
proc glUniform2fARB*(location: glint, v0, v1: glfloat){.stdcall, importc, ogl.}
proc glUniform3fARB*(location: glint, v0, v1, v2: glfloat){.stdcall, importc, ogl.}
proc glUniform4fARB*(location: glint, v0, v1, v2, v3: glfloat){.stdcall, importc, ogl.}
proc glUniform1iARB*(location: glint, v0: glint){.stdcall, importc, ogl.}
proc glUniform2iARB*(location: glint, v0, v1: glint){.stdcall, importc, ogl.}
proc glUniform3iARB*(location: glint, v0, v1, v2: glint){.stdcall, importc, ogl.}
proc glUniform4iARB*(location: glint, v0, v1, v2, v3: glint){.stdcall, importc, ogl.}
proc glUniform1fvARB*(location: glint, count: GLsizei, value: pglfloat){.stdcall, importc, ogl.}
proc glUniform2fvARB*(location: glint, count: GLsizei, value: pglfloat){.stdcall, importc, ogl.}
proc glUniform3fvARB*(location: glint, count: GLsizei, value: pglfloat){.stdcall, importc, ogl.}
proc glUniform4fvARB*(location: glint, count: GLsizei, value: pglfloat){.stdcall, importc, ogl.}
proc glUniform1ivARB*(location: glint, count: GLsizei, value: pglint){.stdcall, importc, ogl.}
proc glUniform2ivARB*(location: glint, count: GLsizei, value: pglint){.stdcall, importc, ogl.}
proc glUniform3ivARB*(location: glint, count: GLsizei, value: pglint){.stdcall, importc, ogl.}
proc glUniform4ivARB*(location: glint, count: GLsizei, value: pglint){.stdcall, importc, ogl.}
proc glUniformMatrix2fvARB*(location: glint, count: glsizei,
                            transpose: glboolean, value: pglfloat){.stdcall, importc, ogl.}
proc glUniformMatrix3fvARB*(location: glint, count: glsizei,
                            transpose: glboolean, value: pglfloat){.stdcall, importc, ogl.}
proc glUniformMatrix4fvARB*(location: glint, count: glsizei,
                            transpose: glboolean, value: pglfloat){.stdcall, importc, ogl.}
proc glGetObjectParameterfvARB*(Obj: GLHandleARB, pname: GLEnum,
                                params: PGLFloat){.stdcall, importc, ogl.}
proc glGetObjectParameterivARB*(Obj: GLHandleARB, pname: GLEnum, params: PGLInt){.
    stdcall, importc, ogl.}
proc glGetInfoLogARB*(shaderObj: GLHandleARB, maxLength: glsizei,
                      len: var glint, infoLog: PGLcharARB){.stdcall, importc, ogl.}
proc glGetAttachedObjectsARB*(programobj: GLhandleARB, maxCount: GLsizei,
                              count: var GLsizei, objects: PGLhandleARB){.
    stdcall, importc, ogl.}
proc glGetUniformLocationARB*(programObj: GLhandleARB, char: PGLcharARB): glint{.
    stdcall, importc, ogl.}
proc glGetActiveUniformARB*(programobj: GLhandleARB, index: GLuint,
                            maxLength: GLsizei, len: var GLsizei,
                            size: var GLint, typ: var GLenum, name: PGLcharARB){.
    stdcall, importc, ogl.}
proc glGetUniformfvARB*(programObj: GLhandleARB, location: GLint,
                        params: PGLfloat){.stdcall, importc, ogl.}
proc glGetUniformivARB*(programObj: GLhandleARB, location: GLint, params: PGLInt){.
    stdcall, importc, ogl.}
proc glGetShaderSourceARB*(shader: GLhandleARB, maxLength: GLsizei,
                           len: var GLsizei, source: PGLcharARB){.stdcall, importc, ogl.}
  # GL_ARB_Occlusion_Query
proc glGenQueriesARB*(n: GLsizei, ids: PGLuint){.stdcall, importc, ogl.}
proc glDeleteQueriesARB*(n: GLsizei, ids: PGLuint){.stdcall, importc, ogl.}
proc glIsQueryARB*(id: GLuint): bool{.stdcall, importc, ogl.}
proc glBeginQueryARB*(target: GLenum, id: GLuint){.stdcall, importc, ogl.}
proc glEndQueryARB*(target: GLenum){.stdcall, importc, ogl.}
proc glGetQueryivARB*(target, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetQueryObjectivARB*(id: GLuint, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetQueryObjectuivARB*(id: GLuint, pname: GLenum, params: PGLuint){.
    stdcall, importc, ogl.}
  # GL_ARB_draw_instanced
proc glDrawArraysInstancedARB*(mode: GLenum, first: GLint, count: GLsizei,
                               primcount: GLsizei){.stdcall, importc, ogl.}
proc glDrawElementsInstancedARB*(mode: GLenum, count: GLsizei, typ: GLenum,
                                 indices: PGLvoid, primcount: GLsizei){.stdcall, importc, ogl.}
  # GL_ARB_framebuffer_object
proc glIsRenderbuffer*(renderbuffer: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glBindRenderbuffer*(target: GLenum, renderbuffer: GLuint){.stdcall, importc, ogl.}
proc glDeleteRenderbuffers*(n: GLsizei, renderbuffers: PGLuint){.stdcall, importc, ogl.}
proc glGenRenderbuffers*(n: GLsizei, renderbuffers: PGLuint){.stdcall, importc, ogl.}
proc glRenderbufferStorage*(target: GLenum, internalformat: GLenum,
                            width: GLsizei, height: GLsizei){.stdcall, importc, ogl.}
proc glGetRenderbufferParameteriv*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glIsFramebuffer*(framebuffer: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glBindFramebuffer*(target: GLenum, framebuffer: GLuint){.stdcall, importc, ogl.}
proc glDeleteFramebuffers*(n: GLsizei, framebuffers: PGLuint){.stdcall, importc, ogl.}
proc glGenFramebuffers*(n: GLsizei, framebuffers: PGLuint){.stdcall, importc, ogl.}
proc glCheckFramebufferStatus*(target: GLenum): GLenum{.stdcall, importc, ogl.}
proc glFramebufferTexture1D*(target: GLenum, attachment: GLenum,
                             textarget: GLenum, texture: GLuint, level: GLint){.
    stdcall, importc, ogl.}
proc glFramebufferTexture2D*(target: GLenum, attachment: GLenum,
                             textarget: GLenum, texture: GLuint, level: GLint){.
    stdcall, importc, ogl.}
proc glFramebufferTexture3D*(target: GLenum, attachment: GLenum,
                             textarget: GLenum, texture: GLuint, level: GLint,
                             zoffset: GLint){.stdcall, importc, ogl.}
proc glFramebufferRenderbuffer*(target: GLenum, attachment: GLenum,
                                renderbuffertarget: GLenum, renderbuffer: GLuint){.
    stdcall, importc, ogl.}
proc glGetFramebufferAttachmentParameteriv*(target: GLenum, attachment: GLenum,
    pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGenerateMipmap*(target: GLenum){.stdcall, importc, ogl.}
proc glBlitFramebuffer*(srcX0: GLint, srcY0: GLint, srcX1: GLint, srcY1: GLint,
                        dstX0: GLint, dstY0: GLint, dstX1: GLint, dstY1: GLint,
                        mask: GLbitfield, filter: GLenum){.stdcall, importc, ogl.}
proc glRenderbufferStorageMultisample*(target: GLenum, samples: GLsizei,
                                       internalformat: GLenum, width: GLsizei,
                                       height: GLsizei){.stdcall, importc, ogl.}
proc glFramebufferTextureLayer*(target: GLenum, attachment: GLenum,
                                texture: GLuint, level: GLint, layer: GLint){.
    stdcall, importc, ogl.}
  # GL_ARB_geometry_shader4
proc glProgramParameteriARB*(prog: GLuint, pname: GLenum, value: GLint){.stdcall, importc, ogl.}
proc glFramebufferTextureARB*(target: GLenum, attachment: GLenum,
                              texture: GLuint, level: GLint){.stdcall, importc, ogl.}
proc glFramebufferTextureLayerARB*(target: GLenum, attachment: GLenum,
                                   texture: GLuint, level: GLint, layer: GLint){.
    stdcall, importc, ogl.}
proc glFramebufferTextureFaceARB*(target: GLenum, attachment: GLenum,
                                  texture: GLuint, level: GLint, face: GLenum){.
    stdcall, importc, ogl.}
  # GL_ARB_instanced_arrays
proc glVertexAttribDivisorARB*(index: GLuint, divisor: GLuint){.stdcall, importc, ogl.}
  # GL_ARB_map_buffer_range
proc glMapBufferRange*(target: GLenum, offset: GLintptr, len: GLsizeiptr,
                       access: GLbitfield): PGLvoid{.stdcall, importc, ogl.}
proc glFlushMappedBufferRange*(target: GLenum, offset: GLintptr, len: GLsizeiptr){.
    stdcall, importc, ogl.}
  # GL_ARB_texture_buffer_object
proc glTexBufferARB*(target: GLenum, internalformat: GLenum, buffer: GLuint){.
    stdcall, importc, ogl.}
  # GL_ARB_vertex_array_object
proc glBindVertexArray*(arr: GLuint){.stdcall, importc, ogl.}
proc glDeleteVertexArrays*(n: GLsizei, arrays: PGLuint){.stdcall, importc, ogl.}
proc glGenVertexArrays*(n: GLsizei, arrays: PGLuint){.stdcall, importc, ogl.}
proc glIsVertexArray*(arr: GLuint): GLboolean{.stdcall, importc, ogl.}
  # GL_ARB_uniform_buffer_object
proc glGetUniformIndices*(prog: GLuint, uniformCount: GLsizei,
                          uniformNames: cstringArray, uniformIndices: PGLuint){.
    stdcall, importc, ogl.}
proc glGetActiveUniformsiv*(prog: GLuint, uniformCount: GLsizei,
                            uniformIndices: PGLuint, pname: GLenum,
                            params: PGLint){.stdcall, importc, ogl.}
proc glGetActiveUniformName*(prog: GLuint, uniformIndex: GLuint,
                             bufSize: GLsizei, len: PGLsizei,
                             uniformName: PGLchar){.stdcall, importc, ogl.}
proc glGetUniformBlockIndex*(prog: GLuint, uniformBlockName: PGLchar): GLuint{.
    stdcall, importc, ogl.}
proc glGetActiveUniformBlockiv*(prog: GLuint, uniformBlockIndex: GLuint,
                                pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetActiveUniformBlockName*(prog: GLuint, uniformBlockIndex: GLuint,
                                  bufSize: GLsizei, len: PGLsizei,
                                  uniformBlockName: PGLchar){.stdcall, importc, ogl.}
proc glUniformBlockBinding*(prog: GLuint, uniformBlockIndex: GLuint,
                            uniformBlockBinding: GLuint){.stdcall, importc, ogl.}
  # GL_ARB_copy_buffer
proc glCopyBufferSubData*(readTarget: GLenum, writeTarget: GLenum,
                          readOffset: GLintptr, writeOffset: GLintptr,
                          size: GLsizeiptr){.stdcall, importc, ogl.}
  # GL_ARB_draw_elements_base_vertex
proc glDrawElementsBaseVertex*(mode: GLenum, count: GLsizei, typ: GLenum,
                               indices: PGLvoid, basevertex: GLint){.stdcall, importc, ogl.}
proc glDrawRangeElementsBaseVertex*(mode: GLenum, start: GLuint, ending: GLuint,
                                    count: GLsizei, typ: GLenum,
                                    indices: PGLvoid, basevertex: GLint){.
    stdcall, importc, ogl.}
proc glDrawElementsInstancedBaseVertex*(mode: GLenum, count: GLsizei,
                                        typ: GLenum, indices: PGLvoid,
                                        primcount: GLsizei, basevertex: GLint){.
    stdcall, importc, ogl.}
proc glMultiDrawElementsBaseVertex*(mode: GLenum, count: PGLsizei, typ: GLenum,
                                    indices: PPGLvoid, primcount: GLsizei,
                                    basevertex: PGLint){.stdcall, importc, ogl.}
  # GL_ARB_provoking_vertex
proc glProvokingVertex*(mode: GLenum){.stdcall, importc, ogl.}
  # GL_ARB_sync
proc glFenceSync*(condition: GLenum, flags: GLbitfield): GLsync{.stdcall, importc, ogl.}
proc glIsSync*(sync: GLsync): GLboolean{.stdcall, importc, ogl.}
proc glDeleteSync*(sync: GLsync){.stdcall, importc, ogl.}
proc glClientWaitSync*(sync: GLsync, flags: GLbitfield, timeout: GLuint64): GLenum{.
    stdcall, importc, ogl.}
proc glWaitSync*(sync: GLsync, flags: GLbitfield, timeout: GLuint64){.stdcall, importc, ogl.}
proc glGetInteger64v*(pname: GLenum, params: PGLint64){.stdcall, importc, ogl.}
proc glGetSynciv*(sync: GLsync, pname: GLenum, butSize: GLsizei, len: PGLsizei,
                  values: PGLint){.stdcall, importc, ogl.}
  # GL_ARB_texture_multisample
proc glTexImage2DMultisample*(target: GLenum, samples: GLsizei,
                              internalformat: GLint, width: GLsizei,
                              height: GLsizei, fixedsamplelocations: GLboolean){.
    stdcall, importc, ogl.}
proc glTexImage3DMultisample*(target: GLenum, samples: GLsizei,
                              internalformat: GLint, width: GLsizei,
                              height: GLsizei, depth: GLsizei,
                              fixedsamplelocations: GLboolean){.stdcall, importc, ogl.}
proc glGetMultisamplefv*(pname: GLenum, index: GLuint, val: PGLfloat){.stdcall, importc, ogl.}
proc glSampleMaski*(index: GLuint, mask: GLbitfield){.stdcall, importc, ogl.}
  # GL_ARB_draw_buffers_blend
proc glBlendEquationiARB*(buf: GLuint, mode: GLenum){.stdcall, importc, ogl.}
proc glBlendEquationSeparateiARB*(buf: GLuint, modeRGB: GLenum,
                                  modeAlpha: GLenum){.stdcall, importc, ogl.}
proc glBlendFunciARB*(buf: GLuint, src: GLenum, dst: GLenum){.stdcall, importc, ogl.}
proc glBlendFuncSeparateiARB*(buf: GLuint, srcRGB: GLenum, dstRGB: GLenum,
                              srcAlpha: GLenum, dstAlpha: GLenum){.stdcall, importc, ogl.}
  # GL_ARB_sample_shading
proc glMinSampleShadingARB*(value: GLclampf){.stdcall, importc, ogl.}
  # GL_ARB_shading_language_include
proc glNamedStringARB*(typ: GLenum, namelen: GLint, name: PGLchar,
                       stringlen: GLint, string: PGLchar){.stdcall, importc, ogl.}
proc glDeleteNamedStringARB*(namelen: GLint, name: PGLchar){.stdcall, importc, ogl.}
proc glCompileShaderIncludeARB*(shader: GLuint, count: GLsizei, path: PPGLchar,
                                len: PGLint){.stdcall, importc, ogl.}
proc glIsNamedStringARB*(namelen: GLint, name: PGLchar): GLboolean{.stdcall, importc, ogl.}
proc glGetNamedStringARB*(namelen: GLint, name: PGLchar, bufSize: GLsizei,
                          stringlen: GLint, string: PGLchar){.stdcall, importc, ogl.}
proc glGetNamedStringivARB*(namelen: GLint, name: PGLchar, pname: GLenum,
                            params: PGLint){.stdcall, importc, ogl.}
  # GL_ARB_blend_func_extended
proc glBindFragDataLocationIndexed*(prog: GLuint, colorNumber: GLuint,
                                    index: GLuint, name: PGLchar){.stdcall, importc, ogl.}
proc glGetFragDataIndex*(prog: GLuint, name: PGLchar): GLint{.stdcall, importc, ogl.}
  # GL_ARB_sampler_objects
proc glGenSamplers*(count: GLsizei, samplers: PGLuint){.stdcall, importc, ogl.}
proc glDeleteSamplers*(count: GLsizei, samplers: PGLuint){.stdcall, importc, ogl.}
proc glIsSampler*(sampler: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glBindSampler*(theUnit: GLuint, sampler: GLuint){.stdcall, importc, ogl.}
proc glSamplerParameteri*(sampler: GLuint, pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glSamplerParameteriv*(sampler: GLuint, pname: GLenum, param: PGLint){.
    stdcall, importc, ogl.}
proc glSamplerParameterf*(sampler: GLuint, pname: GLenum, param: GLfloat){.
    stdcall, importc, ogl.}
proc glSamplerParameterfv*(sampler: GLuint, pname: GLenum, param: PGLfloat){.
    stdcall, importc, ogl.}
proc glSamplerParameterIiv*(sampler: GLuint, pname: GLenum, param: PGLint){.
    stdcall, importc, ogl.}
proc glSamplerParameterIuiv*(sampler: GLuint, pname: GLenum, param: PGLuint){.
    stdcall, importc, ogl.}
proc glGetSamplerParameteriv*(sampler: GLuint, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetSamplerParameterIiv*(sampler: GLuint, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetSamplerParameterfv*(sampler: GLuint, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetSamplerParameterIuiv*(sampler: GLuint, pname: GLenum, params: PGLuint){.
    stdcall, importc, ogl.}
  # GL_ARB_timer_query
proc glQueryCounter*(id: GLuint, target: GLenum){.stdcall, importc, ogl.}
proc glGetQueryObjecti64v*(id: GLuint, pname: GLenum, params: PGLint64){.stdcall, importc, ogl.}
proc glGetQueryObjectui64v*(id: GLuint, pname: GLenum, params: PGLuint64){.
    stdcall, importc, ogl.}
  # GL_ARB_vertextyp_2_10_10_10_rev
proc glVertexP2ui*(typ: GLenum, value: GLuint){.stdcall, importc, ogl.}
proc glVertexP2uiv*(typ: GLenum, value: PGLuint){.stdcall, importc, ogl.}
proc glVertexP3ui*(typ: GLenum, value: GLuint){.stdcall, importc, ogl.}
proc glVertexP3uiv*(typ: GLenum, value: PGLuint){.stdcall, importc, ogl.}
proc glVertexP4ui*(typ: GLenum, value: GLuint){.stdcall, importc, ogl.}
proc glVertexP4uiv*(typ: GLenum, value: PGLuint){.stdcall, importc, ogl.}
proc glTexCoordP1ui*(typ: GLenum, coords: GLuint){.stdcall, importc, ogl.}
proc glTexCoordP1uiv*(typ: GLenum, coords: PGLuint){.stdcall, importc, ogl.}
proc glTexCoordP2ui*(typ: GLenum, coords: GLuint){.stdcall, importc, ogl.}
proc glTexCoordP2uiv*(typ: GLenum, coords: PGLuint){.stdcall, importc, ogl.}
proc glTexCoordP3ui*(typ: GLenum, coords: GLuint){.stdcall, importc, ogl.}
proc glTexCoordP3uiv*(typ: GLenum, coords: PGLuint){.stdcall, importc, ogl.}
proc glTexCoordP4ui*(typ: GLenum, coords: GLuint){.stdcall, importc, ogl.}
proc glTexCoordP4uiv*(typ: GLenum, coords: PGLuint){.stdcall, importc, ogl.}
proc glMultiTexCoordP1ui*(texture: GLenum, typ: GLenum, coords: GLuint){.stdcall, importc, ogl.}
proc glMultiTexCoordP1uiv*(texture: GLenum, typ: GLenum, coords: GLuint){.
    stdcall, importc, ogl.}
proc glMultiTexCoordP2ui*(texture: GLenum, typ: GLenum, coords: GLuint){.stdcall, importc, ogl.}
proc glMultiTexCoordP2uiv*(texture: GLenum, typ: GLenum, coords: PGLuint){.
    stdcall, importc, ogl.}
proc glMultiTexCoordP3ui*(texture: GLenum, typ: GLenum, coords: GLuint){.stdcall, importc, ogl.}
proc glMultiTexCoordP3uiv*(texture: GLenum, typ: GLenum, coords: PGLuint){.
    stdcall, importc, ogl.}
proc glMultiTexCoordP4ui*(texture: GLenum, typ: GLenum, coords: GLuint){.stdcall, importc, ogl.}
proc glMultiTexCoordP4uiv*(texture: GLenum, typ: GLenum, coords: PGLuint){.
    stdcall, importc, ogl.}
proc glNormalP3ui*(typ: GLenum, coords: GLuint){.stdcall, importc, ogl.}
proc glNormalP3uiv*(typ: GLenum, coords: PGLuint){.stdcall, importc, ogl.}
proc glColorP3ui*(typ: GLenum, color: GLuint){.stdcall, importc, ogl.}
proc glColorP3uiv*(typ: GLenum, color: PGLuint){.stdcall, importc, ogl.}
proc glColorP4ui*(typ: GLenum, color: GLuint){.stdcall, importc, ogl.}
proc glColorP4uiv*(typ: GLenum, color: GLuint){.stdcall, importc, ogl.}
proc glSecondaryColorP3ui*(typ: GLenum, color: GLuint){.stdcall, importc, ogl.}
proc glSecondaryColorP3uiv*(typ: GLenum, color: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttribP1ui*(index: GLuint, typ: GLenum, normalized: GLboolean,
                         value: GLuint){.stdcall, importc, ogl.}
proc glVertexAttribP1uiv*(index: GLuint, typ: GLenum, normalized: GLboolean,
                          value: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttribP2ui*(index: GLuint, typ: GLenum, normalized: GLboolean,
                         value: GLuint){.stdcall, importc, ogl.}
proc glVertexAttribP2uiv*(index: GLuint, typ: GLenum, normalized: GLboolean,
                          value: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttribP3ui*(index: GLuint, typ: GLenum, normalized: GLboolean,
                         value: GLuint){.stdcall, importc, ogl.}
proc glVertexAttribP3uiv*(index: GLuint, typ: GLenum, normalized: GLboolean,
                          value: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttribP4ui*(index: GLuint, typ: GLenum, normalized: GLboolean,
                         value: GLuint){.stdcall, importc, ogl.}
proc glVertexAttribP4uiv*(index: GLuint, typ: GLenum, normalized: GLboolean,
                          value: PGLuint){.stdcall, importc, ogl.}
  # GL_ARB_draw_indirect
proc glDrawArraysIndirect*(mode: GLenum, indirect: PGLvoid){.stdcall, importc, ogl.}
proc glDrawElementsIndirect*(mode: GLenum, typ: GLenum, indirect: PGLvoid){.
    stdcall, importc, ogl.}
  # GL_ARB_gpu_shader_fp64
proc glUniform1d*(location: GLint, x: GLdouble){.stdcall, importc, ogl.}
proc glUniform2d*(location: GLint, x: GLdouble, y: GLdouble){.stdcall, importc, ogl.}
proc glUniform3d*(location: GLint, x: GLdouble, y: GLdouble, z: GLdouble){.
    stdcall, importc, ogl.}
proc glUniform4d*(location: GLint, x: GLdouble, y: GLdouble, z: GLdouble,
                  w: GLdouble){.stdcall, importc, ogl.}
proc glUniform1dv*(location: GLint, count: GLsizei, value: PGLdouble){.stdcall, importc, ogl.}
proc glUniform2dv*(location: GLint, count: GLsizei, value: PGLdouble){.stdcall, importc, ogl.}
proc glUniform3dv*(location: GLint, count: GLsizei, value: PGLdouble){.stdcall, importc, ogl.}
proc glUniform4dv*(location: GLint, count: GLsizei, value: PGLdouble){.stdcall, importc, ogl.}
proc glUniformMatrix2dv*(location: GLint, count: GLsizei, transpose: GLboolean,
                         value: PGLdouble){.stdcall, importc, ogl.}
proc glUniformMatrix3dv*(location: GLint, count: GLsizei, transpose: GLboolean,
                         value: PGLdouble){.stdcall, importc, ogl.}
proc glUniformMatrix4dv*(location: GLint, count: GLsizei, transpose: GLboolean,
                         value: PGLdouble){.stdcall, importc, ogl.}
proc glUniformMatrix2x3dv*(location: GLint, count: GLsizei,
                           transpose: GLboolean, value: PGLdouble){.stdcall, importc, ogl.}
proc glUniformMatrix2x4dv*(location: GLint, count: GLsizei,
                           transpose: GLboolean, value: PGLdouble){.stdcall, importc, ogl.}
proc glUniformMatrix3x2dv*(location: GLint, count: GLsizei,
                           transpose: GLboolean, value: PGLdouble){.stdcall, importc, ogl.}
proc glUniformMatrix3x4dv*(location: GLint, count: GLsizei,
                           transpose: GLboolean, value: PGLdouble){.stdcall, importc, ogl.}
proc glUniformMatrix4x2dv*(location: GLint, count: GLsizei,
                           transpose: GLboolean, value: PGLdouble){.stdcall, importc, ogl.}
proc glUniformMatrix4x3dv*(location: GLint, count: GLsizei,
                           transpose: GLboolean, value: PGLdouble){.stdcall, importc, ogl.}
proc glGetUniformdv*(prog: GLuint, location: GLint, params: PGLdouble){.stdcall, importc, ogl.}
  # GL_ARB_shader_subroutine
proc glGetSubroutineUniformLocation*(prog: GLuint, shadertype: GLenum,
                                     name: PGLchar): GLint{.stdcall, importc, ogl.}
proc glGetSubroutineIndex*(prog: GLuint, shadertype: GLenum, name: PGLchar): GLuint{.
    stdcall, importc, ogl.}
proc glGetActiveSubroutineUniformiv*(prog: GLuint, shadertype: GLenum,
                                     index: GLuint, pname: GLenum,
                                     values: PGLint){.stdcall, importc, ogl.}
proc glGetActiveSubroutineUniformName*(prog: GLuint, shadertype: GLenum,
                                       index: GLuint, bufsize: GLsizei,
                                       len: PGLsizei, name: PGLchar){.stdcall, importc, ogl.}
proc glGetActiveSubroutineName*(prog: GLuint, shadertype: GLenum, index: GLuint,
                                bufsize: GLsizei, len: PGLsizei, name: PGLchar){.
    stdcall, importc, ogl.}
proc glUniformSubroutinesuiv*(shadertype: GLenum, count: GLsizei,
                              indices: PGLuint){.stdcall, importc, ogl.}
proc glGetUniformSubroutineuiv*(shadertype: GLenum, location: GLint,
                                params: PGLuint){.stdcall, importc, ogl.}
proc glGetProgramStageiv*(prog: GLuint, shadertype: GLenum, pname: GLenum,
                          values: PGLint){.stdcall, importc, ogl.}
  # GL_ARB_tessellation_shader
proc glPatchParameteri*(pname: GLenum, value: GLint){.stdcall, importc, ogl.}
proc glPatchParameterfv*(pname: GLenum, values: PGLfloat){.stdcall, importc, ogl.}
  # GL_ARB_transform_feedback2
proc glBindTransformFeedback*(target: GLenum, id: GLuint){.stdcall, importc, ogl.}
proc glDeleteTransformFeedbacks*(n: GLsizei, ids: PGLuint){.stdcall, importc, ogl.}
proc glGenTransformFeedbacks*(n: GLsizei, ids: PGLuint){.stdcall, importc, ogl.}
proc glIsTransformFeedback*(id: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glPauseTransformFeedback*(){.stdcall, importc, ogl.}
proc glResumeTransformFeedback*(){.stdcall, importc, ogl.}
proc glDrawTransformFeedback*(mode: GLenum, id: GLuint){.stdcall, importc, ogl.}
  # GL_ARB_transform_feedback3
proc glDrawTransformFeedbackStream*(mode: GLenum, id: GLuint, stream: GLuint){.
    stdcall, importc, ogl.}
proc glBeginQueryIndexed*(target: GLenum, index: GLuint, id: GLuint){.stdcall, importc, ogl.}
proc glEndQueryIndexed*(target: GLenum, index: GLuint){.stdcall, importc, ogl.}
proc glGetQueryIndexediv*(target: GLenum, index: GLuint, pname: GLenum,
                          params: PGLint){.stdcall, importc, ogl.}
  # GL_ARB_ES2_compatibility
proc glReleaseShaderCompiler*(){.stdcall, importc, ogl.}
proc glShaderBinary*(count: GLsizei, shaders: PGLuint, binaryformat: GLenum,
                     binary: PGLvoid, len: GLsizei){.stdcall, importc, ogl.}
proc glGetShaderPrecisionFormat*(shadertype: GLenum, precisiontype: GLenum,
                                 range: PGLint, precision: PGLint){.stdcall, importc, ogl.}
proc glDepthRangef*(n: GLclampf, f: GLclampf){.stdcall, importc, ogl.}
proc glClearDepthf*(d: GLclampf){.stdcall, importc, ogl.}
  # GL_ARB_get_prog_binary
proc glGetProgramBinary*(prog: GLuint, bufSize: GLsizei, len: PGLsizei,
                         binaryFormat: PGLenum, binary: PGLvoid){.stdcall, importc, ogl.}
proc glProgramBinary*(prog: GLuint, binaryFormat: GLenum, binary: PGLvoid,
                      len: GLsizei){.stdcall, importc, ogl.}
proc glProgramParameteri*(prog: GLuint, pname: GLenum, value: GLint){.stdcall, importc, ogl.}
  # GL_ARB_separate_shader_objects
proc glUseProgramStages*(pipeline: GLuint, stages: GLbitfield, prog: GLuint){.
    stdcall, importc, ogl.}
proc glActiveShaderProgram*(pipeline: GLuint, prog: GLuint){.stdcall, importc, ogl.}
proc glCreateShaderProgramv*(typ: GLenum, count: GLsizei, strings: cstringArray): GLuint{.
    stdcall, importc, ogl.}
proc glBindProgramPipeline*(pipeline: GLuint){.stdcall, importc, ogl.}
proc glDeleteProgramPipelines*(n: GLsizei, pipelines: PGLuint){.stdcall, importc, ogl.}
proc glGenProgramPipelines*(n: GLsizei, pipelines: PGLuint){.stdcall, importc, ogl.}
proc glIsProgramPipeline*(pipeline: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glGetProgramPipelineiv*(pipeline: GLuint, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glProgramUniform1i*(prog: GLuint, location: GLint, v0: GLint){.stdcall, importc, ogl.}
proc glProgramUniform1iv*(prog: GLuint, location: GLint, count: GLsizei,
                          value: PGLint){.stdcall, importc, ogl.}
proc glProgramUniform1f*(prog: GLuint, location: GLint, v0: GLfloat){.stdcall, importc, ogl.}
proc glProgramUniform1fv*(prog: GLuint, location: GLint, count: GLsizei,
                          value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniform1d*(prog: GLuint, location: GLint, v0: GLdouble){.stdcall, importc, ogl.}
proc glProgramUniform1dv*(prog: GLuint, location: GLint, count: GLsizei,
                          value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniform1ui*(prog: GLuint, location: GLint, v0: GLuint){.stdcall, importc, ogl.}
proc glProgramUniform1uiv*(prog: GLuint, location: GLint, count: GLsizei,
                           value: PGLuint){.stdcall, importc, ogl.}
proc glProgramUniform2i*(prog: GLuint, location: GLint, v0: GLint, v1: GLint){.
    stdcall, importc, ogl.}
proc glProgramUniform2iv*(prog: GLuint, location: GLint, count: GLsizei,
                          value: PGLint){.stdcall, importc, ogl.}
proc glProgramUniform2f*(prog: GLuint, location: GLint, v0: GLfloat, v1: GLfloat){.
    stdcall, importc, ogl.}
proc glProgramUniform2fv*(prog: GLuint, location: GLint, count: GLsizei,
                          value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniform2d*(prog: GLuint, location: GLint, v0: GLdouble,
                         v1: GLdouble){.stdcall, importc, ogl.}
proc glProgramUniform2dv*(prog: GLuint, location: GLint, count: GLsizei,
                          value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniform2ui*(prog: GLuint, location: GLint, v0: GLuint, v1: GLuint){.
    stdcall, importc, ogl.}
proc glProgramUniform2uiv*(prog: GLuint, location: GLint, count: GLsizei,
                           value: PGLuint){.stdcall, importc, ogl.}
proc glProgramUniform3i*(prog: GLuint, location: GLint, v0: GLint, v1: GLint,
                         v2: GLint){.stdcall, importc, ogl.}
proc glProgramUniform3iv*(prog: GLuint, location: GLint, count: GLsizei,
                          value: PGLint){.stdcall, importc, ogl.}
proc glProgramUniform3f*(prog: GLuint, location: GLint, v0: GLfloat,
                         v1: GLfloat, v2: GLfloat){.stdcall, importc, ogl.}
proc glProgramUniform3fv*(prog: GLuint, location: GLint, count: GLsizei,
                          value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniform3d*(prog: GLuint, location: GLint, v0: GLdouble,
                         v1: GLdouble, v2: GLdouble){.stdcall, importc, ogl.}
proc glProgramUniform3dv*(prog: GLuint, location: GLint, count: GLsizei,
                          value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniform3ui*(prog: GLuint, location: GLint, v0: GLuint, v1: GLuint,
                          v2: GLuint){.stdcall, importc, ogl.}
proc glProgramUniform3uiv*(prog: GLuint, location: GLint, count: GLsizei,
                           value: PGLuint){.stdcall, importc, ogl.}
proc glProgramUniform4i*(prog: GLuint, location: GLint, v0: GLint, v1: GLint,
                         v2: GLint, v3: GLint){.stdcall, importc, ogl.}
proc glProgramUniform4iv*(prog: GLuint, location: GLint, count: GLsizei,
                          value: PGLint){.stdcall, importc, ogl.}
proc glProgramUniform4f*(prog: GLuint, location: GLint, v0: GLfloat,
                         v1: GLfloat, v2: GLfloat, v3: GLfloat){.stdcall, importc, ogl.}
proc glProgramUniform4fv*(prog: GLuint, location: GLint, count: GLsizei,
                          value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniform4d*(prog: GLuint, location: GLint, v0: GLdouble,
                         v1: GLdouble, v2: GLdouble, v3: GLdouble){.stdcall, importc, ogl.}
proc glProgramUniform4dv*(prog: GLuint, location: GLint, count: GLsizei,
                          value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniform4ui*(prog: GLuint, location: GLint, v0: GLuint, v1: GLuint,
                          v2: GLuint, v3: GLuint){.stdcall, importc, ogl.}
proc glProgramUniform4uiv*(prog: GLuint, location: GLint, count: GLsizei,
                           value: PGLuint){.stdcall, importc, ogl.}
proc glProgramUniformMatrix2fv*(prog: GLuint, location: GLint, count: GLsizei,
                                transpose: GLboolean, value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniformMatrix3fv*(prog: GLuint, location: GLint, count: GLsizei,
                                transpose: GLboolean, value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniformMatrix4fv*(prog: GLuint, location: GLint, count: GLsizei,
                                transpose: GLboolean, value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniformMatrix2dv*(prog: GLuint, location: GLint, count: GLsizei,
                                transpose: GLboolean, value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniformMatrix3dv*(prog: GLuint, location: GLint, count: GLsizei,
                                transpose: GLboolean, value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniformMatrix4dv*(prog: GLuint, location: GLint, count: GLsizei,
                                transpose: GLboolean, value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniformMatrix2x3fv*(prog: GLuint, location: GLint, count: GLsizei,
                                  transpose: GLboolean, value: PGLfloat){.
    stdcall, importc, ogl.}
proc glProgramUniformMatrix3x2fv*(prog: GLuint, location: GLint, count: GLsizei,
                                  transpose: GLboolean, value: PGLfloat){.
    stdcall, importc, ogl.}
proc glProgramUniformMatrix2x4fv*(prog: GLuint, location: GLint, count: GLsizei,
                                  transpose: GLboolean, value: PGLfloat){.
    stdcall, importc, ogl.}
proc glProgramUniformMatrix4x2fv*(prog: GLuint, location: GLint, count: GLsizei,
                                  transpose: GLboolean, value: PGLfloat){.
    stdcall, importc, ogl.}
proc glProgramUniformMatrix3x4fv*(prog: GLuint, location: GLint, count: GLsizei,
                                  transpose: GLboolean, value: PGLfloat){.
    stdcall, importc, ogl.}
proc glProgramUniformMatrix4x3fv*(prog: GLuint, location: GLint, count: GLsizei,
                                  transpose: GLboolean, value: PGLfloat){.
    stdcall, importc, ogl.}
proc glProgramUniformMatrix2x3dv*(prog: GLuint, location: GLint, count: GLsizei,
                                  transpose: GLboolean, value: PGLdouble){.
    stdcall, importc, ogl.}
proc glProgramUniformMatrix3x2dv*(prog: GLuint, location: GLint, count: GLsizei,
                                  transpose: GLboolean, value: PGLdouble){.
    stdcall, importc, ogl.}
proc glProgramUniformMatrix2x4dv*(prog: GLuint, location: GLint, count: GLsizei,
                                  transpose: GLboolean, value: PGLdouble){.
    stdcall, importc, ogl.}
proc glProgramUniformMatrix4x2dv*(prog: GLuint, location: GLint, count: GLsizei,
                                  transpose: GLboolean, value: PGLdouble){.
    stdcall, importc, ogl.}
proc glProgramUniformMatrix3x4dv*(prog: GLuint, location: GLint, count: GLsizei,
                                  transpose: GLboolean, value: PGLdouble){.
    stdcall, importc, ogl.}
proc glProgramUniformMatrix4x3dv*(prog: GLuint, location: GLint, count: GLsizei,
                                  transpose: GLboolean, value: PGLdouble){.
    stdcall, importc, ogl.}
proc glValidateProgramPipeline*(pipeline: GLuint){.stdcall, importc, ogl.}
proc glGetProgramPipelineInfoLog*(pipeline: GLuint, bufSize: GLsizei,
                                  len: PGLsizei, infoLog: PGLchar){.stdcall, importc, ogl.}
  # GL_ARB_vertex_attrib_64bit
proc glVertexAttribL1d*(index: GLuint, x: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttribL2d*(index: GLuint, x: GLdouble, y: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttribL3d*(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble){.
    stdcall, importc, ogl.}
proc glVertexAttribL4d*(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble,
                        w: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttribL1dv*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttribL2dv*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttribL3dv*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttribL4dv*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttribLPointer*(index: GLuint, size: GLint, typ: GLenum,
                             stride: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glGetVertexAttribLdv*(index: GLuint, pname: GLenum, params: PGLdouble){.
    stdcall, importc, ogl.}
  # GL_ARB_viewport_array
proc glViewportArrayv*(first: GLuint, count: GLsizei, v: PGLfloat){.stdcall, importc, ogl.}
proc glViewportIndexedf*(index: GLuint, x: GLfloat, y: GLfloat, w: GLfloat,
                         h: GLfloat){.stdcall, importc, ogl.}
proc glViewportIndexedfv*(index: GLuint, v: PGLfloat){.stdcall, importc, ogl.}
proc glScissorArrayv*(first: GLuint, count: GLsizei, v: PGLint){.stdcall, importc, ogl.}
proc glScissorIndexed*(index: GLuint, left: GLint, bottom: GLint,
                       width: GLsizei, height: GLsizei){.stdcall, importc, ogl.}
proc glScissorIndexedv*(index: GLuint, v: PGLint){.stdcall, importc, ogl.}
proc glDepthRangeArrayv*(first: GLuint, count: GLsizei, v: PGLclampd){.stdcall, importc, ogl.}
proc glDepthRangeIndexed*(index: GLuint, n: GLclampd, f: GLclampd){.stdcall, importc, ogl.}
proc glGetFloati_v*(target: GLenum, index: GLuint, data: PGLfloat){.stdcall, importc, ogl.}
proc glGetDoublei_v*(target: GLenum, index: GLuint, data: PGLdouble){.stdcall, importc, ogl.}
  # GL 4.2
  # GL_ARB_base_instance
proc glDrawArraysInstancedBaseInstance*(mode: GLenum, first: GLint,
                                        count: GLsizei, primcount: GLsizei,
                                        baseinstance: GLUint){.stdcall, importc, ogl.}
proc glDrawElementsInstancedBaseInstance*(mode: GLEnum, count: GLsizei,
    typ: GLenum, indices: PGLVoid, primcount: GLsizei, baseinstance: GLUInt){.
    stdcall, importc, ogl.}
proc glDrawElementsInstancedBaseVertexBaseInstance*(mode: GLEnum,
    count: GLsizei, typ: GLenum, indices: PGLVoid, primcount: GLsizei,
    basevertex: GLint, baseinstance: GLuint){.stdcall, importc, ogl.}
  # GL_ARB_transform_feedback_instanced
proc glDrawTransformFeedbackInstanced*(mode: GLenum, id: GLuint,
                                       primcount: GLsizei){.stdcall, importc, ogl.}
proc glDrawTransformFeedbackStreamInstanced*(mode: GLenum, id: GLUInt,
    stream: GLUint, primcount: GLsizei){.stdcall, importc, ogl.}
  # GL_ARB_internalformat_query
proc glGetInternalformativ*(target: GLenum, internalformat: GLenum,
                            pname: GLenum, bufSize: GLsizei, params: PGLint){.
    stdcall, importc, ogl.}
  # GL_ARB_shader_atomic_counters
proc glGetActiveAtomicCounterBufferiv*(prog: GLuint, bufferIndex: GLuint,
                                       pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
  #/ GL_ARB_shader_image_load_store
proc glBindImageTexture*(theUnit: GLuint, texture: GLuint, level: GLint,
                         layered: GLboolean, layer: GLint, access: GLenum,
                         format: GLenum){.stdcall, importc, ogl.}
proc glMemoryBarrier*(barriers: GLbitfield){.stdcall, importc, ogl.}
  # GL_ARB_texture_storage
proc glTexStorage1D*(target: GLenum, levels: GLsizei, internalformat: GLenum,
                     width: GLsizei){.stdcall, importc, ogl.}
proc glTexStorage2D*(target: GLenum, levels: GLsizei, internalformat: GLenum,
                     width: GLsizei, height: GLsizei){.stdcall, importc, ogl.}
proc glTexStorage3D*(target: GLenum, levels: GLsizei, internalformat: GLenum,
                     width: GLsizei, height: GLsizei, depth: GLsizei){.stdcall, importc, ogl.}
proc glTextureStorage1DEXT*(texture: GLuint, target: GLenum, levels: GLsizei,
                            internalformat: GLenum, width: GLsizei){.stdcall, importc, ogl.}
proc glTextureStorage2DEXT*(texture: GLuint, target: GLenum, levels: GLsizei,
                            internalformat: GLenum, width: GLsizei,
                            height: GLsizei){.stdcall, importc, ogl.}
proc glTextureStorage3DEXT*(texture: GLuint, target: GLenum, levels: GLsizei,
                            internalformat: GLenum, width: GLsizei,
                            height: GLsizei, depth: GLsizei){.stdcall, importc, ogl.}
  #
  # GL_ARB_cl_event
proc glCreateSyncFromCLeventARB*(context: p_cl_context, event: p_cl_event,
                                 flags: GLbitfield): GLsync{.stdcall, importc, ogl.}
  # GL_ARB_debug_output
proc glDebugMessageControlARB*(source: GLenum, typ: GLenum, severity: GLenum,
                               count: GLsizei, ids: PGLuint, enabled: GLboolean){.
    stdcall, importc, ogl.}
proc glDebugMessageInsertARB*(source: GLenum, typ: GLenum, id: GLuint,
                              severity: GLenum, len: GLsizei, buf: PGLchar){.
    stdcall, importc, ogl.}
proc glDebugMessageCallbackARB*(callback: TglDebugProcARB, userParam: PGLvoid){.
    stdcall, importc, ogl.}
proc glGetDebugMessageLogARB*(count: GLuint, bufsize: GLsizei, sources: PGLenum,
                              types: PGLenum, ids: PGLuint, severities: PGLenum,
                              lengths: PGLsizei, messageLog: PGLchar): GLuint{.
    stdcall, importc, ogl.}
  # GL_ARB_robustness
proc glGetGraphicsResetStatusARB*(): GLenum{.stdcall, importc, ogl.}
proc glGetnMapdvARB*(target: GLenum, query: GLenum, bufSize: GLsizei,
                     v: PGLdouble){.stdcall, importc, ogl.}
proc glGetnMapfvARB*(target: GLenum, query: GLenum, bufSize: GLsizei,
                     v: PGLfloat){.stdcall, importc, ogl.}
proc glGetnMapivARB*(target: GLenum, query: GLenum, bufSize: GLsizei, v: PGLint){.
    stdcall, importc, ogl.}
proc glGetnPixelMapfvARB*(map: GLenum, bufSize: GLsizei, values: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetnPixelMapuivARB*(map: GLenum, bufSize: GLsizei, values: PGLuint){.
    stdcall, importc, ogl.}
proc glGetnPixelMapusvARB*(map: GLenum, bufSize: GLsizei, values: PGLushort){.
    stdcall, importc, ogl.}
proc glGetnPolygonStippleARB*(bufSize: GLsizei, pattern: PGLubyte){.stdcall, importc, ogl.}
proc glGetnColorTableARB*(target: GLenum, format: GLenum, typ: GLenum,
                          bufSize: GLsizei, table: PGLvoid){.stdcall, importc, ogl.}
proc glGetnConvolutionFilterARB*(target: GLenum, format: GLenum, typ: GLenum,
                                 bufSize: GLsizei, image: PGLvoid){.stdcall, importc, ogl.}
proc glGetnSeparableFilterARB*(target: GLenum, format: GLenum, typ: GLenum,
                               rowBufSize: GLsizei, row: PGLvoid,
                               columnBufSize: GLsizei, column: PGLvoid,
                               span: PGLvoid){.stdcall, importc, ogl.}
proc glGetnHistogramARB*(target: GLenum, reset: GLboolean, format: GLenum,
                         typ: GLenum, bufSize: GLsizei, values: PGLvoid){.
    stdcall, importc, ogl.}
proc glGetnMinmaxARB*(target: GLenum, reset: GLboolean, format: GLenum,
                      typ: GLenum, bufSize: GLsizei, values: PGLvoid){.stdcall, importc, ogl.}
proc glGetnTexImageARB*(target: GLenum, level: GLint, format: GLenum,
                        typ: GLenum, bufSize: GLsizei, img: PGLvoid){.stdcall, importc, ogl.}
proc glReadnPixelsARB*(x: GLint, y: GLint, width: GLsizei, height: GLsizei,
                       format: GLenum, typ: GLenum, bufSize: GLsizei,
                       data: PGLvoid){.stdcall, importc, ogl.}
proc glGetnCompressedTexImageARB*(target: GLenum, lod: GLint, bufSize: GLsizei,
                                  img: PGLvoid){.stdcall, importc, ogl.}
proc glGetnUniformfvARB*(prog: GLuint, location: GLint, bufSize: GLsizei,
                         params: PGLfloat){.stdcall, importc, ogl.}
proc glGetnUniformivARB*(prog: GLuint, location: GLint, bufSize: GLsizei,
                         params: PGLint){.stdcall, importc, ogl.}
proc glGetnUniformuivARB*(prog: GLuint, location: GLint, bufSize: GLsizei,
                          params: PGLuint){.stdcall, importc, ogl.}
proc glGetnUniformdvARB*(prog: GLuint, location: GLint, bufSize: GLsizei,
                         params: PGLdouble){.stdcall, importc, ogl.}
  # GL_ATI_draw_buffers
proc glDrawBuffersATI*(n: GLsizei, bufs: PGLenum){.stdcall, importc, ogl.}
  # GL_ATI_element_array
proc glElementPointerATI*(typ: GLenum, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glDrawElementArrayATI*(mode: GLenum, count: GLsizei){.stdcall, importc, ogl.}
proc glDrawRangeElementArrayATI*(mode: GLenum, start: GLuint, ending: GLuint,
                                 count: GLsizei){.stdcall, importc, ogl.}
  # GL_ATI_envmap_bumpmap
proc glTexBumpParameterivATI*(pname: GLenum, param: PGLint){.stdcall, importc, ogl.}
proc glTexBumpParameterfvATI*(pname: GLenum, param: PGLfloat){.stdcall, importc, ogl.}
proc glGetTexBumpParameterivATI*(pname: GLenum, param: PGLint){.stdcall, importc, ogl.}
proc glGetTexBumpParameterfvATI*(pname: GLenum, param: PGLfloat){.stdcall, importc, ogl.}
  # GL_ATI_fragment_shader
proc glGenFragmentShadersATI*(range: GLuint): GLuint{.stdcall, importc, ogl.}
proc glBindFragmentShaderATI*(id: GLuint){.stdcall, importc, ogl.}
proc glDeleteFragmentShaderATI*(id: GLuint){.stdcall, importc, ogl.}
proc glBeginFragmentShaderATI*(){.stdcall, importc, ogl.}
proc glEndFragmentShaderATI*(){.stdcall, importc, ogl.}
proc glPassTexCoordATI*(dst: GLuint, coord: GLuint, swizzle: GLenum){.stdcall, importc, ogl.}
proc glSampleMapATI*(dst: GLuint, interp: GLuint, swizzle: GLenum){.stdcall, importc, ogl.}
proc glColorFragmentOp1ATI*(op: GLenum, dst: GLuint, dstMask: GLuint,
                            dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint,
                            arg1Mod: GLuint){.stdcall, importc, ogl.}
proc glColorFragmentOp2ATI*(op: GLenum, dst: GLuint, dstMask: GLuint,
                            dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint,
                            arg1Mod: GLuint, arg2: GLuint, arg2Rep: GLuint,
                            arg2Mod: GLuint){.stdcall, importc, ogl.}
proc glColorFragmentOp3ATI*(op: GLenum, dst: GLuint, dstMask: GLuint,
                            dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint,
                            arg1Mod: GLuint, arg2: GLuint, arg2Rep: GLuint,
                            arg2Mod: GLuint, arg3: GLuint, arg3Rep: GLuint,
                            arg3Mod: GLuint){.stdcall, importc, ogl.}
proc glAlphaFragmentOp1ATI*(op: GLenum, dst: GLuint, dstMod: GLuint,
                            arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint){.
    stdcall, importc, ogl.}
proc glAlphaFragmentOp2ATI*(op: GLenum, dst: GLuint, dstMod: GLuint,
                            arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint,
                            arg2: GLuint, arg2Rep: GLuint, arg2Mod: GLuint){.
    stdcall, importc, ogl.}
proc glAlphaFragmentOp3ATI*(op: GLenum, dst: GLuint, dstMod: GLuint,
                            arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint,
                            arg2: GLuint, arg2Rep: GLuint, arg2Mod: GLuint,
                            arg3: GLuint, arg3Rep: GLuint, arg3Mod: GLuint){.
    stdcall, importc, ogl.}
proc glSetFragmentShaderConstantATI*(dst: GLuint, value: PGLfloat){.stdcall, importc, ogl.}
  # GL_ATI_map_object_buffer
proc glMapObjectBufferATI*(buffer: GLuint): PGLvoid{.stdcall, importc, ogl.}
proc glUnmapObjectBufferATI*(buffer: GLuint){.stdcall, importc, ogl.}
  # GL_ATI_pn_triangles
proc glPNTrianglesiATI*(pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glPNTrianglesfATI*(pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
  # GL_ATI_separate_stencil
proc glStencilOpSeparateATI*(face: GLenum, sfail: GLenum, dpfail: GLenum,
                             dppass: GLenum){.stdcall, importc, ogl.}
proc glStencilFuncSeparateATI*(frontfunc: GLenum, backfunc: GLenum, theRef: GLint,
                               mask: GLuint){.stdcall, importc, ogl.}
  # GL_ATI_vertex_array_object
proc glNewObjectBufferATI*(size: GLsizei, pointer: PGLvoid, usage: GLenum): GLuint{.
    stdcall, importc, ogl.}
proc glIsObjectBufferATI*(buffer: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glUpdateObjectBufferATI*(buffer: GLuint, offset: GLuint, size: GLsizei,
                              pointer: PGLvoid, preserve: GLenum){.stdcall, importc, ogl.}
proc glGetObjectBufferfvATI*(buffer: GLuint, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetObjectBufferivATI*(buffer: GLuint, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glFreeObjectBufferATI*(buffer: GLuint){.stdcall, importc, ogl.}
proc glArrayObjectATI*(arr: GLenum, size: GLint, typ: GLenum, stride: GLsizei,
                       buffer: GLuint, offset: GLuint){.stdcall, importc, ogl.}
proc glGetArrayObjectfvATI*(arr: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetArrayObjectivATI*(arr: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glVariantArrayObjectATI*(id: GLuint, typ: GLenum, stride: GLsizei,
                              buffer: GLuint, offset: GLuint){.stdcall, importc, ogl.}
proc glGetVariantArrayObjectfvATI*(id: GLuint, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetVariantArrayObjectivATI*(id: GLuint, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
  # GL_ATI_vertex_attrib_array_object
proc glVertexAttribArrayObjectATI*(index: GLuint, size: GLint, typ: GLenum,
                                   normalized: GLboolean, stride: GLsizei,
                                   buffer: GLuint, offset: GLuint){.stdcall, importc, ogl.}
proc glGetVertexAttribArrayObjectfvATI*(index: GLuint, pname: GLenum,
                                        params: PGLfloat){.stdcall, importc, ogl.}
proc glGetVertexAttribArrayObjectivATI*(index: GLuint, pname: GLenum,
                                        params: PGLint){.stdcall, importc, ogl.}
  # GL_ATI_vertex_streams
proc glVertexStream1sATI*(stream: GLenum, x: GLshort){.stdcall, importc, ogl.}
proc glVertexStream1svATI*(stream: GLenum, coords: PGLshort){.stdcall, importc, ogl.}
proc glVertexStream1iATI*(stream: GLenum, x: GLint){.stdcall, importc, ogl.}
proc glVertexStream1ivATI*(stream: GLenum, coords: PGLint){.stdcall, importc, ogl.}
proc glVertexStream1fATI*(stream: GLenum, x: GLfloat){.stdcall, importc, ogl.}
proc glVertexStream1fvATI*(stream: GLenum, coords: PGLfloat){.stdcall, importc, ogl.}
proc glVertexStream1dATI*(stream: GLenum, x: GLdouble){.stdcall, importc, ogl.}
proc glVertexStream1dvATI*(stream: GLenum, coords: PGLdouble){.stdcall, importc, ogl.}
proc glVertexStream2sATI*(stream: GLenum, x: GLshort, y: GLshort){.stdcall, importc, ogl.}
proc glVertexStream2svATI*(stream: GLenum, coords: PGLshort){.stdcall, importc, ogl.}
proc glVertexStream2iATI*(stream: GLenum, x: GLint, y: GLint){.stdcall, importc, ogl.}
proc glVertexStream2ivATI*(stream: GLenum, coords: PGLint){.stdcall, importc, ogl.}
proc glVertexStream2fATI*(stream: GLenum, x: GLfloat, y: GLfloat){.stdcall, importc, ogl.}
proc glVertexStream2fvATI*(stream: GLenum, coords: PGLfloat){.stdcall, importc, ogl.}
proc glVertexStream2dATI*(stream: GLenum, x: GLdouble, y: GLdouble){.stdcall, importc, ogl.}
proc glVertexStream2dvATI*(stream: GLenum, coords: PGLdouble){.stdcall, importc, ogl.}
proc glVertexStream3sATI*(stream: GLenum, x: GLshort, y: GLshort, z: GLshort){.
    stdcall, importc, ogl.}
proc glVertexStream3svATI*(stream: GLenum, coords: PGLshort){.stdcall, importc, ogl.}
proc glVertexStream3iATI*(stream: GLenum, x: GLint, y: GLint, z: GLint){.stdcall, importc, ogl.}
proc glVertexStream3ivATI*(stream: GLenum, coords: PGLint){.stdcall, importc, ogl.}
proc glVertexStream3fATI*(stream: GLenum, x: GLfloat, y: GLfloat, z: GLfloat){.
    stdcall, importc, ogl.}
proc glVertexStream3fvATI*(stream: GLenum, coords: PGLfloat){.stdcall, importc, ogl.}
proc glVertexStream3dATI*(stream: GLenum, x: GLdouble, y: GLdouble, z: GLdouble){.
    stdcall, importc, ogl.}
proc glVertexStream3dvATI*(stream: GLenum, coords: PGLdouble){.stdcall, importc, ogl.}
proc glVertexStream4sATI*(stream: GLenum, x: GLshort, y: GLshort, z: GLshort,
                          w: GLshort){.stdcall, importc, ogl.}
proc glVertexStream4svATI*(stream: GLenum, coords: PGLshort){.stdcall, importc, ogl.}
proc glVertexStream4iATI*(stream: GLenum, x: GLint, y: GLint, z: GLint, w: GLint){.
    stdcall, importc, ogl.}
proc glVertexStream4ivATI*(stream: GLenum, coords: PGLint){.stdcall, importc, ogl.}
proc glVertexStream4fATI*(stream: GLenum, x: GLfloat, y: GLfloat, z: GLfloat,
                          w: GLfloat){.stdcall, importc, ogl.}
proc glVertexStream4fvATI*(stream: GLenum, coords: PGLfloat){.stdcall, importc, ogl.}
proc glVertexStream4dATI*(stream: GLenum, x: GLdouble, y: GLdouble, z: GLdouble,
                          w: GLdouble){.stdcall, importc, ogl.}
proc glVertexStream4dvATI*(stream: GLenum, coords: PGLdouble){.stdcall, importc, ogl.}
proc glNormalStream3bATI*(stream: GLenum, nx: GLbyte, ny: GLbyte, nz: GLbyte){.
    stdcall, importc, ogl.}
proc glNormalStream3bvATI*(stream: GLenum, coords: PGLbyte){.stdcall, importc, ogl.}
proc glNormalStream3sATI*(stream: GLenum, nx: GLshort, ny: GLshort, nz: GLshort){.
    stdcall, importc, ogl.}
proc glNormalStream3svATI*(stream: GLenum, coords: PGLshort){.stdcall, importc, ogl.}
proc glNormalStream3iATI*(stream: GLenum, nx: GLint, ny: GLint, nz: GLint){.
    stdcall, importc, ogl.}
proc glNormalStream3ivATI*(stream: GLenum, coords: PGLint){.stdcall, importc, ogl.}
proc glNormalStream3fATI*(stream: GLenum, nx: GLfloat, ny: GLfloat, nz: GLfloat){.
    stdcall, importc, ogl.}
proc glNormalStream3fvATI*(stream: GLenum, coords: PGLfloat){.stdcall, importc, ogl.}
proc glNormalStream3dATI*(stream: GLenum, nx: GLdouble, ny: GLdouble,
                          nz: GLdouble){.stdcall, importc, ogl.}
proc glNormalStream3dvATI*(stream: GLenum, coords: PGLdouble){.stdcall, importc, ogl.}
proc glClientActiveVertexStreamATI*(stream: GLenum){.stdcall, importc, ogl.}
proc glVertexBlendEnviATI*(pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glVertexBlendEnvfATI*(pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
  # GL_AMD_performance_monitor
proc glGetPerfMonitorGroupsAMD*(numGroups: PGLint, groupsSize: GLsizei,
                                groups: PGLuint){.stdcall, importc, ogl.}
proc glGetPerfMonitorCountersAMD*(group: GLuint, numCounters: PGLint,
                                  maxActiveCouters: PGLint,
                                  counterSize: GLsizei, counters: PGLuint){.
    stdcall, importc, ogl.}
proc glGetPerfMonitorGroupStringAMD*(group: GLuint, bufSize: GLsizei,
                                     len: PGLsizei, groupString: PGLchar){.
    stdcall, importc, ogl.}
proc glGetPerfMonitorCounterStringAMD*(group: GLuint, counter: GLuint,
                                       bufSize: GLsizei, len: PGLsizei,
                                       counterString: PGLchar){.stdcall, importc, ogl.}
proc glGetPerfMonitorCounterInfoAMD*(group: GLuint, counter: GLuint,
                                     pname: GLenum, data: PGLvoid){.stdcall, importc, ogl.}
proc glGenPerfMonitorsAMD*(n: GLsizei, monitors: PGLuint){.stdcall, importc, ogl.}
proc glDeletePerfMonitorsAMD*(n: GLsizei, monitors: PGLuint){.stdcall, importc, ogl.}
proc glSelectPerfMonitorCountersAMD*(monitor: GLuint, enable: GLboolean,
                                     group: GLuint, numCounters: GLint,
                                     counterList: PGLuint){.stdcall, importc, ogl.}
proc glBeginPerfMonitorAMD*(monitor: GLuint){.stdcall, importc, ogl.}
proc glEndPerfMonitorAMD*(monitor: GLuint){.stdcall, importc, ogl.}
proc glGetPerfMonitorCounterDataAMD*(monitor: GLuint, pname: GLenum,
                                     dataSize: GLsizei, data: PGLuint,
                                     bytesWritten: PGLint){.stdcall, importc, ogl.}
  # GL_AMD_vertex_shader_tesselator
proc glTessellationFactorAMD*(factor: GLfloat){.stdcall, importc, ogl.}
proc glTessellationModeAMD*(mode: GLenum){.stdcall, importc, ogl.}
  # GL_AMD_draw_buffers_blend
proc glBlendFuncIndexedAMD*(buf: GLuint, src: GLenum, dst: GLenum){.stdcall, importc, ogl.}
proc glBlendFuncSeparateIndexedAMD*(buf: GLuint, srcRGB: GLenum, dstRGB: GLenum,
                                    srcAlpha: GLenum, dstAlpha: GLenum){.stdcall, importc, ogl.}
proc glBlendEquationIndexedAMD*(buf: GLuint, mode: GLenum){.stdcall, importc, ogl.}
proc glBlendEquationSeparateIndexedAMD*(buf: GLuint, modeRGB: GLenum,
                                        modeAlpha: GLenum){.stdcall, importc, ogl.}
  # GL_AMD_name_gen_delete
proc glGenNamesAMD*(identifier: GLenum, num: GLuint, names: PGLuint){.stdcall, importc, ogl.}
proc glDeleteNamesAMD*(identifier: GLenum, num: GLuint, names: PGLuint){.stdcall, importc, ogl.}
proc glIsNameAMD*(identifier: GLenum, name: GLuint): GLboolean{.stdcall, importc, ogl.}
  # GL_AMD_debug_output
proc glDebugMessageEnableAMD*(category: GLenum, severity: GLenum,
                              count: GLsizei, ids: PGLuint, enabled: GLboolean){.
    stdcall, importc, ogl.}
proc glDebugMessageInsertAMD*(category: GLenum, severity: GLenum, id: GLuint,
                              len: GLsizei, buf: PGLchar){.stdcall, importc, ogl.}
proc glDebugMessageCallbackAMD*(callback: TGLDebugProcAMD, userParam: PGLvoid){.
    stdcall, importc, ogl.}
proc glGetDebugMessageLogAMD*(count: GLuint, bufsize: GLsizei,
                              categories: PGLenum, severities: PGLuint,
                              ids: PGLuint, lengths: PGLsizei, message: PGLchar): GLuint{.
    stdcall, importc, ogl.}
  # GL_EXT_blend_color
proc glBlendColorEXT*(red: GLclampf, green: GLclampf, blue: GLclampf,
                      alpha: GLclampf){.stdcall, importc, ogl.}
  # GL_EXT_blend_func_separate
proc glBlendFuncSeparateEXT*(sfactorRGB: GLenum, dfactorRGB: GLenum,
                             sfactorAlpha: GLenum, dfactorAlpha: GLenum){.
    stdcall, importc, ogl.}
  # GL_EXT_blend_minmax
proc glBlendEquationEXT*(mode: GLenum){.stdcall, importc, ogl.}
  # GL_EXT_color_subtable
proc glColorSubTableEXT*(target: GLenum, start: GLsizei, count: GLsizei,
                         format: GLenum, typ: GLenum, data: PGLvoid){.stdcall, importc, ogl.}
proc glCopyColorSubTableEXT*(target: GLenum, start: GLsizei, x: GLint, y: GLint,
                             width: GLsizei){.stdcall, importc, ogl.}
  # GL_EXT_compiled_vertex_array
proc glLockArraysEXT*(first: GLint, count: GLsizei){.stdcall, importc, ogl.}
proc glUnlockArraysEXT*(){.stdcall, importc, ogl.}
  # GL_EXT_convolution
proc glConvolutionFilter1DEXT*(target: GLenum, internalformat: GLenum,
                               width: GLsizei, format: GLenum, typ: GLenum,
                               image: PGLvoid){.stdcall, importc, ogl.}
proc glConvolutionFilter2DEXT*(target: GLenum, internalformat: GLenum,
                               width: GLsizei, height: GLsizei, format: GLenum,
                               typ: GLenum, image: PGLvoid){.stdcall, importc, ogl.}
proc glConvolutionParameterfEXT*(target: GLenum, pname: GLenum, params: GLfloat){.
    stdcall, importc, ogl.}
proc glConvolutionParameterfvEXT*(target: GLenum, pname: GLenum,
                                  params: PGLfloat){.stdcall, importc, ogl.}
proc glConvolutionParameteriEXT*(target: GLenum, pname: GLenum, params: GLint){.
    stdcall, importc, ogl.}
proc glConvolutionParameterivEXT*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glCopyConvolutionFilter1DEXT*(target: GLenum, internalformat: GLenum,
                                   x: GLint, y: GLint, width: GLsizei){.stdcall, importc, ogl.}
proc glCopyConvolutionFilter2DEXT*(target: GLenum, internalformat: GLenum,
                                   x: GLint, y: GLint, width: GLsizei,
                                   height: GLsizei){.stdcall, importc, ogl.}
proc glGetConvolutionFilterEXT*(target: GLenum, format: GLenum, typ: GLenum,
                                image: PGLvoid){.stdcall, importc, ogl.}
proc glGetConvolutionParameterfvEXT*(target: GLenum, pname: GLenum,
                                     params: PGLfloat){.stdcall, importc, ogl.}
proc glGetConvolutionParameterivEXT*(target: GLenum, pname: GLenum,
                                     params: PGLint){.stdcall, importc, ogl.}
proc glGetSeparableFilterEXT*(target: GLenum, format: GLenum, typ: GLenum,
                              row: PGLvoid, column: PGLvoid, span: PGLvoid){.
    stdcall, importc, ogl.}
proc glSeparableFilter2DEXT*(target: GLenum, internalformat: GLenum,
                             width: GLsizei, height: GLsizei, format: GLenum,
                             typ: GLenum, row: PGLvoid, column: PGLvoid){.
    stdcall, importc, ogl.}
  # GL_EXT_coordinate_frame
proc glTangent3bEXT*(tx: GLbyte, ty: GLbyte, tz: GLbyte){.stdcall, importc, ogl.}
proc glTangent3bvEXT*(v: PGLbyte){.stdcall, importc, ogl.}
proc glTangent3dEXT*(tx: GLdouble, ty: GLdouble, tz: GLdouble){.stdcall, importc, ogl.}
proc glTangent3dvEXT*(v: PGLdouble){.stdcall, importc, ogl.}
proc glTangent3fEXT*(tx: GLfloat, ty: GLfloat, tz: GLfloat){.stdcall, importc, ogl.}
proc glTangent3fvEXT*(v: PGLfloat){.stdcall, importc, ogl.}
proc glTangent3iEXT*(tx: GLint, ty: GLint, tz: GLint){.stdcall, importc, ogl.}
proc glTangent3ivEXT*(v: PGLint){.stdcall, importc, ogl.}
proc glTangent3sEXT*(tx: GLshort, ty: GLshort, tz: GLshort){.stdcall, importc, ogl.}
proc glTangent3svEXT*(v: PGLshort){.stdcall, importc, ogl.}
proc glBinormal3bEXT*(bx: GLbyte, by: GLbyte, bz: GLbyte){.stdcall, importc, ogl.}
proc glBinormal3bvEXT*(v: PGLbyte){.stdcall, importc, ogl.}
proc glBinormal3dEXT*(bx: GLdouble, by: GLdouble, bz: GLdouble){.stdcall, importc, ogl.}
proc glBinormal3dvEXT*(v: PGLdouble){.stdcall, importc, ogl.}
proc glBinormal3fEXT*(bx: GLfloat, by: GLfloat, bz: GLfloat){.stdcall, importc, ogl.}
proc glBinormal3fvEXT*(v: PGLfloat){.stdcall, importc, ogl.}
proc glBinormal3iEXT*(bx: GLint, by: GLint, bz: GLint){.stdcall, importc, ogl.}
proc glBinormal3ivEXT*(v: PGLint){.stdcall, importc, ogl.}
proc glBinormal3sEXT*(bx: GLshort, by: GLshort, bz: GLshort){.stdcall, importc, ogl.}
proc glBinormal3svEXT*(v: PGLshort){.stdcall, importc, ogl.}
proc glTangentPointerEXT*(typ: GLenum, stride: GLsizei, pointer: PGLvoid){.
    stdcall, importc, ogl.}
proc glBinormalPointerEXT*(typ: GLenum, stride: GLsizei, pointer: PGLvoid){.
    stdcall, importc, ogl.}
  # GL_EXT_copy_texture
proc glCopyTexImage1DEXT*(target: GLenum, level: GLint, internalformat: GLenum,
                          x: GLint, y: GLint, width: GLsizei, border: GLint){.
    stdcall, importc, ogl.}
proc glCopyTexImage2DEXT*(target: GLenum, level: GLint, internalformat: GLenum,
                          x: GLint, y: GLint, width: GLsizei, height: GLsizei,
                          border: GLint){.stdcall, importc, ogl.}
proc glCopyTexSubImage1DEXT*(target: GLenum, level: GLint, xoffset: GLint,
                             x: GLint, y: GLint, width: GLsizei){.stdcall, importc, ogl.}
proc glCopyTexSubImage2DEXT*(target: GLenum, level: GLint, xoffset: GLint,
                             yoffset: GLint, x: GLint, y: GLint, width: GLsizei,
                             height: GLsizei){.stdcall, importc, ogl.}
proc glCopyTexSubImage3DEXT*(target: GLenum, level: GLint, xoffset: GLint,
                             yoffset: GLint, zoffset: GLint, x: GLint, y: GLint,
                             width: GLsizei, height: GLsizei){.stdcall, importc, ogl.}
  # GL_EXT_cull_vertex
proc glCullParameterdvEXT*(pname: GLenum, params: PGLdouble){.stdcall, importc, ogl.}
proc glCullParameterfvEXT*(pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
  # GL_EXT_draw_range_elements
proc glDrawRangeElementsEXT*(mode: GLenum, start: GLuint, ending: GLuint,
                             count: GLsizei, typ: GLenum, indices: PGLvoid){.
    stdcall, importc, ogl.}
  # GL_EXT_fog_coord
proc glFogCoordfEXT*(coord: GLfloat){.stdcall, importc, ogl.}
proc glFogCoordfvEXT*(coord: PGLfloat){.stdcall, importc, ogl.}
proc glFogCoorddEXT*(coord: GLdouble){.stdcall, importc, ogl.}
proc glFogCoorddvEXT*(coord: PGLdouble){.stdcall, importc, ogl.}
proc glFogCoordPointerEXT*(typ: GLenum, stride: GLsizei, pointer: PGLvoid){.
    stdcall, importc, ogl.}
  # GL_EXT_framebuffer_object
proc glIsRenderbufferEXT*(renderbuffer: GLuint): bool{.stdcall, importc, ogl.}
proc glBindRenderbufferEXT*(target: GLenum, renderbuffer: GLuint){.stdcall, importc, ogl.}
proc glDeleteRenderbuffersEXT*(n: GLsizei, renderbuffers: PGLuint){.stdcall, importc, ogl.}
proc glGenRenderbuffersEXT*(n: GLsizei, renderbuffers: PGLuint){.stdcall, importc, ogl.}
proc glRenderbufferStorageEXT*(target: GLenum, internalformat: GLenum,
                               width: GLsizei, height: GLsizei){.stdcall, importc, ogl.}
proc glGetRenderbufferParameterivEXT*(target: GLenum, pname: GLenum,
                                      params: PGLint){.stdcall, importc, ogl.}
proc glIsFramebufferEXT*(framebuffer: GLuint): bool{.stdcall, importc, ogl.}
proc glBindFramebufferEXT*(target: GLenum, framebuffer: GLuint){.stdcall, importc, ogl.}
proc glDeleteFramebuffersEXT*(n: GLsizei, framebuffers: PGLuint){.stdcall, importc, ogl.}
proc glGenFramebuffersEXT*(n: GLsizei, framebuffers: PGLuint){.stdcall, importc, ogl.}
proc glCheckFramebufferStatusEXT*(target: GLenum): GLenum{.stdcall, importc, ogl.}
proc glFramebufferTexture1DEXT*(target: GLenum, attachment: GLenum,
                                textarget: GLenum, texture: GLuint, level: GLint){.
    stdcall, importc, ogl.}
proc glFramebufferTexture2DEXT*(target: GLenum, attachment: GLenum,
                                textarget: GLenum, texture: GLuint, level: GLint){.
    stdcall, importc, ogl.}
proc glFramebufferTexture3DEXT*(target: GLenum, attachment: GLenum,
                                textarget: GLenum, texture: GLuint,
                                level: GLint, zoffset: GLint){.stdcall, importc, ogl.}
proc glFramebufferRenderbufferEXT*(target: GLenum, attachment: GLenum,
                                   renderbuffertarget: GLenum,
                                   renderbuffer: GLuint){.stdcall, importc, ogl.}
proc glGetFramebufferAttachmentParameterivEXT*(target: GLenum,
    attachment: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGenerateMipmapEXT*(target: GLenum){.stdcall, importc, ogl.}
  # GL_EXT_histogram
proc glGetHistogramEXT*(target: GLenum, reset: GLboolean, format: GLenum,
                        typ: GLenum, values: PGLvoid){.stdcall, importc, ogl.}
proc glGetHistogramParameterfvEXT*(target: GLenum, pname: GLenum,
                                   params: PGLfloat){.stdcall, importc, ogl.}
proc glGetHistogramParameterivEXT*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetMinmaxEXT*(target: GLenum, reset: GLboolean, format: GLenum,
                     typ: GLenum, values: PGLvoid){.stdcall, importc, ogl.}
proc glGetMinmaxParameterfvEXT*(target: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetMinmaxParameterivEXT*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glHistogramEXT*(target: GLenum, width: GLsizei, internalformat: GLenum,
                     sink: GLboolean){.stdcall, importc, ogl.}
proc glMinmaxEXT*(target: GLenum, internalformat: GLenum, sink: GLboolean){.
    stdcall, importc, ogl.}
proc glResetHistogramEXT*(target: GLenum){.stdcall, importc, ogl.}
proc glResetMinmaxEXT*(target: GLenum){.stdcall, importc, ogl.}
  # GL_EXT_index_func
proc glIndexFuncEXT*(func: GLenum, theRef: GLclampf){.stdcall, importc, ogl.}
  # GL_EXT_index_material
proc glIndexMaterialEXT*(face: GLenum, mode: GLenum){.stdcall, importc, ogl.}
  # GL_EXT_light_texture
proc glApplyTextureEXT*(mode: GLenum){.stdcall, importc, ogl.}
proc glTextureLightEXT*(pname: GLenum){.stdcall, importc, ogl.}
proc glTextureMaterialEXT*(face: GLenum, mode: GLenum){.stdcall, importc, ogl.}
  # GL_EXT_multi_draw_arrays
proc glMultiDrawArraysEXT*(mode: GLenum, first: PGLint, count: PGLsizei,
                           primcount: GLsizei){.stdcall, importc, ogl.}
proc glMultiDrawElementsEXT*(mode: GLenum, count: PGLsizei, typ: GLenum,
                             indices: PGLvoid, primcount: GLsizei){.stdcall, importc, ogl.}
  # GL_EXT_multisample
proc glSampleMaskEXT*(value: GLclampf, invert: GLboolean){.stdcall, importc, ogl.}
proc glSamplePatternEXT*(pattern: GLenum){.stdcall, importc, ogl.}
  # GL_EXT_paletted_texture
proc glColorTableEXT*(target: GLenum, internalFormat: GLenum, width: GLsizei,
                      format: GLenum, typ: GLenum, table: PGLvoid){.stdcall, importc, ogl.}
proc glGetColorTableEXT*(target: GLenum, format: GLenum, typ: GLenum,
                         data: PGLvoid){.stdcall, importc, ogl.}
proc glGetColorTableParameterivEXT*(target: GLenum, pname: GLenum,
                                    params: PGLint){.stdcall, importc, ogl.}
proc glGetColorTableParameterfvEXT*(target: GLenum, pname: GLenum,
                                    params: PGLfloat){.stdcall, importc, ogl.}
  # GL_EXT_pixel_transform
proc glPixelTransformParameteriEXT*(target: GLenum, pname: GLenum, param: GLint){.
    stdcall, importc, ogl.}
proc glPixelTransformParameterfEXT*(target: GLenum, pname: GLenum,
                                    param: GLfloat){.stdcall, importc, ogl.}
proc glPixelTransformParameterivEXT*(target: GLenum, pname: GLenum,
                                     params: PGLint){.stdcall, importc, ogl.}
proc glPixelTransformParameterfvEXT*(target: GLenum, pname: GLenum,
                                     params: PGLfloat){.stdcall, importc, ogl.}
  # GL_EXT_point_parameters
proc glPointParameterfEXT*(pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glPointParameterfvEXT*(pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
  # GL_EXT_polygon_offset
proc glPolygonOffsetEXT*(factor: GLfloat, bias: GLfloat){.stdcall, importc, ogl.}
  # GL_EXT_secondary_color
proc glSecondaryColor3bEXT*(red: GLbyte, green: GLbyte, blue: GLbyte){.stdcall, importc, ogl.}
proc glSecondaryColor3bvEXT*(v: PGLbyte){.stdcall, importc, ogl.}
proc glSecondaryColor3dEXT*(red: GLdouble, green: GLdouble, blue: GLdouble){.
    stdcall, importc, ogl.}
proc glSecondaryColor3dvEXT*(v: PGLdouble){.stdcall, importc, ogl.}
proc glSecondaryColor3fEXT*(red: GLfloat, green: GLfloat, blue: GLfloat){.
    stdcall, importc, ogl.}
proc glSecondaryColor3fvEXT*(v: PGLfloat){.stdcall, importc, ogl.}
proc glSecondaryColor3iEXT*(red: GLint, green: GLint, blue: GLint){.stdcall, importc, ogl.}
proc glSecondaryColor3ivEXT*(v: PGLint){.stdcall, importc, ogl.}
proc glSecondaryColor3sEXT*(red: GLshort, green: GLshort, blue: GLshort){.
    stdcall, importc, ogl.}
proc glSecondaryColor3svEXT*(v: PGLshort){.stdcall, importc, ogl.}
proc glSecondaryColor3ubEXT*(red: GLubyte, green: GLubyte, blue: GLubyte){.
    stdcall, importc, ogl.}
proc glSecondaryColor3ubvEXT*(v: PGLubyte){.stdcall, importc, ogl.}
proc glSecondaryColor3uiEXT*(red: GLuint, green: GLuint, blue: GLuint){.stdcall, importc, ogl.}
proc glSecondaryColor3uivEXT*(v: PGLuint){.stdcall, importc, ogl.}
proc glSecondaryColor3usEXT*(red: GLushort, green: GLushort, blue: GLushort){.
    stdcall, importc, ogl.}
proc glSecondaryColor3usvEXT*(v: PGLushort){.stdcall, importc, ogl.}
proc glSecondaryColorPointerEXT*(size: GLint, typ: GLenum, stride: GLsizei,
                                 pointer: PGLvoid){.stdcall, importc, ogl.}
  # GL_EXT_stencil_two_side
proc glActiveStencilFaceEXT*(face: GLenum){.stdcall, importc, ogl.}
  # GL_EXT_subtexture
proc glTexSubImage1DEXT*(target: GLenum, level: GLint, xoffset: GLint,
                         width: GLsizei, format: GLenum, typ: GLenum,
                         pixels: PGLvoid){.stdcall, importc, ogl.}
proc glTexSubImage2DEXT*(target: GLenum, level: GLint, xoffset: GLint,
                         yoffset: GLint, width: GLsizei, height: GLsizei,
                         format: GLenum, typ: GLenum, pixels: PGLvoid){.stdcall, importc, ogl.}
  # GL_EXT_texture3D
proc glTexImage3DEXT*(target: GLenum, level: GLint, internalformat: GLenum,
                      width: GLsizei, height: GLsizei, depth: GLsizei,
                      border: GLint, format: GLenum, typ: GLenum,
                      pixels: PGLvoid){.stdcall, importc, ogl.}
proc glTexSubImage3DEXT*(target: GLenum, level: GLint, xoffset: GLint,
                         yoffset: GLint, zoffset: GLint, width: GLsizei,
                         height: GLsizei, depth: GLsizei, format: GLenum,
                         typ: GLenum, pixels: PGLvoid){.stdcall, importc, ogl.}
  # GL_EXT_texture_object
proc glAreTexturesResidentEXT*(n: GLsizei, textures: PGLuint,
                               residences: PGLboolean): GLboolean{.stdcall, importc, ogl.}
proc glBindTextureEXT*(target: GLenum, texture: GLuint){.stdcall, importc, ogl.}
proc glDeleteTexturesEXT*(n: GLsizei, textures: PGLuint){.stdcall, importc, ogl.}
proc glGenTexturesEXT*(n: GLsizei, textures: PGLuint){.stdcall, importc, ogl.}
proc glIsTextureEXT*(texture: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glPrioritizeTexturesEXT*(n: GLsizei, textures: PGLuint,
                              priorities: PGLclampf){.stdcall, importc, ogl.}
  # GL_EXT_texture_perturb_normal
proc glTextureNormalEXT*(mode: GLenum){.stdcall, importc, ogl.}
  # GL_EXT_vertex_array
proc glArrayElementEXT*(i: GLint){.stdcall, importc, ogl.}
proc glColorPointerEXT*(size: GLint, typ: GLenum, stride: GLsizei,
                        count: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glDrawArraysEXT*(mode: GLenum, first: GLint, count: GLsizei){.stdcall, importc, ogl.}
proc glEdgeFlagPointerEXT*(stride: GLsizei, count: GLsizei, pointer: PGLboolean){.
    stdcall, importc, ogl.}
proc glGetPointervEXT*(pname: GLenum, params: PGLvoid){.stdcall, importc, ogl.}
proc glIndexPointerEXT*(typ: GLenum, stride: GLsizei, count: GLsizei,
                        pointer: PGLvoid){.stdcall, importc, ogl.}
proc glNormalPointerEXT*(typ: GLenum, stride: GLsizei, count: GLsizei,
                         pointer: PGLvoid){.stdcall, importc, ogl.}
proc glTexCoordPointerEXT*(size: GLint, typ: GLenum, stride: GLsizei,
                           count: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glVertexPointerEXT*(size: GLint, typ: GLenum, stride: GLsizei,
                         count: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
  # GL_EXT_vertex_shader
proc glBeginVertexShaderEXT*(){.stdcall, importc, ogl.}
proc glEndVertexShaderEXT*(){.stdcall, importc, ogl.}
proc glBindVertexShaderEXT*(id: GLuint){.stdcall, importc, ogl.}
proc glGenVertexShadersEXT*(range: GLuint): GLuint{.stdcall, importc, ogl.}
proc glDeleteVertexShaderEXT*(id: GLuint){.stdcall, importc, ogl.}
proc glShaderOp1EXT*(op: GLenum, res: GLuint, arg1: GLuint){.stdcall, importc, ogl.}
proc glShaderOp2EXT*(op: GLenum, res: GLuint, arg1: GLuint, arg2: GLuint){.
    stdcall, importc, ogl.}
proc glShaderOp3EXT*(op: GLenum, res: GLuint, arg1: GLuint, arg2: GLuint,
                     arg3: GLuint){.stdcall, importc, ogl.}
proc glSwizzleEXT*(res: GLuint, ain: GLuint, outX: GLenum, outY: GLenum,
                   outZ: GLenum, outW: GLenum){.stdcall, importc, ogl.}
proc glWriteMaskEXT*(res: GLuint, ain: GLuint, outX: GLenum, outY: GLenum,
                     outZ: GLenum, outW: GLenum){.stdcall, importc, ogl.}
proc glInsertComponentEXT*(res: GLuint, src: GLuint, num: GLuint){.stdcall, importc, ogl.}
proc glExtractComponentEXT*(res: GLuint, src: GLuint, num: GLuint){.stdcall, importc, ogl.}
proc glGenSymbolsEXT*(datatype: GLenum, storagetype: GLenum, range: GLenum,
                      components: GLuint): GLuint{.stdcall, importc, ogl.}
proc glSetInvariantEXT*(id: GLuint, typ: GLenum, theAddr: PGLvoid){.stdcall, importc, ogl.}
proc glSetLocalConstantEXT*(id: GLuint, typ: GLenum, theAddr: PGLvoid){.stdcall, importc, ogl.}
proc glVariantbvEXT*(id: GLuint, theAddr: PGLbyte){.stdcall, importc, ogl.}
proc glVariantsvEXT*(id: GLuint, theAddr: PGLshort){.stdcall, importc, ogl.}
proc glVariantivEXT*(id: GLuint, theAddr: PGLint){.stdcall, importc, ogl.}
proc glVariantfvEXT*(id: GLuint, theAddr: PGLfloat){.stdcall, importc, ogl.}
proc glVariantdvEXT*(id: GLuint, theAddr: PGLdouble){.stdcall, importc, ogl.}
proc glVariantubvEXT*(id: GLuint, theAddr: PGLubyte){.stdcall, importc, ogl.}
proc glVariantusvEXT*(id: GLuint, theAddr: PGLushort){.stdcall, importc, ogl.}
proc glVariantuivEXT*(id: GLuint, theAddr: PGLuint){.stdcall, importc, ogl.}
proc glVariantPointerEXT*(id: GLuint, typ: GLenum, stride: GLuint, theAddr: PGLvoid){.
    stdcall, importc, ogl.}
proc glEnableVariantClientStateEXT*(id: GLuint){.stdcall, importc, ogl.}
proc glDisableVariantClientStateEXT*(id: GLuint){.stdcall, importc, ogl.}
proc glBindLightParameterEXT*(light: GLenum, value: GLenum): GLuint{.stdcall, importc, ogl.}
proc glBindMaterialParameterEXT*(face: GLenum, value: GLenum): GLuint{.stdcall, importc, ogl.}
proc glBindTexGenParameterEXT*(theUnit: GLenum, coord: GLenum, value: GLenum): GLuint{.
    stdcall, importc, ogl.}
proc glBindTextureUnitParameterEXT*(theUnit: GLenum, value: GLenum): GLuint{.
    stdcall, importc, ogl.}
proc glBindParameterEXT*(value: GLenum): GLuint{.stdcall, importc, ogl.}
proc glIsVariantEnabledEXT*(id: GLuint, cap: GLenum): GLboolean{.stdcall, importc, ogl.}
proc glGetVariantBooleanvEXT*(id: GLuint, value: GLenum, data: PGLboolean){.
    stdcall, importc, ogl.}
proc glGetVariantIntegervEXT*(id: GLuint, value: GLenum, data: PGLint){.stdcall, importc, ogl.}
proc glGetVariantFloatvEXT*(id: GLuint, value: GLenum, data: PGLfloat){.stdcall, importc, ogl.}
proc glGetVariantPointervEXT*(id: GLuint, value: GLenum, data: PGLvoid){.stdcall, importc, ogl.}
proc glGetInvariantBooleanvEXT*(id: GLuint, value: GLenum, data: PGLboolean){.
    stdcall, importc, ogl.}
proc glGetInvariantIntegervEXT*(id: GLuint, value: GLenum, data: PGLint){.
    stdcall, importc, ogl.}
proc glGetInvariantFloatvEXT*(id: GLuint, value: GLenum, data: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetLocalConstantBooleanvEXT*(id: GLuint, value: GLenum, data: PGLboolean){.
    stdcall, importc, ogl.}
proc glGetLocalConstantIntegervEXT*(id: GLuint, value: GLenum, data: PGLint){.
    stdcall, importc, ogl.}
proc glGetLocalConstantFloatvEXT*(id: GLuint, value: GLenum, data: PGLfloat){.
    stdcall, importc, ogl.}
  # GL_EXT_vertex_weighting
proc glVertexWeightfEXT*(weight: GLfloat){.stdcall, importc, ogl.}
proc glVertexWeightfvEXT*(weight: PGLfloat){.stdcall, importc, ogl.}
proc glVertexWeightPointerEXT*(size: GLsizei, typ: GLenum, stride: GLsizei,
                               pointer: PGLvoid){.stdcall, importc, ogl.}
  # GL_EXT_stencil_clear_tag
proc glStencilClearTagEXT*(stencilTagBits: GLsizei, stencilClearTag: GLuint){.
    stdcall, importc, ogl.}
  # GL_EXT_framebuffer_blit
proc glBlitFramebufferEXT*(srcX0: GLint, srcY0: GLint, srcX1: GLint,
                           srcY1: GLint, dstX0: GLint, dstY0: GLint,
                           dstX1: GLint, dstY1: GLint, mask: GLbitfield,
                           filter: GLenum){.stdcall, importc, ogl.}
  # GL_EXT_framebuffer_multisample
proc glRenderbufferStorageMultisampleEXT*(target: GLenum, samples: GLsizei,
    internalformat: GLenum, width: GLsizei, height: GLsizei){.stdcall, importc, ogl.}
  # GL_EXT_timer_query
proc glGetQueryObjecti64vEXT*(id: GLuint, pname: GLenum, params: PGLint64EXT){.
    stdcall, importc, ogl.}
proc glGetQueryObjectui64vEXT*(id: GLuint, pname: GLenum, params: PGLuint64EXT){.
    stdcall, importc, ogl.}
  # GL_EXT_gpu_program_parameters
proc glProgramEnvParameters4fvEXT*(target: GLenum, index: GLuint,
                                   count: GLsizei, params: PGLfloat){.stdcall, importc, ogl.}
proc glProgramLocalParameters4fvEXT*(target: GLenum, index: GLuint,
                                     count: GLsizei, params: PGLfloat){.stdcall, importc, ogl.}
  # GL_EXT_bindable_uniform
proc glUniformBufferEXT*(prog: GLuint, location: GLint, buffer: GLuint){.stdcall, importc, ogl.}
proc glGetUniformBufferSizeEXT*(prog: GLuint, location: GLint): GLint{.stdcall, importc, ogl.}
proc glGetUniformOffsetEXT*(prog: GLuint, location: GLint): GLintptr{.stdcall, importc, ogl.}
  # GL_EXT_draw_buffers2
proc glColorMaskIndexedEXT*(buf: GLuint, r: GLboolean, g: GLboolean,
                            b: GLboolean, a: GLboolean){.stdcall, importc, ogl.}
proc glGetBooleanIndexedvEXT*(value: GLenum, index: GLuint, data: PGLboolean){.
    stdcall, importc, ogl.}
proc glGetIntegerIndexedvEXT*(value: GLenum, index: GLuint, data: PGLint){.
    stdcall, importc, ogl.}
proc glEnableIndexedEXT*(target: GLenum, index: GLuint){.stdcall, importc, ogl.}
proc glDisableIndexedEXT*(target: GLenum, index: GLuint){.stdcall, importc, ogl.}
proc glIsEnabledIndexedEXT*(target: GLenum, index: GLuint): GLboolean{.stdcall, importc, ogl.}
  # GL_EXT_draw_instanced
proc glDrawArraysInstancedEXT*(mode: GLenum, first: GLint, count: GLsizei,
                               primcount: GLsizei){.stdcall, importc, ogl.}
proc glDrawElementsInstancedEXT*(mode: GLenum, count: GLsizei, typ: GLenum,
                                 indices: Pointer, primcount: GLsizei){.stdcall, importc, ogl.}
  # GL_EXT_geometry_shader4
proc glProgramParameteriEXT*(prog: GLuint, pname: GLenum, value: GLint){.stdcall, importc, ogl.}
proc glFramebufferTextureEXT*(target: GLenum, attachment: GLenum,
                              texture: GLuint, level: GLint){.stdcall, importc, ogl.}
  #procedure glFramebufferTextureLayerEXT(target: GLenum; attachment: GLenum; texture: GLuint; level: GLint; layer: GLint); stdcall, importc, ogl;
proc glFramebufferTextureFaceEXT*(target: GLenum, attachment: GLenum,
                                  texture: GLuint, level: GLint, face: GLenum){.
    stdcall, importc, ogl.}
  # GL_EXT_gpu_shader4
proc glVertexAttribI1iEXT*(index: GLuint, x: GLint){.stdcall, importc, ogl.}
proc glVertexAttribI2iEXT*(index: GLuint, x: GLint, y: GLint){.stdcall, importc, ogl.}
proc glVertexAttribI3iEXT*(index: GLuint, x: GLint, y: GLint, z: GLint){.stdcall, importc, ogl.}
proc glVertexAttribI4iEXT*(index: GLuint, x: GLint, y: GLint, z: GLint, w: GLint){.
    stdcall, importc, ogl.}
proc glVertexAttribI1uiEXT*(index: GLuint, x: GLuint){.stdcall, importc, ogl.}
proc glVertexAttribI2uiEXT*(index: GLuint, x: GLuint, y: GLuint){.stdcall, importc, ogl.}
proc glVertexAttribI3uiEXT*(index: GLuint, x: GLuint, y: GLuint, z: GLuint){.
    stdcall, importc, ogl.}
proc glVertexAttribI4uiEXT*(index: GLuint, x: GLuint, y: GLuint, z: GLuint,
                            w: GLuint){.stdcall, importc, ogl.}
proc glVertexAttribI1ivEXT*(index: GLuint, v: PGLint){.stdcall, importc, ogl.}
proc glVertexAttribI2ivEXT*(index: GLuint, v: PGLint){.stdcall, importc, ogl.}
proc glVertexAttribI3ivEXT*(index: GLuint, v: PGLint){.stdcall, importc, ogl.}
proc glVertexAttribI4ivEXT*(index: GLuint, v: PGLint){.stdcall, importc, ogl.}
proc glVertexAttribI1uivEXT*(index: GLuint, v: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttribI2uivEXT*(index: GLuint, v: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttribI3uivEXT*(index: GLuint, v: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttribI4uivEXT*(index: GLuint, v: PGLuint){.stdcall, importc, ogl.}
proc glVertexAttribI4bvEXT*(index: GLuint, v: PGLbyte){.stdcall, importc, ogl.}
proc glVertexAttribI4svEXT*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttribI4ubvEXT*(index: GLuint, v: PGLubyte){.stdcall, importc, ogl.}
proc glVertexAttribI4usvEXT*(index: GLuint, v: PGLushort){.stdcall, importc, ogl.}
proc glVertexAttribIPointerEXT*(index: GLuint, size: GLint, typ: GLenum,
                                stride: GLsizei, pointer: Pointer){.stdcall, importc, ogl.}
proc glGetVertexAttribIivEXT*(index: GLuint, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetVertexAttribIuivEXT*(index: GLuint, pname: GLenum, params: PGLuint){.
    stdcall, importc, ogl.}
proc glUniform1uiEXT*(location: GLint, v0: GLuint){.stdcall, importc, ogl.}
proc glUniform2uiEXT*(location: GLint, v0: GLuint, v1: GLuint){.stdcall, importc, ogl.}
proc glUniform3uiEXT*(location: GLint, v0: GLuint, v1: GLuint, v2: GLuint){.
    stdcall, importc, ogl.}
proc glUniform4uiEXT*(location: GLint, v0: GLuint, v1: GLuint, v2: GLuint,
                      v3: GLuint){.stdcall, importc, ogl.}
proc glUniform1uivEXT*(location: GLint, count: GLsizei, value: PGLuint){.stdcall, importc, ogl.}
proc glUniform2uivEXT*(location: GLint, count: GLsizei, value: PGLuint){.stdcall, importc, ogl.}
proc glUniform3uivEXT*(location: GLint, count: GLsizei, value: PGLuint){.stdcall, importc, ogl.}
proc glUniform4uivEXT*(location: GLint, count: GLsizei, value: PGLuint){.stdcall, importc, ogl.}
proc glGetUniformuivEXT*(prog: GLuint, location: GLint, params: PGLuint){.
    stdcall, importc, ogl.}
proc glBindFragDataLocationEXT*(prog: GLuint, colorNumber: GLuint, name: PGLchar){.
    stdcall, importc, ogl.}
proc glGetFragDataLocationEXT*(prog: GLuint, name: PGLchar): GLint{.stdcall, importc, ogl.}
  # GL_EXT_texture_array
proc glFramebufferTextureLayerEXT*(target: GLenum, attachment: GLenum,
                                   texture: GLuint, level: GLint, layer: GLint){.
    stdcall, importc, ogl.}
  # GL_EXT_texture_buffer_object
proc glTexBufferEXT*(target: GLenum, internalformat: GLenum, buffer: GLuint){.
    stdcall, importc, ogl.}
  # GL_EXT_texture_integer
proc glClearColorIiEXT*(r: GLint, g: GLint, b: GLint, a: GLint){.stdcall, importc, ogl.}
proc glClearColorIuiEXT*(r: GLuint, g: GLuint, b: GLuint, a: GLuint){.stdcall, importc, ogl.}
proc glTexParameterIivEXT*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glTexParameterIuivEXT*(target: GLenum, pname: GLenum, params: PGLuint){.
    stdcall, importc, ogl.}
proc glGetTexParameterIivEXT*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetTexParameterIiuvEXT*(target: GLenum, pname: GLenum, params: PGLuint){.
    stdcall, importc, ogl.}
  # GL_HP_image_transform
proc glImageTransformParameteriHP*(target: GLenum, pname: GLenum, param: GLint){.
    stdcall, importc, ogl.}
proc glImageTransformParameterfHP*(target: GLenum, pname: GLenum, param: GLfloat){.
    stdcall, importc, ogl.}
proc glImageTransformParameterivHP*(target: GLenum, pname: GLenum,
                                    params: PGLint){.stdcall, importc, ogl.}
proc glImageTransformParameterfvHP*(target: GLenum, pname: GLenum,
                                    params: PGLfloat){.stdcall, importc, ogl.}
proc glGetImageTransformParameterivHP*(target: GLenum, pname: GLenum,
                                       params: PGLint){.stdcall, importc, ogl.}
proc glGetImageTransformParameterfvHP*(target: GLenum, pname: GLenum,
                                       params: PGLfloat){.stdcall, importc, ogl.}
  # GL_EXT_depth_bounds_test
proc glDepthBoundsEXT*(zmin: GLclampd, zmax: GLclampd){.stdcall, importc, ogl.}
  # GL_EXT_blend_equation_separate
proc glBlendEquationSeparateEXT*(modeRGB: GLenum, modeAlpha: GLenum){.stdcall, importc, ogl.}
  # GL_EXT_transform_feedback
proc glBeginTransformFeedbackEXT*(primitiveMode: GLenum){.stdcall, importc, ogl.}
proc glEndTransformFeedbackEXT*(){.stdcall, importc, ogl.}
proc glBindBufferRangeEXT*(target: GLenum, index: GLuint, buffer: GLuint,
                           offset: GLintptr, size: GLsizeiptr){.stdcall, importc, ogl.}
proc glBindBufferOffsetEXT*(target: GLenum, index: GLuint, buffer: GLuint,
                            offset: GLintptr){.stdcall, importc, ogl.}
proc glBindBufferBaseEXT*(target: GLenum, index: GLuint, buffer: GLuint){.
    stdcall, importc, ogl.}
proc glTransformFeedbackVaryingsEXT*(prog: GLuint, count: GLsizei,
                                     locations: PGLint, bufferMode: GLenum){.
    stdcall, importc, ogl.}
proc glGetTransformFeedbackVaryingEXT*(prog: GLuint, index: GLuint,
                                       location: PGLint){.stdcall, importc, ogl.}
  # GL_EXT_direct_state_access
proc glClientAttribDefaultEXT*(mask: GLbitfield){.stdcall, importc, ogl.}
proc glPushClientAttribDefaultEXT*(mask: GLbitfield){.stdcall, importc, ogl.}
proc glMatrixLoadfEXT*(mode: GLenum, m: PGLfloat){.stdcall, importc, ogl.}
proc glMatrixLoaddEXT*(mode: GLenum, m: PGLdouble){.stdcall, importc, ogl.}
proc glMatrixMultfEXT*(mode: GLenum, m: PGLfloat){.stdcall, importc, ogl.}
proc glMatrixMultdEXT*(mode: GLenum, m: PGLdouble){.stdcall, importc, ogl.}
proc glMatrixLoadIdentityEXT*(mode: GLenum){.stdcall, importc, ogl.}
proc glMatrixRotatefEXT*(mode: GLenum, angle: GLfloat, x: GLfloat, y: GLfloat,
                         z: GLfloat){.stdcall, importc, ogl.}
proc glMatrixRotatedEXT*(mode: GLenum, angle: GLdouble, x: GLdouble,
                         y: GLdouble, z: GLdouble){.stdcall, importc, ogl.}
proc glMatrixScalefEXT*(mode: GLenum, x: GLfloat, y: GLfloat, z: GLfloat){.
    stdcall, importc, ogl.}
proc glMatrixScaledEXT*(mode: GLenum, x: GLdouble, y: GLdouble, z: GLdouble){.
    stdcall, importc, ogl.}
proc glMatrixTranslatefEXT*(mode: GLenum, x: GLfloat, y: GLfloat, z: GLfloat){.
    stdcall, importc, ogl.}
proc glMatrixTranslatedEXT*(mode: GLenum, x: GLdouble, y: GLdouble, z: GLdouble){.
    stdcall, importc, ogl.}
proc glMatrixFrustumEXT*(mode: GLenum, left: GLdouble, right: GLdouble,
                         bottom: GLdouble, top: GLdouble, zNear: GLdouble,
                         zFar: GLdouble){.stdcall, importc, ogl.}
proc glMatrixOrthoEXT*(mode: GLenum, left: GLdouble, right: GLdouble,
                       bottom: GLdouble, top: GLdouble, zNear: GLdouble,
                       zFar: GLdouble){.stdcall, importc, ogl.}
proc glMatrixPopEXT*(mode: GLenum){.stdcall, importc, ogl.}
proc glMatrixPushEXT*(mode: GLenum){.stdcall, importc, ogl.}
proc glMatrixLoadTransposefEXT*(mode: GLenum, m: PGLfloat){.stdcall, importc, ogl.}
proc glMatrixLoadTransposedEXT*(mode: GLenum, m: PGLdouble){.stdcall, importc, ogl.}
proc glMatrixMultTransposefEXT*(mode: GLenum, m: PGLfloat){.stdcall, importc, ogl.}
proc glMatrixMultTransposedEXT*(mode: GLenum, m: PGLdouble){.stdcall, importc, ogl.}
proc glTextureParameterfEXT*(texture: GLuint, target: GLenum, pname: GLenum,
                             param: GLfloat){.stdcall, importc, ogl.}
proc glTextureParameterfvEXT*(texture: GLuint, target: GLenum, pname: GLenum,
                              params: PGLfloat){.stdcall, importc, ogl.}
proc glTextureParameteriEXT*(texture: GLuint, target: GLenum, pname: GLenum,
                             param: GLint){.stdcall, importc, ogl.}
proc glTextureParameterivEXT*(texture: GLuint, target: GLenum, pname: GLenum,
                              params: PGLint){.stdcall, importc, ogl.}
proc glTextureImage1DEXT*(texture: GLuint, target: GLenum, level: GLint,
                          internalformat: GLenum, width: GLsizei, border: GLint,
                          format: GLenum, typ: GLenum, pixels: PGLvoid){.stdcall, importc, ogl.}
proc glTextureImage2DEXT*(texture: GLuint, target: GLenum, level: GLint,
                          internalformat: GLenum, width: GLsizei,
                          height: GLsizei, border: GLint, format: GLenum,
                          typ: GLenum, pixels: PGLvoid){.stdcall, importc, ogl.}
proc glTextureSubImage1DEXT*(texture: GLuint, target: GLenum, level: GLint,
                             xoffset: GLint, width: GLsizei, format: GLenum,
                             typ: GLenum, pixels: PGLvoid){.stdcall, importc, ogl.}
proc glTextureSubImage2DEXT*(texture: GLuint, target: GLenum, level: GLint,
                             xoffset: GLint, yoffset: GLint, width: GLsizei,
                             height: GLsizei, format: GLenum, typ: GLenum,
                             pixels: PGLvoid){.stdcall, importc, ogl.}
proc glCopyTextureImage1DEXT*(texture: GLuint, target: GLenum, level: GLint,
                              internalformat: GLenum, x: GLint, y: GLint,
                              width: GLsizei, border: GLint){.stdcall, importc, ogl.}
proc glCopyTextureImage2DEXT*(texture: GLuint, target: GLenum, level: GLint,
                              internalformat: GLenum, x: GLint, y: GLint,
                              width: GLsizei, height: GLsizei, border: GLint){.
    stdcall, importc, ogl.}
proc glCopyTextureSubImage1DEXT*(texture: GLuint, target: GLenum, level: GLint,
                                 xoffset: GLint, x: GLint, y: GLint,
                                 width: GLsizei){.stdcall, importc, ogl.}
proc glCopyTextureSubImage2DEXT*(texture: GLuint, target: GLenum, level: GLint,
                                 xoffset: GLint, yoffset: GLint, x: GLint,
                                 y: GLint, width: GLsizei, height: GLsizei){.
    stdcall, importc, ogl.}
proc glGetTextureImageEXT*(texture: GLuint, target: GLenum, level: GLint,
                           format: GLenum, typ: GLenum, pixels: PGLvoid){.
    stdcall, importc, ogl.}
proc glGetTextureParameterfvEXT*(texture: GLuint, target: GLenum, pname: GLenum,
                                 params: PGLfloat){.stdcall, importc, ogl.}
proc glGetTextureParameterivEXT*(texture: GLuint, target: GLenum, pname: GLenum,
                                 params: PGLint){.stdcall, importc, ogl.}
proc glGetTextureLevelParameterfvEXT*(texture: GLuint, target: GLenum,
                                      level: GLint, pname: GLenum,
                                      params: PGLfloat){.stdcall, importc, ogl.}
proc glGetTextureLevelParameterivEXT*(texture: GLuint, target: GLenum,
                                      level: GLint, pname: GLenum, params: GLint){.
    stdcall, importc, ogl.}
proc glTextureImage3DEXT*(texture: GLuint, target: GLenum, level: GLint,
                          internalformat: GLenum, width: GLsizei,
                          height: GLsizei, depth: GLsizei, border: GLint,
                          format: GLenum, typ: GLenum, pixels: PGLvoid){.stdcall, importc, ogl.}
proc glTextureSubImage3DEXT*(texture: GLuint, target: GLenum, level: GLint,
                             xoffset: GLint, yoffset: GLint, zoffset: GLint,
                             width: GLsizei, height: GLsizei, depth: GLsizei,
                             format: GLenum, typ: GLenum, pixels: PGLvoid){.
    stdcall, importc, ogl.}
proc glCopyTextureSubImage3DEXT*(texture: GLuint, target: GLenum, level: GLint,
                                 xoffset: GLint, yoffset: GLint, zoffset: GLint,
                                 x: GLint, y: GLint, width: GLsizei,
                                 height: GLsizei){.stdcall, importc, ogl.}
proc glMultiTexParameterfEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                              param: GLfloat){.stdcall, importc, ogl.}
proc glMultiTexParameterfvEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                               params: PGLfloat){.stdcall, importc, ogl.}
proc glMultiTexParameteriEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                              param: GLint){.stdcall, importc, ogl.}
proc glMultiTexParameterivEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                               params: PGLint){.stdcall, importc, ogl.}
proc glMultiTexImage1DEXT*(texunit: GLenum, target: GLenum, level: GLint,
                           internalformat: GLenum, width: GLsizei,
                           border: GLint, format: GLenum, typ: GLenum,
                           pixels: PGLvoid){.stdcall, importc, ogl.}
proc glMultiTexImage2DEXT*(texunit: GLenum, target: GLenum, level: GLint,
                           internalformat: GLenum, width: GLsizei,
                           height: GLsizei, border: GLint, format: GLenum,
                           typ: GLenum, pixels: PGLvoid){.stdcall, importc, ogl.}
proc glMultiTexSubImage1DEXT*(texunit: GLenum, target: GLenum, level: GLint,
                              xoffset: GLint, width: GLsizei, format: GLenum,
                              typ: GLenum, pixels: PGLvoid){.stdcall, importc, ogl.}
proc glMultiTexSubImage2DEXT*(texunit: GLenum, target: GLenum, level: GLint,
                              xoffset: GLint, yoffset: GLint, width: GLsizei,
                              height: GLsizei, format: GLenum, typ: GLenum,
                              pixels: PGLvoid){.stdcall, importc, ogl.}
proc glCopyMultiTexImage1DEXT*(texunit: GLenum, target: GLenum, level: GLint,
                               internalformat: GLenum, x: GLint, y: GLint,
                               width: GLsizei, border: GLint){.stdcall, importc, ogl.}
proc glCopyMultiTexImage2DEXT*(texunit: GLenum, target: GLenum, level: GLint,
                               internalformat: GLenum, x: GLint, y: GLint,
                               width: GLsizei, height: GLsizei, border: GLint){.
    stdcall, importc, ogl.}
proc glCopyMultiTexSubImage1DEXT*(texunit: GLenum, target: GLenum, level: GLint,
                                  xoffset: GLint, x: GLint, y: GLint,
                                  width: GLsizei){.stdcall, importc, ogl.}
proc glCopyMultiTexSubImage2DEXT*(texunit: GLenum, target: GLenum, level: GLint,
                                  xoffset: GLint, yoffset: GLint, x: GLint,
                                  y: GLint, width: GLsizei, height: GLsizei){.
    stdcall, importc, ogl.}
proc glGetMultiTexImageEXT*(texunit: GLenum, target: GLenum, level: GLint,
                            format: GLenum, typ: GLenum, pixels: PGLvoid){.
    stdcall, importc, ogl.}
proc glGetMultiTexParameterfvEXT*(texunit: GLenum, target: GLenum,
                                  pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glGetMultiTexParameterivEXT*(texunit: GLenum, target: GLenum,
                                  pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetMultiTexLevelParameterfvEXT*(texunit: GLenum, target: GLenum,
                                       level: GLint, pname: GLenum,
                                       params: PGLfloat){.stdcall, importc, ogl.}
proc glGetMultiTexLevelParameterivEXT*(texunit: GLenum, target: GLenum,
                                       level: GLint, pname: GLenum,
                                       params: PGLint){.stdcall, importc, ogl.}
proc glMultiTexImage3DEXT*(texunit: GLenum, target: GLenum, level: GLint,
                           internalformat: GLenum, width: GLsizei,
                           height: GLsizei, depth: GLsizei, border: GLint,
                           format: GLenum, typ: GLenum, pixels: PGLvoid){.
    stdcall, importc, ogl.}
proc glMultiTexSubImage3DEXT*(texunit: GLenum, target: GLenum, level: GLint,
                              xoffset: GLint, yoffset: GLint, zoffset: GLint,
                              width: GLsizei, height: GLsizei, depth: GLsizei,
                              format: GLenum, typ: GLenum, pixels: PGLvoid){.
    stdcall, importc, ogl.}
proc glCopyMultiTexSubImage3DEXT*(texunit: GLenum, target: GLenum, level: GLint,
                                  xoffset: GLint, yoffset: GLint,
                                  zoffset: GLint, x: GLint, y: GLint,
                                  width: GLsizei, height: GLsizei){.stdcall, importc, ogl.}
proc glBindMultiTextureEXT*(texunit: GLenum, target: GLenum, texture: GLuint){.
    stdcall, importc, ogl.}
proc glEnableClientStateIndexedEXT*(arr: GLenum, index: GLuint){.stdcall, importc, ogl.}
proc glDisableClientStateIndexedEXT*(arr: GLenum, index: GLuint){.stdcall, importc, ogl.}
proc glMultiTexCoordPointerEXT*(texunit: GLenum, size: GLint, typ: GLenum,
                                stride: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glMultiTexEnvfEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                        param: GLfloat){.stdcall, importc, ogl.}
proc glMultiTexEnvfvEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                         params: PGLfloat){.stdcall, importc, ogl.}
proc glMultiTexEnviEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                        param: GLint){.stdcall, importc, ogl.}
proc glMultiTexEnvivEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                         params: PGLint){.stdcall, importc, ogl.}
proc glMultiTexGendEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                        param: GLdouble){.stdcall, importc, ogl.}
proc glMultiTexGendvEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                         params: PGLdouble){.stdcall, importc, ogl.}
proc glMultiTexGenfEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                        param: GLfloat){.stdcall, importc, ogl.}
proc glMultiTexGenfvEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                         params: PGLfloat){.stdcall, importc, ogl.}
proc glMultiTexGeniEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                        param: GLint){.stdcall, importc, ogl.}
proc glMultiTexGenivEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                         params: PGLint){.stdcall, importc, ogl.}
proc glGetMultiTexEnvfvEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                            params: PGLfloat){.stdcall, importc, ogl.}
proc glGetMultiTexEnvivEXT*(texunit: GLenum, target: GLenum, pname: GLenum,
                            params: PGLint){.stdcall, importc, ogl.}
proc glGetMultiTexGendvEXT*(texunit: GLenum, coord: GLenum, pname: GLenum,
                            params: PGLdouble){.stdcall, importc, ogl.}
proc glGetMultiTexGenfvEXT*(texunit: GLenum, coord: GLenum, pname: GLenum,
                            params: PGLfloat){.stdcall, importc, ogl.}
proc glGetMultiTexGenivEXT*(texunit: GLenum, coord: GLenum, pname: GLenum,
                            params: PGLint){.stdcall, importc, ogl.}
proc glGetFloatIndexedvEXT*(target: GLenum, index: GLuint, data: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetDoubleIndexedvEXT*(target: GLenum, index: GLuint, data: PGLdouble){.
    stdcall, importc, ogl.}
proc glGetPointerIndexedvEXT*(target: GLenum, index: GLuint, data: PPGLvoid){.
    stdcall, importc, ogl.}
proc glCompressedTextureImage3DEXT*(texture: GLuint, target: GLenum,
                                    level: GLint, internalformat: GLenum,
                                    width: GLsizei, height: GLsizei,
                                    depth: GLsizei, border: GLint,
                                    imageSize: GLsizei, bits: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedTextureImage2DEXT*(texture: GLuint, target: GLenum,
                                    level: GLint, internalformat: GLenum,
                                    width: GLsizei, height: GLsizei,
                                    border: GLint, imageSize: GLsizei,
                                    bits: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedTextureImage1DEXT*(texture: GLuint, target: GLenum,
                                    level: GLint, internalformat: GLenum,
                                    width: GLsizei, border: GLint,
                                    imageSize: GLsizei, bits: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedTextureSubImage3DEXT*(texture: GLuint, target: GLenum,
                                       level: GLint, xoffset: GLint,
                                       yoffset: GLint, zoffset: GLint,
                                       width: GLsizei, height: GLsizei,
                                       depth: GLsizei, format: GLenum,
                                       imageSize: GLsizei, bits: PGLvoid){.
    stdcall, importc, ogl.}
proc glCompressedTextureSubImage2DEXT*(texture: GLuint, target: GLenum,
                                       level: GLint, xoffset: GLint,
                                       yoffset: GLint, width: GLsizei,
                                       height: GLsizei, format: GLenum,
                                       imageSize: GLsizei, bits: PGLvoid){.
    stdcall, importc, ogl.}
proc glCompressedTextureSubImage1DEXT*(texture: GLuint, target: GLenum,
                                       level: GLint, xoffset: GLint,
                                       width: GLsizei, format: GLenum,
                                       imageSize: GLsizei, bits: PGLvoid){.
    stdcall, importc, ogl.}
proc glGetCompressedTextureImageEXT*(texture: GLuint, target: GLenum,
                                     lod: GLint, img: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedMultiTexImage3DEXT*(texunit: GLenum, target: GLenum,
                                     level: GLint, internalformat: GLenum,
                                     width: GLsizei, height: GLsizei,
                                     depth: GLsizei, border: GLint,
                                     imageSize: GLsizei, bits: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedMultiTexImage2DEXT*(texunit: GLenum, target: GLenum,
                                     level: GLint, internalformat: GLenum,
                                     width: GLsizei, height: GLsizei,
                                     border: GLint, imageSize: GLsizei,
                                     bits: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedMultiTexImage1DEXT*(texunit: GLenum, target: GLenum,
                                     level: GLint, internalformat: GLenum,
                                     width: GLsizei, border: GLint,
                                     imageSize: GLsizei, bits: PGLvoid){.stdcall, importc, ogl.}
proc glCompressedMultiTexSubImage3DEXT*(texunit: GLenum, target: GLenum,
                                        level: GLint, xoffset: GLint,
                                        yoffset: GLint, zoffset: GLint,
                                        width: GLsizei, height: GLsizei,
                                        depth: GLsizei, format: GLenum,
                                        imageSize: GLsizei, bits: PGLvoid){.
    stdcall, importc, ogl.}
proc glCompressedMultiTexSubImage2DEXT*(texunit: GLenum, target: GLenum,
                                        level: GLint, xoffset: GLint,
                                        yoffset: GLint, width: GLsizei,
                                        height: GLsizei, format: GLenum,
                                        imageSize: GLsizei, bits: PGLvoid){.
    stdcall, importc, ogl.}
proc glCompressedMultiTexSubImage1DEXT*(texunit: GLenum, target: GLenum,
                                        level: GLint, xoffset: GLint,
                                        width: GLsizei, format: GLenum,
                                        imageSize: GLsizei, bits: PGLvoid){.
    stdcall, importc, ogl.}
proc glGetCompressedMultiTexImageEXT*(texunit: GLenum, target: GLenum,
                                      lod: GLint, img: PGLvoid){.stdcall, importc, ogl.}
proc glNamedProgramStringEXT*(prog: GLuint, target: GLenum, format: GLenum,
                              length: GLsizei, string: PGLvoid){.stdcall, importc, ogl.}
proc glNamedProgramLocalParameter4dEXT*(prog: GLuint, target: GLenum,
                                        index: GLuint, x: GLdouble, y: GLdouble,
                                        z: GLdouble, w: GLdouble){.stdcall, importc, ogl.}
proc glNamedProgramLocalParameter4dvEXT*(prog: GLuint, target: GLenum,
    index: GLuint, params: PGLdouble){.stdcall, importc, ogl.}
proc glNamedProgramLocalParameter4fEXT*(prog: GLuint, target: GLenum,
                                        index: GLuint, x: GLfloat, y: GLfloat,
                                        z: GLfloat, w: GLfloat){.stdcall, importc, ogl.}
proc glNamedProgramLocalParameter4fvEXT*(prog: GLuint, target: GLenum,
    index: GLuint, params: PGLfloat){.stdcall, importc, ogl.}
proc glGetNamedProgramLocalParameterdvEXT*(prog: GLuint, target: GLenum,
    index: GLuint, params: PGLdouble){.stdcall, importc, ogl.}
proc glGetNamedProgramLocalParameterfvEXT*(prog: GLuint, target: GLenum,
    index: GLuint, params: PGLfloat){.stdcall, importc, ogl.}
proc glGetNamedProgramivEXT*(prog: GLuint, target: GLenum, pname: GLenum,
                             params: PGLint){.stdcall, importc, ogl.}
proc glGetNamedProgramStringEXT*(prog: GLuint, target: GLenum, pname: GLenum,
                                 string: PGLvoid){.stdcall, importc, ogl.}
proc glNamedProgramLocalParameters4fvEXT*(prog: GLuint, target: GLenum,
    index: GLuint, count: GLsizei, params: PGLfloat){.stdcall, importc, ogl.}
proc glNamedProgramLocalParameterI4iEXT*(prog: GLuint, target: GLenum,
    index: GLuint, x: GLint, y: GLint, z: GLint, w: GLint){.stdcall, importc, ogl.}
proc glNamedProgramLocalParameterI4ivEXT*(prog: GLuint, target: GLenum,
    index: GLuint, params: PGLint){.stdcall, importc, ogl.}
proc glNamedProgramLocalParametersI4ivEXT*(prog: GLuint, target: GLenum,
    index: GLuint, count: GLsizei, params: PGLint){.stdcall, importc, ogl.}
proc glNamedProgramLocalParameterI4uiEXT*(prog: GLuint, target: GLenum,
    index: GLuint, x: GLuint, y: GLuint, z: GLuint, w: GLuint){.stdcall, importc, ogl.}
proc glNamedProgramLocalParameterI4uivEXT*(prog: GLuint, target: GLenum,
    index: GLuint, params: PGLuint){.stdcall, importc, ogl.}
proc glNamedProgramLocalParametersI4uivEXT*(prog: GLuint, target: GLenum,
    index: GLuint, count: GLsizei, params: PGLuint){.stdcall, importc, ogl.}
proc glGetNamedProgramLocalParameterIivEXT*(prog: GLuint, target: GLenum,
    index: GLuint, params: PGLint){.stdcall, importc, ogl.}
proc glGetNamedProgramLocalParameterIuivEXT*(prog: GLuint, target: GLenum,
    index: GLuint, params: PGLuint){.stdcall, importc, ogl.}
proc glTextureParameterIivEXT*(texture: GLuint, target: GLenum, pname: GLenum,
                               params: PGLint){.stdcall, importc, ogl.}
proc glTextureParameterIuivEXT*(texture: GLuint, target: GLenum, pname: GLenum,
                                params: PGLuint){.stdcall, importc, ogl.}
proc glGetTextureParameterIivEXT*(texture: GLuint, target: GLenum,
                                  pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetTextureParameterIuivEXT*(texture: GLuint, target: GLenum,
                                   pname: GLenum, params: PGLuint){.stdcall, importc, ogl.}
proc glMultiTexParameterIivEXT*(texture: GLuint, target: GLenum, pname: GLenum,
                                params: PGLint){.stdcall, importc, ogl.}
proc glMultiTexParameterIuivEXT*(texture: GLuint, target: GLenum, pname: GLenum,
                                 params: PGLuint){.stdcall, importc, ogl.}
proc glGetMultiTexParameterIivEXT*(texture: GLuint, target: GLenum,
                                   pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetMultiTexParameterIuivEXT*(texture: GLuint, target: GLenum,
                                    pname: GLenum, params: PGLuint){.stdcall, importc, ogl.}
proc glProgramUniform1fEXT*(prog: GLuint, location: GLint, v0: GLfloat){.stdcall, importc, ogl.}
proc glProgramUniform2fEXT*(prog: GLuint, location: GLint, v0: GLfloat,
                            v1: GLfloat){.stdcall, importc, ogl.}
proc glProgramUniform3fEXT*(prog: GLuint, location: GLint, v0: GLfloat,
                            v1: GLfloat, v2: GLfloat){.stdcall, importc, ogl.}
proc glProgramUniform4fEXT*(prog: GLuint, location: GLint, v0: GLfloat,
                            v1: GLfloat, v2: GLfloat, v3: GLfloat){.stdcall, importc, ogl.}
proc glProgramUniform1iEXT*(prog: GLuint, location: GLint, v0: GLint){.stdcall, importc, ogl.}
proc glProgramUniform2iEXT*(prog: GLuint, location: GLint, v0: GLint, v1: GLint){.
    stdcall, importc, ogl.}
proc glProgramUniform3iEXT*(prog: GLuint, location: GLint, v0: GLint, v1: GLint,
                            v2: GLint){.stdcall, importc, ogl.}
proc glProgramUniform4iEXT*(prog: GLuint, location: GLint, v0: GLint, v1: GLint,
                            v2: GLint, v3: GLint){.stdcall, importc, ogl.}
proc glProgramUniform1fvEXT*(prog: GLuint, location: GLint, count: GLsizei,
                             value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniform2fvEXT*(prog: GLuint, location: GLint, count: GLsizei,
                             value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniform3fvEXT*(prog: GLuint, location: GLint, count: GLsizei,
                             value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniform4fvEXT*(prog: GLuint, location: GLint, count: GLsizei,
                             value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniform1ivEXT*(prog: GLuint, location: GLint, count: GLsizei,
                             value: PGLint){.stdcall, importc, ogl.}
proc glProgramUniform2ivEXT*(prog: GLuint, location: GLint, count: GLsizei,
                             value: PGLint){.stdcall, importc, ogl.}
proc glProgramUniform3ivEXT*(prog: GLuint, location: GLint, count: GLsizei,
                             value: PGLint){.stdcall, importc, ogl.}
proc glProgramUniform4ivEXT*(prog: GLuint, location: GLint, count: GLsizei,
                             value: PGLint){.stdcall, importc, ogl.}
proc glProgramUniformMatrix2fvEXT*(prog: GLuint, location: GLint,
                                   count: GLsizei, transpose: GLboolean,
                                   value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniformMatrix3fvEXT*(prog: GLuint, location: GLint,
                                   count: GLsizei, transpose: GLboolean,
                                   value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniformMatrix4fvEXT*(prog: GLuint, location: GLint,
                                   count: GLsizei, transpose: GLboolean,
                                   value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniformMatrix2x3fvEXT*(prog: GLuint, location: GLint,
                                     count: GLsizei, transpose: GLboolean,
                                     value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniformMatrix3x2fvEXT*(prog: GLuint, location: GLint,
                                     count: GLsizei, transpose: GLboolean,
                                     value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniformMatrix2x4fvEXT*(prog: GLuint, location: GLint,
                                     count: GLsizei, transpose: GLboolean,
                                     value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniformMatrix4x2fvEXT*(prog: GLuint, location: GLint,
                                     count: GLsizei, transpose: GLboolean,
                                     value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniformMatrix3x4fvEXT*(prog: GLuint, location: GLint,
                                     count: GLsizei, transpose: GLboolean,
                                     value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniformMatrix4x3fvEXT*(prog: GLuint, location: GLint,
                                     count: GLsizei, transpose: GLboolean,
                                     value: PGLfloat){.stdcall, importc, ogl.}
proc glProgramUniform1uiEXT*(prog: GLuint, location: GLint, v0: GLuint){.stdcall, importc, ogl.}
proc glProgramUniform2uiEXT*(prog: GLuint, location: GLint, v0: GLuint,
                             v1: GLuint){.stdcall, importc, ogl.}
proc glProgramUniform3uiEXT*(prog: GLuint, location: GLint, v0: GLuint,
                             v1: GLuint, v2: GLuint){.stdcall, importc, ogl.}
proc glProgramUniform4uiEXT*(prog: GLuint, location: GLint, v0: GLuint,
                             v1: GLuint, v2: GLuint, v3: GLuint){.stdcall, importc, ogl.}
proc glProgramUniform1uivEXT*(prog: GLuint, location: GLint, count: GLsizei,
                              value: PGLuint){.stdcall, importc, ogl.}
proc glProgramUniform2uivEXT*(prog: GLuint, location: GLint, count: GLsizei,
                              value: PGLuint){.stdcall, importc, ogl.}
proc glProgramUniform3uivEXT*(prog: GLuint, location: GLint, count: GLsizei,
                              value: PGLuint){.stdcall, importc, ogl.}
proc glProgramUniform4uivEXT*(prog: GLuint, location: GLint, count: GLsizei,
                              value: PGLuint){.stdcall, importc, ogl.}
proc glNamedBufferDataEXT*(buffer: GLuint, size: GLsizei, data: PGLvoid,
                           usage: GLenum){.stdcall, importc, ogl.}
proc glNamedBufferSubDataEXT*(buffer: GLuint, offset: GLintptr,
                              size: GLsizeiptr, data: PGLvoid){.stdcall, importc, ogl.}
proc glMapNamedBufferEXT*(buffer: GLuint, access: GLenum): PGLvoid{.stdcall, importc, ogl.}
proc glUnmapNamedBufferEXT*(buffer: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glMapNamedBufferRangeEXT*(buffer: GLuint, offset: GLintptr,
                               len: GLsizeiptr, access: GLbitfield): PGLvoid{.
    stdcall, importc, ogl.}
proc glFlushMappedNamedBufferRangeEXT*(buffer: GLuint, offset: GLintptr,
                                       len: GLsizeiptr){.stdcall, importc, ogl.}
proc glNamedCopyBufferSubDataEXT*(readBuffer: GLuint, writeBuffer: GLuint,
                                  readOffset: GLintptr, writeOffset: GLintptr,
                                  size: GLsizeiptr){.stdcall, importc, ogl.}
proc glGetNamedBufferParameterivEXT*(buffer: GLuint, pname: GLenum,
                                     params: PGLint){.stdcall, importc, ogl.}
proc glGetNamedBufferPointervEXT*(buffer: GLuint, pname: GLenum,
                                  params: PPGLvoid){.stdcall, importc, ogl.}
proc glGetNamedBufferSubDataEXT*(buffer: GLuint, offset: GLintptr,
                                 size: GLsizeiptr, data: PGLvoid){.stdcall, importc, ogl.}
proc glTextureBufferEXT*(texture: GLuint, target: GLenum,
                         internalformat: GLenum, buffer: GLuint){.stdcall, importc, ogl.}
proc glMultiTexBufferEXT*(texunit: GLenum, target: GLenum, interformat: GLenum,
                          buffer: GLuint){.stdcall, importc, ogl.}
proc glNamedRenderbufferStorageEXT*(renderbuffer: GLuint, interformat: GLenum,
                                    width: GLsizei, height: GLsizei){.stdcall, importc, ogl.}
proc glGetNamedRenderbufferParameterivEXT*(renderbuffer: GLuint, pname: GLenum,
    params: PGLint){.stdcall, importc, ogl.}
proc glCheckNamedFramebufferStatusEXT*(framebuffer: GLuint, target: GLenum): GLenum{.
    stdcall, importc, ogl.}
proc glNamedFramebufferTexture1DEXT*(framebuffer: GLuint, attachment: GLenum,
                                     textarget: GLenum, texture: GLuint,
                                     level: GLint){.stdcall, importc, ogl.}
proc glNamedFramebufferTexture2DEXT*(framebuffer: GLuint, attachment: GLenum,
                                     textarget: GLenum, texture: GLuint,
                                     level: GLint){.stdcall, importc, ogl.}
proc glNamedFramebufferTexture3DEXT*(framebuffer: GLuint, attachment: GLenum,
                                     textarget: GLenum, texture: GLuint,
                                     level: GLint, zoffset: GLint){.stdcall, importc, ogl.}
proc glNamedFramebufferRenderbufferEXT*(framebuffer: GLuint, attachment: GLenum,
                                        renderbuffertarget: GLenum,
                                        renderbuffer: GLuint){.stdcall, importc, ogl.}
proc glGetNamedFramebufferAttachmentParameterivEXT*(framebuffer: GLuint,
    attachment: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGenerateTextureMipmapEXT*(texture: GLuint, target: GLenum){.stdcall, importc, ogl.}
proc glGenerateMultiTexMipmapEXT*(texunit: GLenum, target: GLenum){.stdcall, importc, ogl.}
proc glFramebufferDrawBufferEXT*(framebuffer: GLuint, mode: GLenum){.stdcall, importc, ogl.}
proc glFramebufferDrawBuffersEXT*(framebuffer: GLuint, n: GLsizei, bufs: PGLenum){.
    stdcall, importc, ogl.}
proc glFramebufferReadBufferEXT*(framebuffer: GLuint, mode: GLenum){.stdcall, importc, ogl.}
proc glGetFramebufferParameterivEXT*(framebuffer: GLuint, pname: GLenum,
                                     params: PGLint){.stdcall, importc, ogl.}
proc glNamedRenderbufferStorageMultisampleEXT*(renderbuffer: GLuint,
    samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei){.
    stdcall, importc, ogl.}
proc glNamedRenderbufferStorageMultisampleCoverageEXT*(renderbuffer: GLuint,
    coverageSamples: GLsizei, colorSamples: GLsizei, internalformat: GLenum,
    width: GLsizei, height: GLsizei){.stdcall, importc, ogl.}
proc glNamedFramebufferTextureEXT*(framebuffer: GLuint, attachment: GLenum,
                                   texture: GLuint, level: GLint){.stdcall, importc, ogl.}
proc glNamedFramebufferTextureLayerEXT*(framebuffer: GLuint, attachment: GLenum,
                                        texture: GLuint, level: GLint,
                                        layer: GLint){.stdcall, importc, ogl.}
proc glNamedFramebufferTextureFaceEXT*(framebuffer: GLuint, attachment: GLenum,
                                       texture: GLuint, level: GLint,
                                       face: GLenum){.stdcall, importc, ogl.}
proc glTextureRenderbufferEXT*(texture: GLuint, target: GLenum,
                               renderbuffer: GLuint){.stdcall, importc, ogl.}
proc glMultiTexRenderbufferEXT*(texunit: GLenum, target: GLenum,
                                renderbuffer: GLuint){.stdcall, importc, ogl.}
proc glProgramUniform1dEXT*(prog: GLuint, location: GLint, x: GLdouble){.stdcall, importc, ogl.}
proc glProgramUniform2dEXT*(prog: GLuint, location: GLint, x: GLdouble,
                            y: GLdouble){.stdcall, importc, ogl.}
proc glProgramUniform3dEXT*(prog: GLuint, location: GLint, x: GLdouble,
                            y: GLdouble, z: GLdouble){.stdcall, importc, ogl.}
proc glProgramUniform4dEXT*(prog: GLuint, location: GLint, x: GLdouble,
                            y: GLdouble, z: GLdouble, w: GLdouble){.stdcall, importc, ogl.}
proc glProgramUniform1dvEXT*(prog: GLuint, location: GLint, count: GLsizei,
                             value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniform2dvEXT*(prog: GLuint, location: GLint, count: GLsizei,
                             value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniform3dvEXT*(prog: GLuint, location: GLint, count: GLsizei,
                             value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniform4dvEXT*(prog: GLuint, location: GLint, count: GLsizei,
                             value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniformMatrix2dvEXT*(prog: GLuint, location: GLint,
                                   count: GLsizei, transpose: GLboolean,
                                   value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniformMatrix3dvEXT*(prog: GLuint, location: GLint,
                                   count: GLsizei, transpose: GLboolean,
                                   value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniformMatrix4dvEXT*(prog: GLuint, location: GLint,
                                   count: GLsizei, transpose: GLboolean,
                                   value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniformMatrix2x3dvEXT*(prog: GLuint, location: GLint,
                                     count: GLsizei, transpose: GLboolean,
                                     value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniformMatrix2x4dvEXT*(prog: GLuint, location: GLint,
                                     count: GLsizei, transpose: GLboolean,
                                     value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniformMatrix3x2dvEXT*(prog: GLuint, location: GLint,
                                     count: GLsizei, transpose: GLboolean,
                                     value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniformMatrix3x4dvEXT*(prog: GLuint, location: GLint,
                                     count: GLsizei, transpose: GLboolean,
                                     value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniformMatrix4x2dvEXT*(prog: GLuint, location: GLint,
                                     count: GLsizei, transpose: GLboolean,
                                     value: PGLdouble){.stdcall, importc, ogl.}
proc glProgramUniformMatrix4x3dvEXT*(prog: GLuint, location: GLint,
                                     count: GLsizei, transpose: GLboolean,
                                     value: PGLdouble){.stdcall, importc, ogl.}
  # GL_EXT_separate_shader_objects
proc glUseShaderProgramEXT*(typ: GLenum, prog: GLuint){.stdcall, importc, ogl.}
proc glActiveProgramEXT*(prog: GLuint){.stdcall, importc, ogl.}
proc glCreateShaderProgramEXT*(typ: GLenum, string: PGLchar): GLuint{.stdcall, importc, ogl.}
  # GL_EXT_shader_image_load_store
proc glBindImageTextureEXT*(index: GLuint, texture: GLuint, level: GLint,
                            layered: GLboolean, layer: GLint, access: GLenum,
                            format: GLint){.stdcall, importc, ogl.}
proc glMemoryBarrierEXT*(barriers: GLbitfield){.stdcall, importc, ogl.}
  # GL_EXT_vertex_attrib_64bit
proc glVertexAttribL1dEXT*(index: GLuint, x: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttribL2dEXT*(index: GLuint, x: GLdouble, y: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttribL3dEXT*(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble){.
    stdcall, importc, ogl.}
proc glVertexAttribL4dEXT*(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble,
                           w: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttribL1dvEXT*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttribL2dvEXT*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttribL3dvEXT*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttribL4dvEXT*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttribLPointerEXT*(index: GLuint, size: GLint, typ: GLenum,
                                stride: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glGetVertexAttribLdvEXT*(index: GLuint, pname: GLenum, params: PGLdouble){.
    stdcall, importc, ogl.}
proc glVertexArrayVertexAttribLOffsetEXT*(vaobj: GLuint, buffer: GLuint,
    index: GLuint, size: GLint, typ: GLenum, stride: GLsizei, offset: GLintptr){.
    stdcall, importc, ogl.}
  # GL_IBM_multimode_draw_arrays
proc glMultiModeDrawArraysIBM*(mode: GLenum, first: PGLint, count: PGLsizei,
                               primcount: GLsizei, modestride: GLint){.stdcall, importc, ogl.}
proc glMultiModeDrawElementsIBM*(mode: PGLenum, count: PGLsizei, typ: GLenum,
                                 indices: PGLvoid, primcount: GLsizei,
                                 modestride: GLint){.stdcall, importc, ogl.}
  # GL_IBM_vertex_array_lists
proc glColorPointerListIBM*(size: GLint, typ: GLenum, stride: GLint,
                            pointer: PGLvoid, ptrstride: GLint){.stdcall, importc, ogl.}
proc glSecondaryColorPointerListIBM*(size: GLint, typ: GLenum, stride: GLint,
                                     pointer: PGLvoid, ptrstride: GLint){.
    stdcall, importc, ogl.}
proc glEdgeFlagPointerListIBM*(stride: GLint, pointer: PGLboolean,
                               ptrstride: GLint){.stdcall, importc, ogl.}
proc glFogCoordPointerListIBM*(typ: GLenum, stride: GLint, pointer: PGLvoid,
                               ptrstride: GLint){.stdcall, importc, ogl.}
proc glIndexPointerListIBM*(typ: GLenum, stride: GLint, pointer: PGLvoid,
                            ptrstride: GLint){.stdcall, importc, ogl.}
proc glNormalPointerListIBM*(typ: GLenum, stride: GLint, pointer: PGLvoid,
                             ptrstride: GLint){.stdcall, importc, ogl.}
proc glTexCoordPointerListIBM*(size: GLint, typ: GLenum, stride: GLint,
                               pointer: PGLvoid, ptrstride: GLint){.stdcall, importc, ogl.}
proc glVertexPointerListIBM*(size: GLint, typ: GLenum, stride: GLint,
                             pointer: PGLvoid, ptrstride: GLint){.stdcall, importc, ogl.}
  # GL_INGR_blend_func_separate
proc glBlendFuncSeparateINGR*(sfactorRGB: GLenum, dfactorRGB: GLenum,
                              sfactorAlpha: GLenum, dfactorAlpha: GLenum){.
    stdcall, importc, ogl.}
  # GL_INTEL_parallel_arrays
proc glVertexPointervINTEL*(size: GLint, typ: GLenum, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glNormalPointervINTEL*(typ: GLenum, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glColorPointervINTEL*(size: GLint, typ: GLenum, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glTexCoordPointervINTEL*(size: GLint, typ: GLenum, pointer: PGLvoid){.
    stdcall, importc, ogl.}
  # GL_MESA_resize_buffers
proc glResizeBuffersMESA*(){.stdcall, importc, ogl.}
  # GL_MESA_window_pos
proc glWindowPos2dMESA*(x: GLdouble, y: GLdouble){.stdcall, importc, ogl.}
proc glWindowPos2dvMESA*(v: PGLdouble){.stdcall, importc, ogl.}
proc glWindowPos2fMESA*(x: GLfloat, y: GLfloat){.stdcall, importc, ogl.}
proc glWindowPos2fvMESA*(v: PGLfloat){.stdcall, importc, ogl.}
proc glWindowPos2iMESA*(x: GLint, y: GLint){.stdcall, importc, ogl.}
proc glWindowPos2ivMESA*(v: PGLint){.stdcall, importc, ogl.}
proc glWindowPos2sMESA*(x: GLshort, y: GLshort){.stdcall, importc, ogl.}
proc glWindowPos2svMESA*(v: PGLshort){.stdcall, importc, ogl.}
proc glWindowPos3dMESA*(x: GLdouble, y: GLdouble, z: GLdouble){.stdcall, importc, ogl.}
proc glWindowPos3dvMESA*(v: PGLdouble){.stdcall, importc, ogl.}
proc glWindowPos3fMESA*(x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glWindowPos3fvMESA*(v: PGLfloat){.stdcall, importc, ogl.}
proc glWindowPos3iMESA*(x: GLint, y: GLint, z: GLint){.stdcall, importc, ogl.}
proc glWindowPos3ivMESA*(v: PGLint){.stdcall, importc, ogl.}
proc glWindowPos3sMESA*(x: GLshort, y: GLshort, z: GLshort){.stdcall, importc, ogl.}
proc glWindowPos3svMESA*(v: PGLshort){.stdcall, importc, ogl.}
proc glWindowPos4dMESA*(x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble){.
    stdcall, importc, ogl.}
proc glWindowPos4dvMESA*(v: PGLdouble){.stdcall, importc, ogl.}
proc glWindowPos4fMESA*(x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat){.stdcall, importc, ogl.}
proc glWindowPos4fvMESA*(v: PGLfloat){.stdcall, importc, ogl.}
proc glWindowPos4iMESA*(x: GLint, y: GLint, z: GLint, w: GLint){.stdcall, importc, ogl.}
proc glWindowPos4ivMESA*(v: PGLint){.stdcall, importc, ogl.}
proc glWindowPos4sMESA*(x: GLshort, y: GLshort, z: GLshort, w: GLshort){.stdcall, importc, ogl.}
proc glWindowPos4svMESA*(v: PGLshort){.stdcall, importc, ogl.}
  # GL_NV_evaluators
proc glMapControlPointsNV*(target: GLenum, index: GLuint, typ: GLenum,
                           ustride: GLsizei, vstride: GLsizei, uorder: GLint,
                           vorder: GLint, pack: GLboolean, points: PGLvoid){.
    stdcall, importc, ogl.}
proc glMapParameterivNV*(target: GLenum, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glMapParameterfvNV*(target: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetMapControlPointsNV*(target: GLenum, index: GLuint, typ: GLenum,
                              ustride: GLsizei, vstride: GLsizei,
                              pack: GLboolean, points: PGLvoid){.stdcall, importc, ogl.}
proc glGetMapParameterivNV*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetMapParameterfvNV*(target: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetMapAttribParameterivNV*(target: GLenum, index: GLuint, pname: GLenum,
                                  params: PGLint){.stdcall, importc, ogl.}
proc glGetMapAttribParameterfvNV*(target: GLenum, index: GLuint, pname: GLenum,
                                  params: PGLfloat){.stdcall, importc, ogl.}
proc glEvalMapsNV*(target: GLenum, mode: GLenum){.stdcall, importc, ogl.}
  # GL_NV_fence
proc glDeleteFencesNV*(n: GLsizei, fences: PGLuint){.stdcall, importc, ogl.}
proc glGenFencesNV*(n: GLsizei, fences: PGLuint){.stdcall, importc, ogl.}
proc glIsFenceNV*(fence: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glTestFenceNV*(fence: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glGetFenceivNV*(fence: GLuint, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glFinishFenceNV*(fence: GLuint){.stdcall, importc, ogl.}
proc glSetFenceNV*(fence: GLuint, condition: GLenum){.stdcall, importc, ogl.}
  # GL_NV_fragment_prog
proc glProgramNamedParameter4fNV*(id: GLuint, length: GLsizei, name: PGLubyte,
                                  x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat){.
    stdcall, importc, ogl.}
proc glProgramNamedParameter4dNV*(id: GLuint, length: GLsizei, name: PGLubyte,
                                  x: GLdouble, y: GLdouble, z: GLdouble,
                                  w: GLdouble){.stdcall, importc, ogl.}
proc glProgramNamedParameter4fvNV*(id: GLuint, length: GLsizei, name: PGLubyte,
                                   v: PGLfloat){.stdcall, importc, ogl.}
proc glProgramNamedParameter4dvNV*(id: GLuint, length: GLsizei, name: PGLubyte,
                                   v: PGLdouble){.stdcall, importc, ogl.}
proc glGetProgramNamedParameterfvNV*(id: GLuint, length: GLsizei,
                                     name: PGLubyte, params: PGLfloat){.stdcall, importc, ogl.}
proc glGetProgramNamedParameterdvNV*(id: GLuint, length: GLsizei,
                                     name: PGLubyte, params: PGLdouble){.stdcall, importc, ogl.}
  # GL_NV_half_float
proc glVertex2hNV*(x: GLhalfNV, y: GLhalfNV){.stdcall, importc, ogl.}
proc glVertex2hvNV*(v: PGLhalfNV){.stdcall, importc, ogl.}
proc glVertex3hNV*(x: GLhalfNV, y: GLhalfNV, z: GLhalfNV){.stdcall, importc, ogl.}
proc glVertex3hvNV*(v: PGLhalfNV){.stdcall, importc, ogl.}
proc glVertex4hNV*(x: GLhalfNV, y: GLhalfNV, z: GLhalfNV, w: GLhalfNV){.stdcall, importc, ogl.}
proc glVertex4hvNV*(v: PGLhalfNV){.stdcall, importc, ogl.}
proc glNormal3hNV*(nx: GLhalfNV, ny: GLhalfNV, nz: GLhalfNV){.stdcall, importc, ogl.}
proc glNormal3hvNV*(v: PGLhalfNV){.stdcall, importc, ogl.}
proc glColor3hNV*(red: GLhalfNV, green: GLhalfNV, blue: GLhalfNV){.stdcall, importc, ogl.}
proc glColor3hvNV*(v: PGLhalfNV){.stdcall, importc, ogl.}
proc glColor4hNV*(red: GLhalfNV, green: GLhalfNV, blue: GLhalfNV,
                  alpha: GLhalfNV){.stdcall, importc, ogl.}
proc glColor4hvNV*(v: PGLhalfNV){.stdcall, importc, ogl.}
proc glTexCoord1hNV*(s: GLhalfNV){.stdcall, importc, ogl.}
proc glTexCoord1hvNV*(v: PGLhalfNV){.stdcall, importc, ogl.}
proc glTexCoord2hNV*(s: GLhalfNV, t: GLhalfNV){.stdcall, importc, ogl.}
proc glTexCoord2hvNV*(v: PGLhalfNV){.stdcall, importc, ogl.}
proc glTexCoord3hNV*(s: GLhalfNV, t: GLhalfNV, r: GLhalfNV){.stdcall, importc, ogl.}
proc glTexCoord3hvNV*(v: PGLhalfNV){.stdcall, importc, ogl.}
proc glTexCoord4hNV*(s: GLhalfNV, t: GLhalfNV, r: GLhalfNV, q: GLhalfNV){.
    stdcall, importc, ogl.}
proc glTexCoord4hvNV*(v: PGLhalfNV){.stdcall, importc, ogl.}
proc glMultiTexCoord1hNV*(target: GLenum, s: GLhalfNV){.stdcall, importc, ogl.}
proc glMultiTexCoord1hvNV*(target: GLenum, v: PGLhalfNV){.stdcall, importc, ogl.}
proc glMultiTexCoord2hNV*(target: GLenum, s: GLhalfNV, t: GLhalfNV){.stdcall, importc, ogl.}
proc glMultiTexCoord2hvNV*(target: GLenum, v: PGLhalfNV){.stdcall, importc, ogl.}
proc glMultiTexCoord3hNV*(target: GLenum, s: GLhalfNV, t: GLhalfNV, r: GLhalfNV){.
    stdcall, importc, ogl.}
proc glMultiTexCoord3hvNV*(target: GLenum, v: PGLhalfNV){.stdcall, importc, ogl.}
proc glMultiTexCoord4hNV*(target: GLenum, s: GLhalfNV, t: GLhalfNV, r: GLhalfNV,
                          q: GLhalfNV){.stdcall, importc, ogl.}
proc glMultiTexCoord4hvNV*(target: GLenum, v: PGLhalfNV){.stdcall, importc, ogl.}
proc glFogCoordhNV*(fog: GLhalfNV){.stdcall, importc, ogl.}
proc glFogCoordhvNV*(fog: PGLhalfNV){.stdcall, importc, ogl.}
proc glSecondaryColor3hNV*(red: GLhalfNV, green: GLhalfNV, blue: GLhalfNV){.
    stdcall, importc, ogl.}
proc glSecondaryColor3hvNV*(v: PGLhalfNV){.stdcall, importc, ogl.}
proc glVertexWeighthNV*(weight: GLhalfNV){.stdcall, importc, ogl.}
proc glVertexWeighthvNV*(weight: PGLhalfNV){.stdcall, importc, ogl.}
proc glVertexAttrib1hNV*(index: GLuint, x: GLhalfNV){.stdcall, importc, ogl.}
proc glVertexAttrib1hvNV*(index: GLuint, v: PGLhalfNV){.stdcall, importc, ogl.}
proc glVertexAttrib2hNV*(index: GLuint, x: GLhalfNV, y: GLhalfNV){.stdcall, importc, ogl.}
proc glVertexAttrib2hvNV*(index: GLuint, v: PGLhalfNV){.stdcall, importc, ogl.}
proc glVertexAttrib3hNV*(index: GLuint, x: GLhalfNV, y: GLhalfNV, z: GLhalfNV){.
    stdcall, importc, ogl.}
proc glVertexAttrib3hvNV*(index: GLuint, v: PGLhalfNV){.stdcall, importc, ogl.}
proc glVertexAttrib4hNV*(index: GLuint, x: GLhalfNV, y: GLhalfNV, z: GLhalfNV,
                         w: GLhalfNV){.stdcall, importc, ogl.}
proc glVertexAttrib4hvNV*(index: GLuint, v: PGLhalfNV){.stdcall, importc, ogl.}
proc glVertexAttribs1hvNV*(index: GLuint, n: GLsizei, v: PGLhalfNV){.stdcall, importc, ogl.}
proc glVertexAttribs2hvNV*(index: GLuint, n: GLsizei, v: PGLhalfNV){.stdcall, importc, ogl.}
proc glVertexAttribs3hvNV*(index: GLuint, n: GLsizei, v: PGLhalfNV){.stdcall, importc, ogl.}
proc glVertexAttribs4hvNV*(index: GLuint, n: GLsizei, v: PGLhalfNV){.stdcall, importc, ogl.}
  # GL_NV_occlusion_query
proc glGenOcclusionQueriesNV*(n: GLsizei, ids: PGLuint){.stdcall, importc, ogl.}
proc glDeleteOcclusionQueriesNV*(n: GLsizei, ids: PGLuint){.stdcall, importc, ogl.}
proc glIsOcclusionQueryNV*(id: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glBeginOcclusionQueryNV*(id: GLuint){.stdcall, importc, ogl.}
proc glEndOcclusionQueryNV*(){.stdcall, importc, ogl.}
proc glGetOcclusionQueryivNV*(id: GLuint, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetOcclusionQueryuivNV*(id: GLuint, pname: GLenum, params: PGLuint){.
    stdcall, importc, ogl.}
  # GL_NV_pixel_data_range
proc glPixelDataRangeNV*(target: GLenum, len: GLsizei, pointer: PGLvoid){.
    stdcall, importc, ogl.}
proc glFlushPixelDataRangeNV*(target: GLenum){.stdcall, importc, ogl.}
  # GL_NV_point_sprite
proc glPointParameteriNV*(pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glPointParameterivNV*(pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
  # GL_NV_primitive_restart
proc glPrimitiveRestartNV*(){.stdcall, importc, ogl.}
proc glPrimitiveRestartIndexNV*(index: GLuint){.stdcall, importc, ogl.}
  # GL_NV_register_combiners
proc glCombinerParameterfvNV*(pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glCombinerParameterfNV*(pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glCombinerParameterivNV*(pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glCombinerParameteriNV*(pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glCombinerInputNV*(stage: GLenum, portion: GLenum, variable: GLenum,
                        input: GLenum, mapping: GLenum, componentUsage: GLenum){.
    stdcall, importc, ogl.}
proc glCombinerOutputNV*(stage: GLenum, portion: GLenum, abOutput: GLenum,
                         cdOutput: GLenum, sumOutput: GLenum, scale: GLenum,
                         bias: GLenum, abDotProduct: GLboolean,
                         cdDotProduct: GLboolean, muxSum: GLboolean){.stdcall, importc, ogl.}
proc glFinalCombinerInputNV*(variable: GLenum, input: GLenum, mapping: GLenum,
                             componentUsage: GLenum){.stdcall, importc, ogl.}
proc glGetCombinerInputParameterfvNV*(stage: GLenum, portion: GLenum,
                                      variable: GLenum, pname: GLenum,
                                      params: PGLfloat){.stdcall, importc, ogl.}
proc glGetCombinerInputParameterivNV*(stage: GLenum, portion: GLenum,
                                      variable: GLenum, pname: GLenum,
                                      params: PGLint){.stdcall, importc, ogl.}
proc glGetCombinerOutputParameterfvNV*(stage: GLenum, portion: GLenum,
                                       pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glGetCombinerOutputParameterivNV*(stage: GLenum, portion: GLenum,
                                       pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetFinalCombinerInputParameterfvNV*(variable: GLenum, pname: GLenum,
    params: PGLfloat){.stdcall, importc, ogl.}
proc glGetFinalCombinerInputParameterivNV*(variable: GLenum, pname: GLenum,
    params: PGLint){.stdcall, importc, ogl.}
  # GL_NV_register_combiners2
proc glCombinerStageParameterfvNV*(stage: GLenum, pname: GLenum,
                                   params: PGLfloat){.stdcall, importc, ogl.}
proc glGetCombinerStageParameterfvNV*(stage: GLenum, pname: GLenum,
                                      params: PGLfloat){.stdcall, importc, ogl.}
  # GL_NV_vertex_array_range
proc glFlushVertexArrayRangeNV*(){.stdcall, importc, ogl.}
proc glVertexArrayRangeNV*(len: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
  # GL_NV_vertex_prog
proc glAreProgramsResidentNV*(n: GLsizei, programs: PGLuint,
                              residences: PGLboolean): GLboolean{.stdcall, importc, ogl.}
proc glBindProgramNV*(target: GLenum, id: GLuint){.stdcall, importc, ogl.}
proc glDeleteProgramsNV*(n: GLsizei, programs: PGLuint){.stdcall, importc, ogl.}
proc glExecuteProgramNV*(target: GLenum, id: GLuint, params: PGLfloat){.stdcall, importc, ogl.}
proc glGenProgramsNV*(n: GLsizei, programs: PGLuint){.stdcall, importc, ogl.}
proc glGetProgramParameterdvNV*(target: GLenum, index: GLuint, pname: GLenum,
                                params: PGLdouble){.stdcall, importc, ogl.}
proc glGetProgramParameterfvNV*(target: GLenum, index: GLuint, pname: GLenum,
                                params: PGLfloat){.stdcall, importc, ogl.}
proc glGetProgramivNV*(id: GLuint, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetProgramStringNV*(id: GLuint, pname: GLenum, prog: PGLubyte){.stdcall, importc, ogl.}
proc glGetTrackMatrixivNV*(target: GLenum, address: GLuint, pname: GLenum,
                           params: PGLint){.stdcall, importc, ogl.}
proc glGetVertexAttribdvNV*(index: GLuint, pname: GLenum, params: PGLdouble){.
    stdcall, importc, ogl.}
proc glGetVertexAttribfvNV*(index: GLuint, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetVertexAttribivNV*(index: GLuint, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetVertexAttribPointervNV*(index: GLuint, pname: GLenum, pointer: PGLvoid){.
    stdcall, importc, ogl.}
proc glIsProgramNV*(id: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glLoadProgramNV*(target: GLenum, id: GLuint, length: GLsizei,
                      prog: PGLubyte){.stdcall, importc, ogl.}
proc glProgramParameter4dNV*(target: GLenum, index: GLuint, x: GLdouble,
                             y: GLdouble, z: GLdouble, w: GLdouble){.stdcall, importc, ogl.}
proc glProgramParameter4dvNV*(target: GLenum, index: GLuint, v: PGLdouble){.
    stdcall, importc, ogl.}
proc glProgramParameter4fNV*(target: GLenum, index: GLuint, x: GLfloat,
                             y: GLfloat, z: GLfloat, w: GLfloat){.stdcall, importc, ogl.}
proc glProgramParameter4fvNV*(target: GLenum, index: GLuint, v: PGLfloat){.
    stdcall, importc, ogl.}
proc glProgramParameters4dvNV*(target: GLenum, index: GLuint, count: GLuint,
                               v: PGLdouble){.stdcall, importc, ogl.}
proc glProgramParameters4fvNV*(target: GLenum, index: GLuint, count: GLuint,
                               v: PGLfloat){.stdcall, importc, ogl.}
proc glRequestResidentProgramsNV*(n: GLsizei, programs: PGLuint){.stdcall, importc, ogl.}
proc glTrackMatrixNV*(target: GLenum, address: GLuint, matrix: GLenum,
                      transform: GLenum){.stdcall, importc, ogl.}
proc glVertexAttribPointerNV*(index: GLuint, fsize: GLint, typ: GLenum,
                              stride: GLsizei, pointer: PGLvoid){.stdcall, importc, ogl.}
proc glVertexAttrib1dNV*(index: GLuint, x: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib1dvNV*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib1fNV*(index: GLuint, x: GLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib1fvNV*(index: GLuint, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib1sNV*(index: GLuint, x: GLshort){.stdcall, importc, ogl.}
proc glVertexAttrib1svNV*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttrib2dNV*(index: GLuint, x: GLdouble, y: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib2dvNV*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib2fNV*(index: GLuint, x: GLfloat, y: GLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib2fvNV*(index: GLuint, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib2sNV*(index: GLuint, x: GLshort, y: GLshort){.stdcall, importc, ogl.}
proc glVertexAttrib2svNV*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttrib3dNV*(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble){.
    stdcall, importc, ogl.}
proc glVertexAttrib3dvNV*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib3fNV*(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat){.
    stdcall, importc, ogl.}
proc glVertexAttrib3fvNV*(index: GLuint, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib3sNV*(index: GLuint, x: GLshort, y: GLshort, z: GLshort){.
    stdcall, importc, ogl.}
proc glVertexAttrib3svNV*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttrib4dNV*(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble,
                         w: GLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib4dvNV*(index: GLuint, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttrib4fNV*(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat,
                         w: GLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib4fvNV*(index: GLuint, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttrib4sNV*(index: GLuint, x: GLshort, y: GLshort, z: GLshort,
                         w: GLshort){.stdcall, importc, ogl.}
proc glVertexAttrib4svNV*(index: GLuint, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttrib4ubNV*(index: GLuint, x: GLubyte, y: GLubyte, z: GLubyte,
                          w: GLubyte){.stdcall, importc, ogl.}
proc glVertexAttrib4ubvNV*(index: GLuint, v: PGLubyte){.stdcall, importc, ogl.}
proc glVertexAttribs1dvNV*(index: GLuint, count: GLsizei, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttribs1fvNV*(index: GLuint, count: GLsizei, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttribs1svNV*(index: GLuint, count: GLsizei, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttribs2dvNV*(index: GLuint, count: GLsizei, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttribs2fvNV*(index: GLuint, count: GLsizei, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttribs2svNV*(index: GLuint, count: GLsizei, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttribs3dvNV*(index: GLuint, count: GLsizei, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttribs3fvNV*(index: GLuint, count: GLsizei, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttribs3svNV*(index: GLuint, count: GLsizei, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttribs4dvNV*(index: GLuint, count: GLsizei, v: PGLdouble){.stdcall, importc, ogl.}
proc glVertexAttribs4fvNV*(index: GLuint, count: GLsizei, v: PGLfloat){.stdcall, importc, ogl.}
proc glVertexAttribs4svNV*(index: GLuint, count: GLsizei, v: PGLshort){.stdcall, importc, ogl.}
proc glVertexAttribs4ubvNV*(index: GLuint, count: GLsizei, v: PGLubyte){.stdcall, importc, ogl.}
  # GL_NV_depth_buffer_float
proc glDepthRangedNV*(n: GLdouble, f: GLdouble){.stdcall, importc, ogl.}
proc glClearDepthdNV*(d: GLdouble){.stdcall, importc, ogl.}
proc glDepthBoundsdNV*(zmin: GLdouble, zmax: GLdouble){.stdcall, importc, ogl.}
  # GL_NV_framebuffer_multisample_coverage
proc glRenderbufferStorageMultsampleCoverageNV*(target: GLenum,
    coverageSamples: GLsizei, colorSamples: GLsizei, internalformat: GLenum,
    width: GLsizei, height: GLsizei){.stdcall, importc, ogl.}
  # GL_NV_geometry_program4
proc glProgramVertexLimitNV*(target: GLenum, limit: GLint){.stdcall, importc, ogl.}
  # GL_NV_gpu_program4
proc glProgramLocalParameterI4iNV*(target: GLenum, index: GLuint, x: GLint,
                                   y: GLint, z: GLint, w: GLint){.stdcall, importc, ogl.}
proc glProgramLocalParameterI4ivNV*(target: GLenum, index: GLuint,
                                    params: PGLint){.stdcall, importc, ogl.}
proc glProgramLocalParametersI4ivNV*(target: GLenum, index: GLuint,
                                     count: GLsizei, params: PGLint){.stdcall, importc, ogl.}
proc glProgramLocalParameterI4uiNV*(target: GLenum, index: GLuint, x: GLuint,
                                    y: GLuint, z: GLuint, w: GLuint){.stdcall, importc, ogl.}
proc glProgramLocalParameterI4uivNV*(target: GLenum, index: GLuint,
                                     params: PGLuint){.stdcall, importc, ogl.}
proc glProgramLocalParametersI4uivNV*(target: GLenum, index: GLuint,
                                      count: GLsizei, params: PGLuint){.stdcall, importc, ogl.}
proc glProgramEnvParameterI4iNV*(target: GLenum, index: GLuint, x: GLint,
                                 y: GLint, z: GLint, w: GLint){.stdcall, importc, ogl.}
proc glProgramEnvParameterI4ivNV*(target: GLenum, index: GLuint, params: PGLint){.
    stdcall, importc, ogl.}
proc glProgramEnvParametersI4ivNV*(target: GLenum, index: GLuint,
                                   count: GLsizei, params: PGLint){.stdcall, importc, ogl.}
proc glProgramEnvParameterI4uiNV*(target: GLenum, index: GLuint, x: GLuint,
                                  y: GLuint, z: GLuint, w: GLuint){.stdcall, importc, ogl.}
proc glProgramEnvParameterI4uivNV*(target: GLenum, index: GLuint,
                                   params: PGLuint){.stdcall, importc, ogl.}
proc glProgramEnvParametersI4uivNV*(target: GLenum, index: GLuint,
                                    count: GLsizei, params: PGLuint){.stdcall, importc, ogl.}
proc glGetProgramLocalParameterIivNV*(target: GLenum, index: GLuint,
                                      params: PGLint){.stdcall, importc, ogl.}
proc glGetProgramLocalParameterIuivNV*(target: GLenum, index: GLuint,
                                       params: PGLuint){.stdcall, importc, ogl.}
proc glGetProgramEnvParameterIivNV*(target: GLenum, index: GLuint,
                                    params: PGLint){.stdcall, importc, ogl.}
proc glGetProgramEnvParameterIuivNV*(target: GLenum, index: GLuint,
                                     params: PGLuint){.stdcall, importc, ogl.}
  # GL_NV_parameter_buffer_object
proc glProgramBufferParametersfvNV*(target: GLenum, buffer: GLuint,
                                    index: GLuint, count: GLsizei,
                                    params: PGLfloat){.stdcall, importc, ogl.}
proc glProgramBufferParametersIivNV*(target: GLenum, buffer: GLuint,
                                     index: GLuint, count: GLsizei,
                                     params: GLint){.stdcall, importc, ogl.}
proc glProgramBufferParametersIuivNV*(target: GLenum, buffer: GLuint,
                                      index: GLuint, count: GLuint,
                                      params: PGLuint){.stdcall, importc, ogl.}
  # GL_NV_transform_feedback
proc glBeginTransformFeedbackNV*(primitiveMode: GLenum){.stdcall, importc, ogl.}
proc glEndTransformFeedbackNV*(){.stdcall, importc, ogl.}
proc glTransformFeedbackAttribsNV*(count: GLsizei, attribs: GLint,
                                   bufferMode: GLenum){.stdcall, importc, ogl.}
proc glBindBufferRangeNV*(target: GLenum, index: GLuint, buffer: GLuint,
                          offset: GLintptr, size: GLsizeiptr){.stdcall, importc, ogl.}
proc glBindBufferOffsetNV*(target: GLenum, index: GLuint, buffer: GLuint,
                           offset: GLintptr){.stdcall, importc, ogl.}
proc glBindBufferBaseNV*(target: GLenum, index: GLuint, buffer: GLuint){.stdcall, importc, ogl.}
proc glTransformFeedbackVaryingsNV*(prog: GLuint, count: GLsizei,
                                    locations: PGLint, bufferMode: GLenum){.
    stdcall, importc, ogl.}
proc glActiveVaryingNV*(prog: GLuint, name: PGLchar){.stdcall, importc, ogl.}
proc glGetVaryingLocationNV*(prog: GLuint, name: PGLchar): GLint{.stdcall, importc, ogl.}
proc glGetActiveVaryingNV*(prog: GLuint, index: GLuint, bufSize: GLsizei,
                           len: PGLsizei, size: PGLsizei, typ: PGLenum,
                           name: PGLchar){.stdcall, importc, ogl.}
proc glGetTransformFeedbackVaryingNV*(prog: GLuint, index: GLuint,
                                      location: PGLint){.stdcall, importc, ogl.}
proc glTransformFeedbackStreamAttribsNV*(count: GLsizei, attribs: PGLint,
    nbuffers: GLsizei, bufstreams: PGLint, bufferMode: GLenum){.stdcall, importc, ogl.}
  # GL_NV_conditional_render
proc glBeginConditionalRenderNV*(id: GLuint, mode: GLenum){.stdcall, importc, ogl.}
proc glEndConditionalRenderNV*(){.stdcall, importc, ogl.}
  # GL_NV_present_video
proc glPresentFrameKeyedNV*(video_slot: GLuint, minPresentTime: GLuint64EXT,
                            beginPresentTimeId: GLuint,
                            presentDuratioId: GLuint, typ: GLenum,
                            target0: GLenum, fill0: GLuint, key0: GLuint,
                            target1: GLenum, fill1: GLuint, key1: GLuint){.
    stdcall, importc, ogl.}
proc glPresentFrameDualFillNV*(video_slot: GLuint, minPresentTime: GLuint64EXT,
                               beginPresentTimeId: GLuint,
                               presentDurationId: GLuint, typ: GLenum,
                               target0: GLenum, fill0: GLuint, target1: GLenum,
                               fill1: GLuint, target2: GLenum, fill2: GLuint,
                               target3: GLenum, fill3: GLuint){.stdcall, importc, ogl.}
proc glGetVideoivNV*(video_slot: GLuint, pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetVideouivNV*(video_slot: GLuint, pname: GLenum, params: PGLuint){.
    stdcall, importc, ogl.}
proc glGetVideoi64vNV*(video_slot: GLuint, pname: GLenum, params: PGLint64EXT){.
    stdcall, importc, ogl.}
proc glGetVideoui64vNV*(video_slot: GLuint, pname: GLenum, params: PGLuint64EXT){.
    stdcall, importc, ogl.}
  #procedure glVideoParameterivNV(video_slot: GLuint; pname: GLenum; const params: PGLint); stdcall, importc, ogl;
  # GL_NV_explicit_multisample
proc glGetMultisamplefvNV*(pname: GLenum, index: GLuint, val: PGLfloat){.stdcall, importc, ogl.}
proc glSampleMaskIndexedNV*(index: GLuint, mask: GLbitfield){.stdcall, importc, ogl.}
proc glTexRenderbufferNV*(target: GLenum, renderbuffer: GLuint){.stdcall, importc, ogl.}
  # GL_NV_transform_feedback2
proc glBindTransformFeedbackNV*(target: GLenum, id: GLuint){.stdcall, importc, ogl.}
proc glDeleteTransformFeedbacksNV*(n: GLsizei, ids: PGLuint){.stdcall, importc, ogl.}
proc glGenTransformFeedbacksNV*(n: GLsizei, ids: PGLuint){.stdcall, importc, ogl.}
proc glIsTransformFeedbackNV*(id: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glPauseTransformFeedbackNV*(){.stdcall, importc, ogl.}
proc glResumeTransformFeedbackNV*(){.stdcall, importc, ogl.}
proc glDrawTransformFeedbackNV*(mode: GLenum, id: GLuint){.stdcall, importc, ogl.}
  # GL_NV_video_capture
proc glBeginVideoCaptureNV*(video_capture_slot: GLuint){.stdcall, importc, ogl.}
proc glBindVideoCaptureStreamBufferNV*(video_capture_slot: GLuint,
                                       stream: GLuint, frame_region: GLenum,
                                       offset: GLintptrARB){.stdcall, importc, ogl.}
proc glBindVideoCaptureStreamTextureNV*(video_capture_slot: GLuint,
                                        stream: GLuint, frame_region: GLenum,
                                        target: GLenum, texture: GLuint){.
    stdcall, importc, ogl.}
proc glEndVideoCaptureNV*(video_capture_slot: GLuint){.stdcall, importc, ogl.}
proc glGetVideoCaptureivNV*(video_capture_slot: GLuint, pname: GLenum,
                            params: PGLint){.stdcall, importc, ogl.}
proc glGetVideoCaptureStreamivNV*(video_capture_slot: GLuint, stream: GLuint,
                                  pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetVideoCaptureStreamfvNV*(video_capture_slot: GLuint, stream: GLuint,
                                  pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glGetVideoCaptureStreamdvNV*(video_capture_slot: GLuint, stream: GLuint,
                                  pname: GLenum, params: PGLdouble){.stdcall, importc, ogl.}
proc glVideoCaptureNV*(video_capture_slot: GLuint, sequence_num: PGLuint,
                       capture_time: PGLuint64EXT): GLenum{.stdcall, importc, ogl.}
proc glVideoCaptureStreamParameterivNV*(video_capture_slot: GLuint,
                                        stream: GLuint, pname: GLenum,
                                        params: PGLint){.stdcall, importc, ogl.}
proc glVideoCaptureStreamParameterfvNV*(video_capture_slot: GLuint,
                                        stream: GLuint, pname: GLenum,
                                        params: PGLfloat){.stdcall, importc, ogl.}
proc glVideoCaptureStreamParameterdvNV*(video_capture_slot: GLuint,
                                        stream: GLuint, pname: GLenum,
                                        params: PGLdouble){.stdcall, importc, ogl.}
  # GL_NV_copy_image
proc glCopyImageSubDataNV*(srcName: GLuint, srcTarget: GLenum, srcLevel: GLint,
                           srcX: GLint, srcY: GLint, srcZ: GLint,
                           dstName: GLuint, dstTarget: GLenum, dstLevel: GLint,
                           dstX: GLint, dstY: GLint, dstZ: GLint,
                           width: GLsizei, height: GLsizei, depth: GLsizei){.
    stdcall, importc, ogl.}
  # GL_NV_shader_buffer_load
proc glMakeBufferResidentNV*(target: GLenum, access: GLenum){.stdcall, importc, ogl.}
proc glMakeBufferNonResidentNV*(target: GLenum){.stdcall, importc, ogl.}
proc glIsBufferResidentNV*(target: GLenum): GLboolean{.stdcall, importc, ogl.}
proc glMakeNamedBufferResidentNV*(buffer: GLuint, access: GLenum){.stdcall, importc, ogl.}
proc glMakeNamedBufferNonResidentNV*(buffer: GLuint){.stdcall, importc, ogl.}
proc glIsNamedBufferResidentNV*(buffer: GLuint): GLboolean{.stdcall, importc, ogl.}
proc glGetBufferParameterui64vNV*(target: GLenum, pname: GLenum,
                                  params: PGLuint64EXT){.stdcall, importc, ogl.}
proc glGetNamedBufferParameterui64vNV*(buffer: GLuint, pname: GLenum,
                                       params: PGLuint64EXT){.stdcall, importc, ogl.}
proc glGetIntegerui64vNV*(value: GLenum, result: PGLuint64EXT){.stdcall, importc, ogl.}
proc glUniformui64NV*(location: GLint, value: GLuint64EXT){.stdcall, importc, ogl.}
proc glUniformui64vNV*(location: GLint, count: GLsizei, value: PGLuint64EXT){.
    stdcall, importc, ogl.}
proc glGetUniformui64vNV*(prog: GLuint, location: GLint, params: PGLuint64EXT){.
    stdcall, importc, ogl.}
proc glProgramUniformui64NV*(prog: GLuint, location: GLint, value: GLuint64EXT){.
    stdcall, importc, ogl.}
proc glProgramUniformui64vNV*(prog: GLuint, location: GLint, count: GLsizei,
                              value: PGLuint64EXT){.stdcall, importc, ogl.}
  # GL_NV_vertex_buffer_unified_memory
proc glBufferAddressRangeNV*(pname: GLenum, index: GLuint, adress: GLuint64EXT,
                             len: GLsizeiptr){.stdcall, importc, ogl.}
proc glVertexFormatNV*(size: GLint, typ: GLenum, stride: GLsizei){.stdcall, importc, ogl.}
proc glNormalFormatNV*(typ: GLenum, stride: GLsizei){.stdcall, importc, ogl.}
proc glColorFormatNV*(size: GLint, typ: GLenum, stride: GLsizei){.stdcall, importc, ogl.}
proc glIndexFormatNV*(typ: GLenum, stride: GLsizei){.stdcall, importc, ogl.}
proc glTexCoordFormatNV*(size: GLint, typ: GLenum, stride: GLsizei){.stdcall, importc, ogl.}
proc glEdgeFlagFormatNV*(stride: GLsizei){.stdcall, importc, ogl.}
proc glSecondaryColorFormatNV*(size: GLint, typ: GLenum, stride: GLsizei){.
    stdcall, importc, ogl.}
proc glFogCoordFormatNV*(typ: GLenum, stride: GLsizei){.stdcall, importc, ogl.}
proc glVertexAttribFormatNV*(index: GLuint, size: GLint, typ: GLenum,
                             normalized: GLboolean, stride: GLsizei){.stdcall, importc, ogl.}
proc glVertexAttribIFormatNV*(index: GLuint, size: GLint, typ: GLenum,
                              stride: GLsizei){.stdcall, importc, ogl.}
proc glGetIntegerui64i_vNV*(value: GLenum, index: GLuint, Result: PGLuint64EXT){.
    stdcall, importc, ogl.}
  # GL_NV_gpu_program5
proc glProgramSubroutineParametersuivNV*(target: GLenum, count: GLsizei,
    params: PGLuint){.stdcall, importc, ogl.}
proc glGetProgramSubroutineParameteruivNV*(target: GLenum, index: GLuint,
    param: PGLuint){.stdcall, importc, ogl.}
  # GL_NV_gpu_shader5
proc glUniform1i64NV*(location: GLint, x: GLint64EXT){.stdcall, importc, ogl.}
proc glUniform2i64NV*(location: GLint, x: GLint64EXT, y: GLint64EXT){.stdcall, importc, ogl.}
proc glUniform3i64NV*(location: GLint, x: GLint64EXT, y: GLint64EXT,
                      z: GLint64EXT){.stdcall, importc, ogl.}
proc glUniform4i64NV*(location: GLint, x: GLint64EXT, y: GLint64EXT,
                      z: GLint64EXT, w: GLint64EXT){.stdcall, importc, ogl.}
proc glUniform1i64vNV*(location: GLint, count: GLsizei, value: PGLint64EXT){.
    stdcall, importc, ogl.}
proc glUniform2i64vNV*(location: GLint, count: GLsizei, value: PGLint64EXT){.
    stdcall, importc, ogl.}
proc glUniform3i64vNV*(location: GLint, count: GLsizei, value: PGLint64EXT){.
    stdcall, importc, ogl.}
proc glUniform4i64vNV*(location: GLint, count: GLsizei, value: PGLint64EXT){.
    stdcall, importc, ogl.}
proc glUniform1ui64NV*(location: GLint, x: GLuint64EXT){.stdcall, importc, ogl.}
proc glUniform2ui64NV*(location: GLint, x: GLuint64EXT, y: GLuint64EXT){.stdcall, importc, ogl.}
proc glUniform3ui64NV*(location: GLint, x: GLuint64EXT, y: GLuint64EXT,
                       z: GLuint64EXT){.stdcall, importc, ogl.}
proc glUniform4ui64NV*(location: GLint, x: GLuint64EXT, y: GLuint64EXT,
                       z: GLuint64EXT, w: GLuint64EXT){.stdcall, importc, ogl.}
proc glUniform1ui64vNV*(location: GLint, count: GLsizei, value: PGLuint64EXT){.
    stdcall, importc, ogl.}
proc glUniform2ui64vNV*(location: GLint, count: GLsizei, value: PGLuint64EXT){.
    stdcall, importc, ogl.}
proc glUniform3ui64vNV*(location: GLint, count: GLsizei, value: PGLuint64EXT){.
    stdcall, importc, ogl.}
proc glUniform4ui64vNV*(location: GLint, count: GLsizei, value: PGLuint64EXT){.
    stdcall, importc, ogl.}
proc glGetUniformi64vNV*(prog: GLuint, location: GLint, params: PGLint64EXT){.
    stdcall, importc, ogl.}
proc glProgramUniform1i64NV*(prog: GLuint, location: GLint, x: GLint64EXT){.
    stdcall, importc, ogl.}
proc glProgramUniform2i64NV*(prog: GLuint, location: GLint, x: GLint64EXT,
                             y: GLint64EXT){.stdcall, importc, ogl.}
proc glProgramUniform3i64NV*(prog: GLuint, location: GLint, x: GLint64EXT,
                             y: GLint64EXT, z: GLint64EXT){.stdcall, importc, ogl.}
proc glProgramUniform4i64NV*(prog: GLuint, location: GLint, x: GLint64EXT,
                             y: GLint64EXT, z: GLint64EXT, w: GLint64EXT){.
    stdcall, importc, ogl.}
proc glProgramUniform1i64vNV*(prog: GLuint, location: GLint, count: GLsizei,
                              value: PGLint64EXT){.stdcall, importc, ogl.}
proc glProgramUniform2i64vNV*(prog: GLuint, location: GLint, count: GLsizei,
                              value: PGLint64EXT){.stdcall, importc, ogl.}
proc glProgramUniform3i64vNV*(prog: GLuint, location: GLint, count: GLsizei,
                              value: PGLint64EXT){.stdcall, importc, ogl.}
proc glProgramUniform4i64vNV*(prog: GLuint, location: GLint, count: GLsizei,
                              value: PGLint64EXT){.stdcall, importc, ogl.}
proc glProgramUniform1ui64NV*(prog: GLuint, location: GLint, x: GLuint64EXT){.
    stdcall, importc, ogl.}
proc glProgramUniform2ui64NV*(prog: GLuint, location: GLint, x: GLuint64EXT,
                              y: GLuint64EXT){.stdcall, importc, ogl.}
proc glProgramUniform3ui64NV*(prog: GLuint, location: GLint, x: GLuint64EXT,
                              y: GLuint64EXT, z: GLuint64EXT){.stdcall, importc, ogl.}
proc glProgramUniform4ui64NV*(prog: GLuint, location: GLint, x: GLuint64EXT,
                              y: GLuint64EXT, z: GLuint64EXT, w: GLuint64EXT){.
    stdcall, importc, ogl.}
proc glProgramUniform1ui64vNV*(prog: GLuint, location: GLint, count: GLsizei,
                               value: PGLuint64EXT){.stdcall, importc, ogl.}
proc glProgramUniform2ui64vNV*(prog: GLuint, location: GLint, count: GLsizei,
                               value: PGLuint64EXT){.stdcall, importc, ogl.}
proc glProgramUniform3ui64vNV*(prog: GLuint, location: GLint, count: GLsizei,
                               value: PGLuint64EXT){.stdcall, importc, ogl.}
proc glProgramUniform4ui64vNV*(prog: GLuint, location: GLint, count: GLsizei,
                               value: PGLuint64EXT){.stdcall, importc, ogl.}
  # GL_NV_vertex_attrib_integer_64bit
proc glVertexAttribL1i64NV*(index: GLuint, x: GLint64EXT){.stdcall, importc, ogl.}
proc glVertexAttribL2i64NV*(index: GLuint, x: GLint64EXT, y: GLint64EXT){.
    stdcall, importc, ogl.}
proc glVertexAttribL3i64NV*(index: GLuint, x: GLint64EXT, y: GLint64EXT,
                            z: GLint64EXT){.stdcall, importc, ogl.}
proc glVertexAttribL4i64NV*(index: GLuint, x: GLint64EXT, y: GLint64EXT,
                            z: GLint64EXT, w: GLint64EXT){.stdcall, importc, ogl.}
proc glVertexAttribL1i64vNV*(index: GLuint, v: PGLint64EXT){.stdcall, importc, ogl.}
proc glVertexAttribL2i64vNV*(index: GLuint, v: PGLint64EXT){.stdcall, importc, ogl.}
proc glVertexAttribL3i64vNV*(index: GLuint, v: PGLint64EXT){.stdcall, importc, ogl.}
proc glVertexAttribL4i64vNV*(index: GLuint, v: PGLint64EXT){.stdcall, importc, ogl.}
proc glVertexAttribL1ui64NV*(index: GLuint, x: GLuint64EXT){.stdcall, importc, ogl.}
proc glVertexAttribL2ui64NV*(index: GLuint, x: GLuint64EXT, y: GLuint64EXT){.
    stdcall, importc, ogl.}
proc glVertexAttribL3ui64NV*(index: GLuint, x: GLuint64EXT, y: GLuint64EXT,
                             z: GLuint64EXT){.stdcall, importc, ogl.}
proc glVertexAttribL4ui64NV*(index: GLuint, x: GLuint64EXT, y: GLuint64EXT,
                             z: GLuint64EXT, w: GLuint64EXT){.stdcall, importc, ogl.}
proc glVertexAttribL1ui64vNV*(index: GLuint, v: PGLuint64EXT){.stdcall, importc, ogl.}
proc glVertexAttribL2ui64vNV*(index: GLuint, v: PGLuint64EXT){.stdcall, importc, ogl.}
proc glVertexAttribL3ui64vNV*(index: GLuint, v: PGLuint64EXT){.stdcall, importc, ogl.}
proc glVertexAttribL4ui64vNV*(index: GLuint, v: PGLuint64EXT){.stdcall, importc, ogl.}
proc glGetVertexAttribLi64vNV*(index: GLuint, pname: GLenum, params: PGLint64EXT){.
    stdcall, importc, ogl.}
proc glGetVertexAttribLui64vNV*(index: GLuint, pname: GLenum,
                                params: PGLuint64EXT){.stdcall, importc, ogl.}
proc glVertexAttribLFormatNV*(index: GLuint, size: GLint, typ: GLenum,
                              stride: GLsizei){.stdcall, importc, ogl.}
  # GL_NV_vdpau_interop
proc glVDPAUInitNV*(vdpDevice: PGLvoid, getProcAddress: PGLvoid){.stdcall, importc, ogl.}
proc glVDPAUFiniNV*(){.stdcall, importc, ogl.}
proc glVDPAURegisterVideoSurfaceNV*(vdpSurface: PGLvoid, target: GLenum,
                                    numTextureNames: GLsizei,
                                    textureNames: PGLuint): GLvdpauSurfaceNV{.
    stdcall, importc, ogl.}
proc glVDPAURegisterOutputSurfaceNV*(vdpSurface: PGLvoid, target: GLenum,
                                     numTextureNames: GLsizei,
                                     textureNames: PGLuint): GLvdpauSurfaceNV{.
    stdcall, importc, ogl.}
proc glVDPAUIsSurfaceNV*(surface: GLvdpauSurfaceNV){.stdcall, importc, ogl.}
proc glVDPAUUnregisterSurfaceNV*(surface: GLvdpauSurfaceNV){.stdcall, importc, ogl.}
proc glVDPAUGetSurfaceivNV*(surface: GLvdpauSurfaceNV, pname: GLenum,
                            bufSize: GLsizei, len: PGLsizei, values: PGLint){.
    stdcall, importc, ogl.}
proc glVDPAUSurfaceAccessNV*(surface: GLvdpauSurfaceNV, access: GLenum){.stdcall, importc, ogl.}
proc glVDPAUMapSurfacesNV*(numSurfaces: GLsizei, surfaces: PGLvdpauSurfaceNV){.
    stdcall, importc, ogl.}
proc glVDPAUUnmapSurfacesNV*(numSurface: GLsizei, surfaces: PGLvdpauSurfaceNV){.
    stdcall, importc, ogl.}
  # GL_NV_texture_barrier
proc glTextureBarrierNV*(){.stdcall, importc, ogl.}
  # GL_PGI_misc_hints
proc glHintPGI*(target: GLenum, mode: GLint){.stdcall, importc, ogl.}
  # GL_SGIS_detail_texture
proc glDetailTexFuncSGIS*(target: GLenum, n: GLsizei, points: PGLfloat){.stdcall, importc, ogl.}
proc glGetDetailTexFuncSGIS*(target: GLenum, points: PGLfloat){.stdcall, importc, ogl.}
  # GL_SGIS_fog_function
proc glFogFuncSGIS*(n: GLsizei, points: PGLfloat){.stdcall, importc, ogl.}
proc glGetFogFuncSGIS*(points: PGLfloat){.stdcall, importc, ogl.}
  # GL_SGIS_multisample
proc glSampleMaskSGIS*(value: GLclampf, invert: GLboolean){.stdcall, importc, ogl.}
proc glSamplePatternSGIS*(pattern: GLenum){.stdcall, importc, ogl.}
  # GL_SGIS_pixel_texture
proc glPixelTexGenParameteriSGIS*(pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glPixelTexGenParameterivSGIS*(pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glPixelTexGenParameterfSGIS*(pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glPixelTexGenParameterfvSGIS*(pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glGetPixelTexGenParameterivSGIS*(pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glGetPixelTexGenParameterfvSGIS*(pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
  # GL_SGIS_point_parameters
proc glPointParameterfSGIS*(pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glPointParameterfvSGIS*(pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
  # GL_SGIS_sharpen_texture
proc glSharpenTexFuncSGIS*(target: GLenum, n: GLsizei, points: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetSharpenTexFuncSGIS*(target: GLenum, points: PGLfloat){.stdcall, importc, ogl.}
  # GL_SGIS_texture4D
proc glTexImage4DSGIS*(target: GLenum, level: GLint, internalformat: GLenum,
                       width: GLsizei, height: GLsizei, depth: GLsizei,
                       size4d: GLsizei, border: GLint, format: GLenum,
                       typ: GLenum, pixels: PGLvoid){.stdcall, importc, ogl.}
proc glTexSubImage4DSGIS*(target: GLenum, level: GLint, xoffset: GLint,
                          yoffset: GLint, zoffset: GLint, woffset: GLint,
                          width: GLsizei, height: GLsizei, depth: GLsizei,
                          size4d: GLsizei, format: GLenum, typ: GLenum,
                          pixels: PGLvoid){.stdcall, importc, ogl.}
  # GL_SGIS_texture_color_mask
proc glTextureColorMaskSGIS*(red: GLboolean, green: GLboolean, blue: GLboolean,
                             alpha: GLboolean){.stdcall, importc, ogl.}
  # GL_SGIS_texture_filter4
proc glGetTexFilterFuncSGIS*(target: GLenum, filter: GLenum, weights: PGLfloat){.
    stdcall, importc, ogl.}
proc glTexFilterFuncSGIS*(target: GLenum, filter: GLenum, n: GLsizei,
                          weights: PGLfloat){.stdcall, importc, ogl.}
  # GL_SGIX_async
proc glAsyncMarkerSGIX*(marker: GLuint){.stdcall, importc, ogl.}
proc glFinishAsyncSGIX*(markerp: PGLuint): GLint{.stdcall, importc, ogl.}
proc glPollAsyncSGIX*(markerp: PGLuint): GLint{.stdcall, importc, ogl.}
proc glGenAsyncMarkersSGIX*(range: GLsizei): GLuint{.stdcall, importc, ogl.}
proc glDeleteAsyncMarkersSGIX*(marker: GLuint, range: GLsizei){.stdcall, importc, ogl.}
proc glIsAsyncMarkerSGIX*(marker: GLuint): GLboolean{.stdcall, importc, ogl.}
  # GL_SGIX_flush_raster
proc glFlushRasterSGIX*(){.stdcall, importc, ogl.}
  # GL_SGIX_fragment_lighting
proc glFragmentColorMaterialSGIX*(face: GLenum, mode: GLenum){.stdcall, importc, ogl.}
proc glFragmentLightfSGIX*(light: GLenum, pname: GLenum, param: GLfloat){.
    stdcall, importc, ogl.}
proc glFragmentLightfvSGIX*(light: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glFragmentLightiSGIX*(light: GLenum, pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glFragmentLightivSGIX*(light: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glFragmentLightModelfSGIX*(pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glFragmentLightModelfvSGIX*(pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glFragmentLightModeliSGIX*(pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glFragmentLightModelivSGIX*(pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
proc glFragmentMaterialfSGIX*(face: GLenum, pname: GLenum, param: GLfloat){.
    stdcall, importc, ogl.}
proc glFragmentMaterialfvSGIX*(face: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glFragmentMaterialiSGIX*(face: GLenum, pname: GLenum, param: GLint){.
    stdcall, importc, ogl.}
proc glFragmentMaterialivSGIX*(face: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetFragmentLightfvSGIX*(light: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetFragmentLightivSGIX*(light: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glGetFragmentMaterialfvSGIX*(face: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetFragmentMaterialivSGIX*(face: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glLightEnviSGIX*(pname: GLenum, param: GLint){.stdcall, importc, ogl.}
  # GL_SGIX_framezoom
proc glFrameZoomSGIX*(factor: GLint){.stdcall, importc, ogl.}
  # GL_SGIX_igloo_interface
proc glIglooInterfaceSGIX*(pname: GLenum, params: PGLvoid){.stdcall, importc, ogl.}
  # GL_SGIX_instruments
proc glGetInstrumentsSGIX*(): GLint{.stdcall, importc, ogl.}
proc glInstrumentsBufferSGIX*(size: GLsizei, buffer: PGLint){.stdcall, importc, ogl.}
proc glPollInstrumentsSGIX*(marker_p: PGLint): GLint{.stdcall, importc, ogl.}
proc glReadInstrumentsSGIX*(marker: GLint){.stdcall, importc, ogl.}
proc glStartInstrumentsSGIX*(){.stdcall, importc, ogl.}
proc glStopInstrumentsSGIX*(marker: GLint){.stdcall, importc, ogl.}
  # GL_SGIX_list_priority
proc glGetListParameterfvSGIX*(list: GLuint, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glGetListParameterivSGIX*(list: GLuint, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glListParameterfSGIX*(list: GLuint, pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glListParameterfvSGIX*(list: GLuint, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glListParameteriSGIX*(list: GLuint, pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glListParameterivSGIX*(list: GLuint, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
  # GL_SGIX_pixel_texture
proc glPixelTexGenSGIX*(mode: GLenum){.stdcall, importc, ogl.}
  # GL_SGIX_polynomial_ffd
proc glDeformationMap3dSGIX*(target: GLenum, u1: GLdouble, u2: GLdouble,
                             ustride: GLint, uorder: GLint, v1: GLdouble,
                             v2: GLdouble, vstride: GLint, vorder: GLint,
                             w1: GLdouble, w2: GLdouble, wstride: GLint,
                             worder: GLint, points: PGLdouble){.stdcall, importc, ogl.}
proc glDeformationMap3fSGIX*(target: GLenum, u1: GLfloat, u2: GLfloat,
                             ustride: GLint, uorder: GLint, v1: GLfloat,
                             v2: GLfloat, vstride: GLint, vorder: GLint,
                             w1: GLfloat, w2: GLfloat, wstride: GLint,
                             worder: GLint, points: PGLfloat){.stdcall, importc, ogl.}
proc glDeformSGIX*(mask: GLbitfield){.stdcall, importc, ogl.}
proc glLoadIdentityDeformationMapSGIX*(mask: GLbitfield){.stdcall, importc, ogl.}
  # GL_SGIX_reference_plane
proc glReferencePlaneSGIX*(equation: PGLdouble){.stdcall, importc, ogl.}
  # GL_SGIX_sprite
proc glSpriteParameterfSGIX*(pname: GLenum, param: GLfloat){.stdcall, importc, ogl.}
proc glSpriteParameterfvSGIX*(pname: GLenum, params: PGLfloat){.stdcall, importc, ogl.}
proc glSpriteParameteriSGIX*(pname: GLenum, param: GLint){.stdcall, importc, ogl.}
proc glSpriteParameterivSGIX*(pname: GLenum, params: PGLint){.stdcall, importc, ogl.}
  # GL_SGIX_tag_sample_buffer
proc glTagSampleBufferSGIX*(){.stdcall, importc, ogl.}
  # GL_SGI_color_table
proc glColorTableSGI*(target: GLenum, internalformat: GLenum, width: GLsizei,
                      format: GLenum, typ: GLenum, table: PGLvoid){.stdcall, importc, ogl.}
proc glColorTableParameterfvSGI*(target: GLenum, pname: GLenum, params: PGLfloat){.
    stdcall, importc, ogl.}
proc glColorTableParameterivSGI*(target: GLenum, pname: GLenum, params: PGLint){.
    stdcall, importc, ogl.}
proc glCopyColorTableSGI*(target: GLenum, internalformat: GLenum, x: GLint,
                          y: GLint, width: GLsizei){.stdcall, importc, ogl.}
proc glGetColorTableSGI*(target: GLenum, format: GLenum, typ: GLenum,
                         table: PGLvoid){.stdcall, importc, ogl.}
proc glGetColorTableParameterfvSGI*(target: GLenum, pname: GLenum,
                                    params: PGLfloat){.stdcall, importc, ogl.}
proc glGetColorTableParameterivSGI*(target: GLenum, pname: GLenum,
                                    params: PGLint){.stdcall, importc, ogl.}
  # GL_SUNX_constant_data
proc glFinishTextureSUNX*(){.stdcall, importc, ogl.}
  # GL_SUN_global_alpha
proc glGlobalAlphaFactorbSUN*(factor: GLbyte){.stdcall, importc, ogl.}
proc glGlobalAlphaFactorsSUN*(factor: GLshort){.stdcall, importc, ogl.}
proc glGlobalAlphaFactoriSUN*(factor: GLint){.stdcall, importc, ogl.}
proc glGlobalAlphaFactorfSUN*(factor: GLfloat){.stdcall, importc, ogl.}
proc glGlobalAlphaFactordSUN*(factor: GLdouble){.stdcall, importc, ogl.}
proc glGlobalAlphaFactorubSUN*(factor: GLubyte){.stdcall, importc, ogl.}
proc glGlobalAlphaFactorusSUN*(factor: GLushort){.stdcall, importc, ogl.}
proc glGlobalAlphaFactoruiSUN*(factor: GLuint){.stdcall, importc, ogl.}
  # GL_SUN_mesh_array
proc glDrawMeshArraysSUN*(mode: GLenum, first: GLint, count: GLsizei,
                          width: GLsizei){.stdcall, importc, ogl.}
  # GL_SUN_triangle_list
proc glReplacementCodeuiSUN*(code: GLuint){.stdcall, importc, ogl.}
proc glReplacementCodeusSUN*(code: GLushort){.stdcall, importc, ogl.}
proc glReplacementCodeubSUN*(code: GLubyte){.stdcall, importc, ogl.}
proc glReplacementCodeuivSUN*(code: PGLuint){.stdcall, importc, ogl.}
proc glReplacementCodeusvSUN*(code: PGLushort){.stdcall, importc, ogl.}
proc glReplacementCodeubvSUN*(code: PGLubyte){.stdcall, importc, ogl.}
proc glReplacementCodePointerSUN*(typ: GLenum, stride: GLsizei, pointer: PGLvoid){.
    stdcall, importc, ogl.}
  # GL_SUN_vertex
proc glColor4ubVertex2fSUN*(r: GLubyte, g: GLubyte, b: GLubyte, a: GLubyte,
                            x: GLfloat, y: GLfloat){.stdcall, importc, ogl.}
proc glColor4ubVertex2fvSUN*(c: PGLubyte, v: PGLfloat){.stdcall, importc, ogl.}
proc glColor4ubVertex3fSUN*(r: GLubyte, g: GLubyte, b: GLubyte, a: GLubyte,
                            x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glColor4ubVertex3fvSUN*(c: PGLubyte, v: PGLfloat){.stdcall, importc, ogl.}
proc glColor3fVertex3fSUN*(r: GLfloat, g: GLfloat, b: GLfloat, x: GLfloat,
                           y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glColor3fVertex3fvSUN*(c: PGLfloat, v: PGLfloat){.stdcall, importc, ogl.}
proc glNormal3fVertex3fSUN*(nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat,
                            y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glNormal3fVertex3fvSUN*(n: PGLfloat, v: PGLfloat){.stdcall, importc, ogl.}
proc glColor4fNormal3fVertex3fSUN*(r: GLfloat, g: GLfloat, b: GLfloat,
                                   a: GLfloat, nx: GLfloat, ny: GLfloat,
                                   nz: GLfloat, x: GLfloat, y: GLfloat,
                                   z: GLfloat){.stdcall, importc, ogl.}
proc glColor4fNormal3fVertex3fvSUN*(c: PGLfloat, n: PGLfloat, v: PGLfloat){.
    stdcall, importc, ogl.}
proc glTexCoord2fVertex3fSUN*(s: GLfloat, t: GLfloat, x: GLfloat, y: GLfloat,
                              z: GLfloat){.stdcall, importc, ogl.}
proc glTexCoord2fVertex3fvSUN*(tc: PGLfloat, v: PGLfloat){.stdcall, importc, ogl.}
proc glTexCoord4fVertex4fSUN*(s: GLfloat, t: GLfloat, p: GLfloat, q: GLfloat,
                              x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat){.
    stdcall, importc, ogl.}
proc glTexCoord4fVertex4fvSUN*(tc: PGLfloat, v: PGLfloat){.stdcall, importc, ogl.}
proc glTexCoord2fColor4ubVertex3fSUN*(s: GLfloat, t: GLfloat, r: GLubyte,
                                      g: GLubyte, b: GLubyte, a: GLubyte,
                                      x: GLfloat, y: GLfloat, z: GLfloat){.
    stdcall, importc, ogl.}
proc glTexCoord2fColor4ubVertex3fvSUN*(tc: PGLfloat, c: PGLubyte, v: PGLfloat){.
    stdcall, importc, ogl.}
proc glTexCoord2fColor3fVertex3fSUN*(s: GLfloat, t: GLfloat, r: GLfloat,
                                     g: GLfloat, b: GLfloat, x: GLfloat,
                                     y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glTexCoord2fColor3fVertex3fvSUN*(tc: PGLfloat, c: PGLfloat, v: PGLfloat){.
    stdcall, importc, ogl.}
proc glTexCoord2fNormal3fVertex3fSUN*(s: GLfloat, t: GLfloat, nx: GLfloat,
                                      ny: GLfloat, nz: GLfloat, x: GLfloat,
                                      y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glTexCoord2fNormal3fVertex3fvSUN*(tc: PGLfloat, n: PGLfloat, v: PGLfloat){.
    stdcall, importc, ogl.}
proc glTexCoord2fColor4fNormal3fVertex3fSUN*(s: GLfloat, t: GLfloat, r: GLfloat,
    g: GLfloat, b: GLfloat, a: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat,
    x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glTexCoord2fColor4fNormal3fVertex3fvSUN*(tc: PGLfloat, c: PGLfloat,
    n: PGLfloat, v: PGLfloat){.stdcall, importc, ogl.}
proc glTexCoord4fColor4fNormal3fVertex4fSUN*(s: GLfloat, t: GLfloat, p: GLfloat,
    q: GLfloat, r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat, nx: GLfloat,
    ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat){.
    stdcall, importc, ogl.}
proc glTexCoord4fColor4fNormal3fVertex4fvSUN*(tc: PGLfloat, c: PGLfloat,
    n: PGLfloat, v: PGLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiVertex3fSUN*(rc: GLuint, x: GLfloat, y: GLfloat,
                                     z: GLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiVertex3fvSUN*(rc: PGLuint, v: PGLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiColor4ubVertex3fSUN*(rc: GLuint, r: GLubyte, g: GLubyte,
    b: GLubyte, a: GLubyte, x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiColor4ubVertex3fvSUN*(rc: PGLuint, c: PGLubyte,
    v: PGLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiColor3fVertex3fSUN*(rc: GLuint, r: GLfloat, g: GLfloat,
    b: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiColor3fVertex3fvSUN*(rc: PGLuint, c: PGLfloat,
    v: PGLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiNormal3fVertex3fSUN*(rc: GLuint, nx: GLfloat,
    ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiNormal3fVertex3fvSUN*(rc: PGLuint, n: PGLfloat,
    v: PGLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiColor4fNormal3fVertex3fSUN*(rc: GLuint, r: GLfloat,
    g: GLfloat, b: GLfloat, a: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat,
    x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiColor4fNormal3fVertex3fvSUN*(rc: PGLuint, c: PGLfloat,
    n: PGLfloat, v: PGLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiTexCoord2fVertex3fSUN*(rc: GLuint, s: GLfloat,
    t: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiTexCoord2fVertex3fvSUN*(rc: PGLuint, tc: PGLfloat,
    v: PGLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiTexCoord2fNormal3fVertex3fSUN*(rc: GLuint, s: GLfloat,
    t: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat,
    z: GLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiTexCoord2fNormal3fVertex3fvSUN*(rc: PGLuint,
    tc: PGLfloat, n: PGLfloat, v: PGLfloat){.stdcall, importc, ogl.}
proc glReplacementCodeuiTexCoord2fColor4fNormal3fVertex3fSUN*(rc: GLuint,
    s: GLfloat, t: GLfloat, r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat,
    nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat){.
    stdcall, importc, ogl.}
proc glReplacementCodeuiTexCoord2fColor4fNormal3fVertex3fvSUN*(rc: PGLuint,
    tc: PGLfloat, c: PGLfloat, n: PGLfloat, v: PGLfloat){.stdcall, importc, ogl.}
  # window support functions
when defined(windows):
  when not defined(wglGetProcAddress):
    proc wglGetProcAddress*(ProcName: cstring): Pointer{.stdcall, importc, wgl.}
  proc wglCopyContext*(p1: HGLRC, p2: HGLRC, p3: int): BOOL{.stdcall, importc, wgl.}
  proc wglCreateContext*(DC: HDC): HGLRC{.stdcall, importc, wgl.}
  proc wglCreateLayerContext*(p1: HDC, p2: int): HGLRC{.stdcall, importc, wgl.}
  proc wglDeleteContext*(p1: HGLRC): BOOL{.stdcall, importc, wgl.}
  proc wglDescribeLayerPlane*(p1: HDC, p2, p3: int, p4: int,
                              LayerPlaneDescriptor: pointer): BOOL{.stdcall, importc, wgl.}
  proc wglGetCurrentContext*(): HGLRC{.stdcall, importc, wgl.}
  proc wglGetCurrentDC*(): HDC{.stdcall, importc, wgl.}
  proc wglGetLayerPaletteEntries*(p1: HDC, p2, p3, p4: int, pcr: pointer): int{.
      stdcall, importc, wgl.}
  proc wglMakeCurrent*(DC: HDC, p2: HGLRC): BOOL{.stdcall, importc, wgl.}
  proc wglRealizeLayerPalette*(p1: HDC, p2: int, p3: BOOL): BOOL{.stdcall, importc, wgl.}
  proc wglSetLayerPaletteEntries*(p1: HDC, p2, p3, p4: int, pcr: pointer): int{.
      stdcall, importc, wgl.}
  proc wglShareLists*(p1, p2: HGLRC): BOOL{.stdcall, importc, wgl.}
  proc wglSwapLayerBuffers*(p1: HDC, p2: int): BOOL{.stdcall, importc, wgl.}
  proc wglSwapMultipleBuffers*(p1: int32, p2: PWGLSWAP): int32{.stdcall, importc, wgl.}
  proc wglUseFontBitmapsA*(DC: HDC, p2, p3, p4: int32): BOOL{.stdcall, importc, wgl.}
  proc wglUseFontBitmapsW*(DC: HDC, p2, p3, p4: int32): BOOL{.stdcall, importc, wgl.}
  proc wglUseFontBitmaps*(DC: HDC, p2, p3, p4: int32): BOOL{.stdcall, importc, wgl.}
  proc wglUseFontOutlinesA*(p1: HDC, p2, p3, p4: int32, p5, p6: float32,
                            p7: int, GlyphMetricsFloat: pointer): BOOL{.stdcall, importc, wgl.}
  proc wglUseFontOutlinesW*(p1: HDC, p2, p3, p4: int32, p5, p6: float32,
                            p7: int, GlyphMetricsFloat: pointer): BOOL{.stdcall, importc, wgl.}
  proc wglUseFontOutlines*(p1: HDC, p2, p3, p4: int32, p5, p6: float32, p7: int,
                           GlyphMetricsFloat: pointer): BOOL{.stdcall, importc, wgl.}
    # WGL_ARB_buffer_region
  proc wglCreateBufferRegionARB*(hDC: HDC, iLayerPlane: GLint, uType: GLuint): THandle{.
      stdcall, importc, wgl.}
  proc wglDeleteBufferRegionARB*(hRegion: THandle){.stdcall, importc, wgl.}
  proc wglSaveBufferRegionARB*(hRegion: THandle, x: GLint, y: GLint,
                               width: GLint, height: GLint): bool{.stdcall, importc, wgl.}
  proc wglRestoreBufferRegionARB*(hRegion: THandle, x: GLint, y: GLint,
                                  width: GLint, height: GLint, xSrc: GLint,
                                  ySrc: GLint): bool{.stdcall, importc, wgl.}
    # WGL_ARB_extensions_string
  proc wglGetExtensionsStringARB*(hdc: HDC): cstring{.stdcall, importc, wgl.}
    # WGL_ARB_make_current_read
  proc wglMakeContextCurrentARB*(hDrawDC: HDC, hReadDC: HDC, hglrc: HGLRC): bool{.
      stdcall, importc, wgl.}
  proc wglGetCurrentReadDCARB*(): HDC{.stdcall, importc, wgl.}
    # WGL_ARB_pbuffer
  proc wglCreatePbufferARB*(hDC: HDC, iPixelFormat: GLint, iWidth: GLint,
                            iHeight: GLint, piAttribList: PGLint): HPBUFFERARB{.
      stdcall, importc, wgl.}
  proc wglGetPbufferDCARB*(hPbuffer: HPBUFFERARB): HDC{.stdcall, importc, wgl.}
  proc wglReleasePbufferDCARB*(hPbuffer: HPBUFFERARB, hDC: HDC): GLint{.stdcall, importc, wgl.}
  proc wglDestroyPbufferARB*(hPbuffer: HPBUFFERARB): bool{.stdcall, importc, wgl.}
  proc wglQueryPbufferARB*(hPbuffer: HPBUFFERARB, iAttribute: GLint,
                           piValue: PGLint): bool{.stdcall, importc, wgl.}
    # WGL_ARB_pixel_format
  proc wglGetPixelFormatAttribivARB*(hdc: HDC, iPixelFormat: GLint,
                                     iLayerPlane: GLint, nAttributes: GLuint,
                                     piAttributes: PGLint, piValues: PGLint): bool{.
      stdcall, importc, wgl.}
  proc wglGetPixelFormatAttribfvARB*(hdc: HDC, iPixelFormat: GLint,
                                     iLayerPlane: GLint, nAttributes: GLuint,
                                     piAttributes: PGLint, pfValues: PGLfloat): bool{.
      stdcall, importc, wgl.}
  proc wglChoosePixelFormatARB*(hdc: HDC, piAttribIList: PGLint,
                                pfAttribFList: PGLfloat, nMaxFormats: GLuint,
                                piFormats: PGLint, nNumFormats: PGLuint): BOOL{.
      stdcall, importc, wgl.}
    # WGL_ARB_color_buffer_float
  proc wglClampColorARB*(target: GLenum, clamp: GLenum){.stdcall, importc, wgl.}
    # WGL_ARB_render_texture
  proc wglBindTexImageARB*(hPbuffer: HPBUFFERARB, iBuffer: GLint): bool{.stdcall, importc, wgl.}
  proc wglReleaseTexImageARB*(hPbuffer: HPBUFFERARB, iBuffer: GLint): bool{.
      stdcall, importc, wgl.}
  proc wglSetPbufferAttribARB*(hPbuffer: HPBUFFERARB, piAttribList: PGLint): bool{.
      stdcall, importc, wgl.}
    # WGL_ARB_create_context
  proc wglCreateContextAttribsARB*(hDC: HDC, hShareContext: HGLRC,
                                   attribList: PGLint): HGLRC{.stdcall, importc, wgl.}
    # WGL_AMD_gpu_association
  proc wglGetGPUIDsAMD*(maxCount: int, ids: ptr int): int{.stdcall, importc, wgl.}
  proc wglGetGPUInfoAMD*(id: int, prop: int, dataType: GLenum, size: int,
                         data: Pointer): int{.stdcall, importc, wgl.}
  proc wglGetContextGPUIDAMD*(hglrc: HGLRC): int{.stdcall, importc, wgl.}
  proc wglCreateAssociatedContextAMD*(id: int): HGLRC{.stdcall, importc, wgl.}
  proc wglCreateAssociatedContextAttribsAMD*(id: int, hShareContext: HGLRC,
      attribList: ptr int32): HGLRC{.stdcall, importc, wgl.}
  proc wglDeleteAssociatedContextAMD*(hglrc: HGLRC): bool{.stdcall, importc, wgl.}
  proc wglMakeAssociatedContextCurrentAMD*(hglrc: HGLRC): bool{.stdcall, importc, wgl.}
  proc wglGetCurrentAssociatedContextAMD*(): HGLRC{.stdcall, importc, wgl.}
  proc wglBlitContextFramebufferAMD*(dstCtx: HGLRC, srcX0: GLint, srcY0: GLint,
                                     srcX1: GLint, srcY1: GLint, dstX0: GLint,
                                     dstY0: GLint, dstX1: GLint, dstY1: GLint,
                                     mask: GLbitfield, filter: GLenum){.stdcall, importc, wgl.}
    # WGL_EXT_display_color_table
  proc wglCreateDisplayColorTableEXT*(id: GLushort): GLboolean{.stdcall, importc, wgl.}
  proc wglLoadDisplayColorTableEXT*(table: PGLushort, len: GLuint): GLboolean{.
      stdcall, importc, wgl.}
  proc wglBindDisplayColorTableEXT*(id: GLushort): GLboolean{.stdcall, importc, wgl.}
  proc wglDestroyDisplayColorTableEXT*(id: GLushort){.stdcall, importc, wgl.}
    # WGL_EXT_extensions_string
  proc wglGetExtensionsStringEXT*(): cstring{.stdcall, importc, wgl.}
    # WGL_EXT_make_current_read
  proc wglMakeContextCurrentEXT*(hDrawDC: HDC, hReadDC: HDC, hglrc: HGLRC): bool{.
      stdcall, importc, wgl.}
  proc wglGetCurrentReadDCEXT*(): HDC{.stdcall, importc, wgl.}
    # WGL_EXT_pbuffer
  proc wglCreatePbufferEXT*(hDC: HDC, iPixelFormat: GLint, iWidth: GLint,
                            iHeight: GLint, piAttribList: PGLint): HPBUFFEREXT{.
      stdcall, importc, wgl.}
  proc wglGetPbufferDCEXT*(hPbuffer: HPBUFFEREXT): HDC{.stdcall, importc, wgl.}
  proc wglReleasePbufferDCEXT*(hPbuffer: HPBUFFEREXT, hDC: HDC): GLint{.stdcall, importc, wgl.}
  proc wglDestroyPbufferEXT*(hPbuffer: HPBUFFEREXT): bool{.stdcall, importc, wgl.}
  proc wglQueryPbufferEXT*(hPbuffer: HPBUFFEREXT, iAttribute: GLint,
                           piValue: PGLint): bool{.stdcall, importc, wgl.}
    # WGL_EXT_pixel_format
  proc wglGetPixelFormatAttribivEXT*(hdc: HDC, iPixelFormat: GLint,
                                     iLayerPlane: GLint, nAttributes: GLuint,
                                     piAttributes: PGLint, piValues: PGLint): bool{.
      stdcall, importc, wgl.}
  proc wglGetPixelFormatAttribfvEXT*(hdc: HDC, iPixelFormat: GLint,
                                     iLayerPlane: GLint, nAttributes: GLuint,
                                     piAttributes: PGLint, pfValues: PGLfloat): bool{.
      stdcall, importc, wgl.}
  proc wglChoosePixelFormatEXT*(hdc: HDC, piAttribIList: PGLint,
                                pfAttribFList: PGLfloat, nMaxFormats: GLuint,
                                piFormats: PGLint, nNumFormats: PGLuint): bool{.
      stdcall, importc, wgl.}
    # WGL_EXT_swap_control
  proc wglSwapIntervalEXT*(interval: GLint): bool{.stdcall, importc, wgl.}
  proc wglGetSwapIntervalEXT*(): GLint{.stdcall, importc, wgl.}
    # WGL_I3D_digital_video_control
  proc wglGetDigitalVideoParametersI3D*(hDC: HDC, iAttribute: GLint,
                                        piValue: PGLint): bool{.stdcall, importc, wgl.}
  proc wglSetDigitalVideoParametersI3D*(hDC: HDC, iAttribute: GLint,
                                        piValue: PGLint): bool{.stdcall, importc, wgl.}
    # WGL_I3D_gamma
  proc wglGetGammaTableParametersI3D*(hDC: HDC, iAttribute: GLint,
                                      piValue: PGLint): bool{.stdcall, importc, wgl.}
  proc wglSetGammaTableParametersI3D*(hDC: HDC, iAttribute: GLint,
                                      piValue: PGLint): bool{.stdcall, importc, wgl.}
  proc wglGetGammaTableI3D*(hDC: HDC, iEntries: GLint, puRed: PGLushort,
                            puGreen: PGLushort, puBlue: PGLushort): bool{.
      stdcall, importc, wgl.}
  proc wglSetGammaTableI3D*(hDC: HDC, iEntries: GLint, puRed: PGLushort,
                            puGreen: PGLushort, puBlue: PGLushort): bool{.
      stdcall, importc, wgl.}
    # WGL_I3D_genlock
  proc wglEnableGenlockI3D*(hDC: HDC): bool{.stdcall, importc, wgl.}
  proc wglDisableGenlockI3D*(hDC: HDC): bool{.stdcall, importc, wgl.}
  proc wglIsEnabledGenlockI3D*(hDC: HDC, pFlag: bool): bool{.stdcall, importc, wgl.}
  proc wglGenlockSourceI3D*(hDC: HDC, uSource: GLuint): bool{.stdcall, importc, wgl.}
  proc wglGetGenlockSourceI3D*(hDC: HDC, uSource: PGLuint): bool{.stdcall, importc, wgl.}
  proc wglGenlockSourceEdgeI3D*(hDC: HDC, uEdge: GLuint): bool{.stdcall, importc, wgl.}
  proc wglGetGenlockSourceEdgeI3D*(hDC: HDC, uEdge: PGLuint): bool{.stdcall, importc, wgl.}
  proc wglGenlockSampleRateI3D*(hDC: HDC, uRate: GLuint): bool{.stdcall, importc, wgl.}
  proc wglGetGenlockSampleRateI3D*(hDC: HDC, uRate: PGLuint): bool{.stdcall, importc, wgl.}
  proc wglGenlockSourceDelayI3D*(hDC: HDC, uDelay: GLuint): bool{.stdcall, importc, wgl.}
  proc wglGetGenlockSourceDelayI3D*(hDC: HDC, uDelay: PGLuint): bool{.stdcall, importc, wgl.}
  proc wglQueryGenlockMaxSourceDelayI3D*(hDC: HDC, uMaxLineDelay: PGLuint,
      uMaxPixelDelay: PGLuint): bool{.stdcall, importc, wgl.}
    # WGL_I3D_image_buffer
  proc wglCreateImageBufferI3D*(hDC: HDC, dwSize: GLuint, uFlags: GLuint): GLvoid{.
      stdcall, importc, wgl.}
  proc wglDestroyImageBufferI3D*(hDC: HDC, pAddress: GLvoid): bool{.stdcall, importc, wgl.}
  proc wglAssociateImageBufferEventsI3D*(hDC: HDC, pEvent: THandle,
      pAddress: PGLvoid, pSize: PGLuint, count: GLuint): bool{.stdcall, importc, wgl.}
  proc wglReleaseImageBufferEventsI3D*(hDC: HDC, pAddress: PGLvoid,
                                       count: GLuint): bool{.stdcall, importc, wgl.}
    # WGL_I3D_swap_frame_lock
  proc wglEnableFrameLockI3D*(): bool{.stdcall, importc, wgl.}
  proc wglDisableFrameLockI3D*(): bool{.stdcall, importc, wgl.}
  proc wglIsEnabledFrameLockI3D*(pFlag: bool): bool{.stdcall, importc, wgl.}
  proc wglQueryFrameLockMasterI3D*(pFlag: bool): bool{.stdcall, importc, wgl.}
    # WGL_I3D_swap_frame_usage
  proc wglGetFrameUsageI3D*(pUsage: PGLfloat): bool{.stdcall, importc, wgl.}
  proc wglBeginFrameTrackingI3D*(): bool{.stdcall, importc, wgl.}
  proc wglEndFrameTrackingI3D*(): bool{.stdcall, importc, wgl.}
  proc wglQueryFrameTrackingI3D*(pFrameCount: PGLuint, pMissedFrames: PGLuint,
                                 pLastMissedUsage: PGLfloat): bool{.stdcall, importc, wgl.}
    # WGL_NV_vertex_array_range
  proc wglAllocateMemoryNV*(size: GLsizei, readfreq: GLfloat,
                            writefreq: GLfloat, priority: GLfloat){.stdcall, importc, wgl.}
  proc wglFreeMemoryNV*(pointer: Pointer){.stdcall, importc, wgl.}
    # WGL_NV_present_video
  proc wglEnumerateVideoDevicesNV*(hdc: HDC, phDeviceList: PHVIDEOOUTPUTDEVICENV): int{.
      stdcall, importc, wgl.}
  proc wglBindVideoDeviceNV*(hd: HDC, uVideoSlot: int,
                             hVideoDevice: HVIDEOOUTPUTDEVICENV,
                             piAttribList: ptr int32): bool{.stdcall, importc, wgl.}
  proc wglQueryCurrentContextNV*(iAttribute: int, piValue: ptr int32): bool{.
      stdcall, importc, wgl.}
    # WGL_NV_video_output
  proc wglGetVideoDeviceNV*(hDC: HDC, numDevices: int, hVideoDevice: PHPVIDEODEV): bool{.
      stdcall, importc, wgl.}
  proc wglReleaseVideoDeviceNV*(hVideoDevice: HPVIDEODEV): bool{.stdcall, importc, wgl.}
  proc wglBindVideoImageNV*(hVideoDevice: HPVIDEODEV, hPbuffer: HPBUFFERARB,
                            iVideoBuffer: int): bool{.stdcall, importc, wgl.}
  proc wglReleaseVideoImageNV*(hPbuffer: HPBUFFERARB, iVideoBuffer: int): bool{.
      stdcall, importc, wgl.}
  proc wglSendPbufferToVideoNV*(hPbuffer: HPBUFFERARB, iBufferType: int,
                                pulCounterPbuffer: ptr int, bBlock: bool): bool{.
      stdcall, importc, wgl.}
  proc wglGetVideoInfoNV*(hpVideoDevice: HPVIDEODEV,
                          pulCounterOutputPbuffer: ptr int,
                          pulCounterOutputVideo: ptr int): bool{.stdcall, importc, wgl.}
    # WGL_NV_swap_group
  proc wglJoinSwapGroupNV*(hDC: HDC, group: GLuint): bool{.stdcall, importc, wgl.}
  proc wglBindSwapBarrierNV*(group: GLuint, barrier: GLuint): bool{.stdcall, importc, wgl.}
  proc wglQuerySwapGroupNV*(hDC: HDC, group: PGLuint, barrier: PGLuint): bool{.
      stdcall, importc, wgl.}
  proc wglQueryMaxSwapGroupsNV*(hDC: HDC, mxGroups: PGLuint,
                                maxBarriers: PGLuint): bool{.stdcall, importc, wgl.}
  proc wglQueryFrameCountNV*(hDC: HDC, count: PGLuint): bool{.stdcall, importc, wgl.}
  proc wglResetFrameCountNV*(hDC: HDC): bool{.stdcall, importc, wgl.}
    # WGL_NV_gpu_affinity
  proc wglEnumGpusNV*(iGpuIndex: int, phGpu: PHGPUNV): bool{.stdcall, importc, wgl.}
  proc wglEnumGpuDevicesNV*(hGpu: HGPUNV, iDeviceIndex: int,
                            lpGpuDevice: PGPU_DEVICE): bool{.stdcall, importc, wgl.}
  proc wglCreateAffinityDCNV*(phGpuList: PHGPUNV): HDC{.stdcall, importc, wgl.}
  proc wglEnumGpusFromAffinityDCNV*(hAffinityDC: HDC, iGpuIndex: int,
                                    hGpu: PHGPUNV): bool{.stdcall, importc, wgl.}
  proc wglDeleteDCNV*(hDC: HDC): bool{.stdcall, importc, wgl.}
    # WGL_NV_video_capture
  proc wglBindVideoCaptureDeviceNV*(uVideoSlot: int,
                                    hDevice: HVIDEOINPUTDEVICENV): bool{.stdcall, importc, wgl.}
  proc wglEnumerateVideoCaptureDevicesNV*(hDc: HDC,
      phDeviceList: PHVIDEOINPUTDEVICENV): int{.stdcall, importc, wgl.}
  proc wglLockVideoCaptureDeviceNV*(hDc: HDC, hDevice: HVIDEOINPUTDEVICENV): bool{.
      stdcall, importc, wgl.}
  proc wglQueryVideoCaptureDeviceNV*(hDc: HDC, hDevice: HVIDEOINPUTDEVICENV,
                                     iAttribute: int, piValue: ptr int32): bool{.
      stdcall, importc, wgl.}
  proc wglReleaseVideoCaptureDeviceNV*(hDc: HDC, hDevice: HVIDEOINPUTDEVICENV): bool{.
      stdcall, importc, wgl.}
    # WGL_NV_copy_image
  proc wglCopyImageSubDataNV*(hSrcRc: HGLRC, srcName: GLuint, srcTarget: GLenum,
                              srcLevel: GLint, srcX: GLint, srcY: GLint,
                              srcZ: GLint, hDstRC: HGLRC, dstName: GLuint,
                              dstTarget: GLenum, dstLevel: GLint, dstX: GLint,
                              dstY: GLint, dstZ: GLint, width: GLsizei,
                              height: GLsizei, depth: GLsizei): bool{.stdcall, importc, wgl.}
    # WGL_NV_DX_interop
  proc wglDXSetResourceShareHandleNV*(dxObject: PGLVoid, hareHandle: int): bool{.
      stdcall, importc, wgl.}
  proc wglDXOpenDeviceNV*(dxDevice: PGLVoid): int{.stdcall, importc, wgl.}
  proc wglDXCloseDeviceNV*(hDevice: int): bool{.stdcall, importc, wgl.}
  proc wglDXRegisterObjectNV*(hDevice: int, dxObject: PGLVoid, name: GLUInt,
                              typ: TGLEnum, access: TGLenum): int{.stdcall, importc, wgl.}
  proc wglDXUnregisterObjectNV*(hDevice: int, hObject: int): bool{.stdcall, importc, wgl.}
  proc wglDXObjectAccessNV*(hObject: int, access: GLenum): bool{.stdcall, importc, wgl.}
  proc wglDXLockObjectsNV*(hDevice: int, count: GLint, hObjects: ptr int): bool{.
      stdcall, importc, wgl.}
  proc wglDXUnlockObjectsNV*(hDevice: int, count: GLint, hObjects: ptr int): bool{.
      stdcall, importc, wgl.}
    # WGL_OML_sync_control
  proc wglGetSyncValuesOML*(hdc: HDC, ust: PGLint64, msc: PGLint64,
                            sbc: PGLint64): bool{.stdcall, importc, wgl.}
  proc wglGetMscRateOML*(hdc: HDC, numerator: PGLint, denominator: PGLint): bool{.
      stdcall, importc, wgl.}
  proc wglSwapBuffersMscOML*(hdc: HDC, target_msc: GLint64, divisor: GLint64,
                             remainder: GLint64): GLint64{.stdcall, importc, wgl.}
  proc wglSwapLayerBuffersMscOML*(hdc: HDC, fuPlanes: GLint,
                                  target_msc: GLint64, divisor: GLint64,
                                  remainder: GLint64): GLint64{.stdcall, importc, wgl.}
  proc wglWaitForMscOML*(hdc: HDC, target_msc: GLint64, divisor: GLint64,
                         remainder: GLint64, ust: PGLint64, msc: PGLint64,
                         sbc: PGLint64): bool{.stdcall, importc, wgl.}
  proc wglWaitForSbcOML*(hdc: HDC, target_sbc: GLint64, ust: PGLint64,
                         msc: PGLint64, sbc: PGLint64): bool{.stdcall, importc, wgl.}
    # WGL_3DL_stereo_control
  proc wglSetStereoEmitterState3DL*(hDC: HDC, uState: int32): bool{.stdcall, importc, wgl.}
    # WIN_draw_range_elements
  proc glDrawRangeElementsWIN*(mode: GLenum, start: GLuint, ending: GLuint,
                               count: GLsizei, typ: GLenum, indices: PGLvoid){.
      stdcall, importc, wgl.}
    # WIN_swap_hint
  proc glAddSwapHintRectWIN*(x: GLint, y: GLint, width: GLsizei, height: GLsizei){.
      stdcall, importc, wgl.}
when defined(LINUX):
  proc glXChooseVisual*(dpy: PDisplay, screen: GLint, attribList: PGLint): PXVisualInfo{.
      stdcall, importc, oglx.}
  proc glXCopyContext*(dpy: PDisplay, src: GLXContext, dst: GLXContext,
                       mask: GLuint){.stdcall, importc, oglx.}
  proc glXCreateContext*(dpy: PDisplay, vis: PXVisualInfo,
                         shareList: GLXContext, direct: GLboolean): GLXContext{.
      stdcall, importc, oglx.}
  proc glXCreateGLXPixmap*(dpy: PDisplay, vis: PXVisualInfo, pixmap: Pixmap): GLXPixmap{.
      stdcall, importc, oglx.}
  proc glXDestroyContext*(dpy: PDisplay, ctx: GLXContext){.stdcall, importc, oglx.}
  proc glXDestroyGLXPixmap*(dpy: PDisplay, pix: GLXPixmap){.stdcall, importc, oglx.}
  proc glXGetConfig*(dpy: PDisplay, vis: PXVisualInfo, attrib: GLint,
                     value: PGLint): GLint{.stdcall, importc, oglx.}
  proc glXGetCurrentContext*(): GLXContext{.stdcall, importc, oglx.}
  proc glXGetCurrentDrawable*(): GLXDrawable{.stdcall, importc, oglx.}
  proc glXIsDirect*(dpy: PDisplay, ctx: GLXContext): glboolean{.stdcall, importc, oglx.}
  proc glXMakeCurrent*(dpy: PDisplay, drawable: GLXDrawable, ctx: GLXContext): GLboolean{.
      stdcall, importc, oglx.}
  proc glXQueryExtension*(dpy: PDisplay, errorBase: PGLint, eventBase: PGLint): GLboolean{.
      stdcall, importc, oglx.}
  proc glXQueryVersion*(dpy: PDisplay, major: PGLint, minor: PGLint): GLboolean{.
      stdcall, importc, oglx.}
  proc glXSwapBuffers*(dpy: PDisplay, drawable: GLXDrawable){.stdcall, importc, oglx.}
  proc glXUseXFont*(font: Font, first: GLint, count: GLint, listBase: GLint){.
      stdcall, importc, oglx.}
  proc glXWaitGL*(){.stdcall, importc, oglx.}
  proc glXWaitX*(){.stdcall, importc, oglx.}
  proc glXGetClientString*(dpy: PDisplay, name: GLint): PGLchar{.stdcall, importc, oglx.}
  proc glXQueryServerString*(dpy: PDisplay, screen: GLint, name: GLint): PGLchar{.
      stdcall, importc, oglx.}
  proc glXQueryExtensionsString*(dpy: PDisplay, screen: GLint): PGLchar{.stdcall, importc, oglx.}
    # GLX_VERSION_1_3
  proc glXGetFBConfigs*(dpy: PDisplay, screen: GLint, nelements: PGLint): GLXFBConfig{.
      stdcall, importc, oglx.}
  proc glXChooseFBConfig*(dpy: PDisplay, screen: GLint, attrib_list: PGLint,
                          nelements: PGLint): GLXFBConfig{.stdcall, importc, oglx.}
  proc glXGetFBConfigAttrib*(dpy: PDisplay, config: GLXFBConfig,
                             attribute: GLint, value: PGLint): glint{.stdcall, importc, oglx.}
  proc glXGetVisualFromFBConfig*(dpy: PDisplay, config: GLXFBConfig): PXVisualInfo{.stdcall, importc, oglx.}
  proc glXCreateWindow*(dpy: PDisplay, config: GLXFBConfig, win: Window,
                        attrib_list: PGLint): GLXWindow{.stdcall, importc, oglx.}
  proc glXDestroyWindow*(dpy: PDisplay, win: GLXWindow){.stdcall, importc, oglx.}
  proc glXCreatePixmap*(dpy: PDisplay, config: GLXFBConfig, pixmap: Pixmap,
                        attrib_list: PGLint): GLXPixmap{.stdcall, importc, oglx.}
  proc glXDestroyPixmap*(dpy: PDisplay, pixmap: GLXPixmap){.stdcall, importc, oglx.}
  proc glXCreatePbuffer*(dpy: PDisplay, config: GLXFBConfig, attrib_list: PGLint): GLXPbuffer{.
      stdcall, importc, oglx.}
  proc glXDestroyPbuffer*(dpy: PDisplay, pbuf: GLXPbuffer){.stdcall, importc, oglx.}
  proc glXQueryDrawable*(dpy: PDisplay, draw: GLXDrawable, attribute: GLint,
                         value: PGLuint){.stdcall, importc, oglx.}
  proc glXCreateNewContext*(dpy: PDisplay, config: GLXFBConfig,
                            rendertyp: GLint, share_list: GLXContext,
                            direct: GLboolean): GLXContext{.stdcall, importc, oglx.}
  proc glXMakeContextCurrent*(display: PDisplay, draw: GLXDrawable,
                              read: GLXDrawable, ctx: GLXContext): GLboolean{.
      stdcall, importc, oglx.}
  proc glXGetCurrentReadDrawable*(): GLXDrawable{.stdcall, importc, oglx.}
  proc glXGetCurreentDisplay*(): PDisplay{.stdcall, importc, oglx.}
  proc glXQueryContext*(dpy: PDisplay, ctx: GLXContext, attribute: GLint,
                        value: PGLint): GLint{.stdcall, importc, oglx.}
  proc glXSelectEvent*(dpy: PDisplay, draw: GLXDrawable, event_mask: GLuint){.
      stdcall, importc, oglx.}
  proc glXGetSelectedEvent*(dpy: PDisplay, draw: GLXDrawable,
                            event_mask: PGLuint){.stdcall, importc, oglx.}
    # GLX_VERSION_1_4
  when not defined(glXGetProcAddress):
    proc glXGetProcAddress*(name: cstring): pointer{.stdcall, importc, oglx.}
    # GLX_ARB_get_proc_address
  when not defined(glXGetProcAddressARB):
    proc glXGetProcAddressARB*(name: cstring): pointer{.stdcall, importc, oglx.}
    # GLX_ARB_create_context
  proc glXCreateContextAttribsARB*(dpy: PDisplay, config: GLXFBConfig,
                                   share_context: GLXContext, direct: GLboolean,
                                   attrib_list: PGLint): GLXContext{.stdcall, importc, oglx.}
    # GLX_EXT_import_context
  proc glXGetCurrentDisplayEXT*(): PDisplay{.stdcall, importc, oglx.}
  proc glXQueryContextInfoEXT*(dpy: PDisplay, context: GLXContext,
                               attribute: GLint, value: PGLint): GLint{.stdcall, importc, oglx.}
  proc glXGetContextIDEXT*(context: GLXContext): GLXContextID{.stdcall, importc, oglx.}
  proc glXImportContextEXT*(dpy: PDisplay, contextID: GLXContextID): GLXContext{.
      stdcall, importc, oglx.}
  proc glXFreeContextEXT*(dpy: PDisplay, context: GLXContext){.stdcall, importc, oglx.}
    # GLX_EXT_texture_from_pixmap
  proc glXBindTexImageEXT*(dpy: PDisplay, drawable: GLXDrawable, buffer: GLint,
                           attrib_list: PGLint){.stdcall, importc, oglx.}
  proc glXReleaseTexImageEXT*(dpy: PDisplay, drawable: GLXDrawable,
                              buffer: GLint){.stdcall, importc, oglx.}
# GL utility functions and procedures

proc gluErrorString*(errCode: GLEnum): cstring{.stdcall, importc, glu.}
proc gluGetString*(name: GLEnum): cstring{.stdcall, importc, glu.}
proc gluOrtho2D*(left, right, bottom, top: GLdouble){.stdcall, importc, glu.}
proc gluPerspective*(fovy, aspect, zNear, zFar: GLdouble){.stdcall, importc, glu.}
proc gluPickMatrix*(x, y, width, height: GLdouble, viewport: TVector4i){.stdcall, importc, glu.}
proc gluLookAt*(eyex, eyey, eyez, centerx, centery, centerz, upx, upy, upz: GLdouble){.
    stdcall, importc, glu.}
proc gluProject*(objx, objy, objz: GLdouble, modelMatrix: TGLMatrixd4,
                 projMatrix: TGLMatrixd4, viewport: TVector4i,
                 winx, winy, winz: PGLdouble): GLint{.stdcall, importc, glu.}
proc gluUnProject*(winx, winy, winz: GLdouble, modelMatrix: TGLMatrixd4,
                   projMatrix: TGLMatrixd4, viewport: TVector4i,
                   objx, objy, objz: PGLdouble): GLint{.stdcall, importc, glu.}
proc gluScaleImage*(format: GLEnum, widthin, heightin: GLint, typein: GLEnum,
                    datain: Pointer, widthout, heightout: GLint,
                    typeout: GLEnum, dataout: Pointer): GLint{.stdcall, importc, glu.}
proc gluBuild1DMipmaps*(target: GLEnum, components, width: GLint,
                        format, atype: GLEnum, data: Pointer): GLint{.stdcall, importc, glu.}
proc gluBuild2DMipmaps*(target: GLEnum, components, width, height: GLint,
                        format, atype: GLEnum, Data: Pointer): GLint{.stdcall, importc, glu.}
proc gluNewQuadric*(): PGLUquadric{.stdcall, importc, glu.}
proc gluDeleteQuadric*(state: PGLUquadric){.stdcall, importc, glu.}
proc gluQuadricNormals*(quadObject: PGLUquadric, normals: GLEnum){.stdcall, importc, glu.}
proc gluQuadricTexture*(quadObject: PGLUquadric, textureCoords: GLboolean){.
    stdcall, importc, glu.}
proc gluQuadricOrientation*(quadObject: PGLUquadric, orientation: GLEnum){.
    stdcall, importc, glu.}
proc gluQuadricDrawStyle*(quadObject: PGLUquadric, drawStyle: GLEnum){.stdcall, importc, glu.}
proc gluCylinder*(quadObject: PGLUquadric,
                  baseRadius, topRadius, height: GLdouble, slices, stacks: GLint){.
    stdcall, importc, glu.}
proc gluDisk*(quadObject: PGLUquadric, innerRadius, outerRadius: GLdouble,
              slices, loops: GLint){.stdcall, importc, glu.}
proc gluPartialDisk*(quadObject: PGLUquadric,
                     innerRadius, outerRadius: GLdouble, slices, loops: GLint,
                     startAngle, sweepAngle: GLdouble){.stdcall, importc, glu.}
proc gluSphere*(quadObject: PGLUquadric, radius: GLdouble, slices, stacks: GLint){.
    stdcall, importc, glu.}
proc gluQuadricCallback*(quadObject: PGLUquadric, which: GLEnum,
                         fn: TGLUQuadricErrorProc){.stdcall, importc, glu.}
proc gluNewTess*(): PGLUtesselator{.stdcall, importc, glu.}
proc gluDeleteTess*(tess: PGLUtesselator){.stdcall, importc, glu.}
proc gluTessBeginPolygon*(tess: PGLUtesselator, polygon_data: Pointer){.stdcall, importc, glu.}
proc gluTessBeginContour*(tess: PGLUtesselator){.stdcall, importc, glu.}
proc gluTessVertex*(tess: PGLUtesselator, coords: TGLArrayd3, data: Pointer){.
    stdcall, importc, glu.}
proc gluTessEndContour*(tess: PGLUtesselator){.stdcall, importc, glu.}
proc gluTessEndPolygon*(tess: PGLUtesselator){.stdcall, importc, glu.}
proc gluTessProperty*(tess: PGLUtesselator, which: GLEnum, value: GLdouble){.
    stdcall, importc, glu.}
proc gluTessNormal*(tess: PGLUtesselator, x, y, z: GLdouble){.stdcall, importc, glu.}
proc gluTessCallback*(tess: PGLUtesselator, which: GLEnum, fn: Pointer){.stdcall, importc, glu.}
proc gluGetTessProperty*(tess: PGLUtesselator, which: GLEnum, value: PGLdouble){.
    stdcall, importc, glu.}
proc gluNewNurbsRenderer*(): PGLUnurbs{.stdcall, importc, glu.}
proc gluDeleteNurbsRenderer*(nobj: PGLUnurbs){.stdcall, importc, glu.}
proc gluBeginSurface*(nobj: PGLUnurbs){.stdcall, importc, glu.}
proc gluBeginCurve*(nobj: PGLUnurbs){.stdcall, importc, glu.}
proc gluEndCurve*(nobj: PGLUnurbs){.stdcall, importc, glu.}
proc gluEndSurface*(nobj: PGLUnurbs){.stdcall, importc, glu.}
proc gluBeginTrim*(nobj: PGLUnurbs){.stdcall, importc, glu.}
proc gluEndTrim*(nobj: PGLUnurbs){.stdcall, importc, glu.}
proc gluPwlCurve*(nobj: PGLUnurbs, count: GLint, points: PGLfloat,
                  stride: GLint, atype: GLEnum){.stdcall, importc, glu.}
proc gluNurbsCurve*(nobj: PGLUnurbs, nknots: GLint, knot: PGLfloat,
                    stride: GLint, ctlarray: PGLfloat, order: GLint,
                    atype: GLEnum){.stdcall, importc, glu.}
proc gluNurbsSurface*(nobj: PGLUnurbs, sknot_count: GLint, sknot: PGLfloat,
                      tknot_count: GLint, tknot: PGLfloat,
                      s_stride, t_stride: GLint, ctlarray: PGLfloat,
                      sorder, torder: GLint, atype: GLEnum){.stdcall, importc, glu.}
proc gluLoadSamplingMatrices*(nobj: PGLUnurbs,
                              modelMatrix, projMatrix: TGLMatrixf4,
                              viewport: TVector4i){.stdcall, importc, glu.}
proc gluNurbsProperty*(nobj: PGLUnurbs, aproperty: GLEnum, value: GLfloat){.
    stdcall, importc, glu.}
proc gluGetNurbsProperty*(nobj: PGLUnurbs, aproperty: GLEnum, value: PGLfloat){.
    stdcall, importc, glu.}
proc gluNurbsCallback*(nobj: PGLUnurbs, which: GLEnum, fn: TGLUNurbsErrorProc){.
    stdcall, importc, glu.}
proc gluBeginPolygon*(tess: PGLUtesselator){.stdcall, importc, glu.}
proc gluNextContour*(tess: PGLUtesselator, atype: GLEnum){.stdcall, importc, glu.}
proc gluEndPolygon*(tess: PGLUtesselator){.stdcall, importc, glu.}

type
  TRCOption* = enum
    opDoubleBuffered, opGDI, opStereo
  TRCOptions* = set[TRCOption]

var LastPixelFormat*: int

when defined(windows):
  proc CreateRenderingContext*(DC: HDC, Options: TRCOptions, ColorBits, ZBits,
      StencilBits, AccumBits, AuxBuffers: int, Layer: int): HGLRC
  proc DestroyRenderingContext*(RC: HGLRC)
  proc ActivateRenderingContext*(DC: HDC, RC: HGLRC)
  proc DeactivateRenderingContext*()
# implementation

proc GetExtensionString*(): string =
  when defined(windows):
    result = $glGetString(GL_EXTENSIONS) & ' ' & $wglGetExtensionsStringEXT() &
        ' ' & $wglGetExtensionsStringARB(wglGetCurrentDC())
  else:
    result = $glGetString(GL_EXTENSIONS)

when defined(windows):
  proc CreateRenderingContext(DC: HDC, Options: TRCOptions, ColorBits, ZBits,
      StencilBits, AccumBits, AuxBuffers: int, Layer: int): HGLRC =
    type
      TPIXELFORMATDESCRIPTOR {.final, pure.} = object
        nSize: int16
        nVersion: int16
        dwFlags: DWORD
        iPixelType: int8
        cColorBits: int8
        cRedBits: int8
        cRedShift: int8
        cGreenBits: int8
        cGreenShift: int8
        cBlueBits: int8
        cBlueShift: int8
        cAlphaBits: int8
        cAlphaShift: int8
        cAccumBits: int8
        cAccumRedBits: int8
        cAccumGreenBits: int8
        cAccumBlueBits: int8
        cAccumAlphaBits: int8
        cDepthBits: int8
        cStencilBits: int8
        cAuxBuffers: int8
        iLayerType: int8
        bReserved: int8
        dwLayerMask: DWORD
        dwVisibleMask: DWORD
        dwDamageMask: DWORD

    proc GetObjectType(h: HDC): DWORD{.stdcall, dynlib: "gdi32",
                                           importc: "GetObjectType".}
    proc ChoosePixelFormat(para1: HDC, para2: ptr TPIXELFORMATDESCRIPTOR): int32{.
        stdcall, dynlib: "gdi32", importc: "ChoosePixelFormat".}
    proc GetPixelFormat(para1: HDC): int32{.stdcall, dynlib: "gdi32",
        importc: "GetPixelFormat".}
    proc SetPixelFormat(para1: HDC, para2: int32,
        para3: ptr TPIXELFORMATDESCRIPTOR): WINBOOL{.
        stdcall, dynlib: "gdi32", importc: "SetPixelFormat".}
    proc DescribePixelFormat(para1: HDC, para2, para3: int32,
                             para4: ptr TPIXELFORMATDESCRIPTOR) {.stdcall,
        dynlib: "gdi32", importc: "DescribePixelFormat".}

    const
      OBJ_MEMDC = 10'i32
      OBJ_ENHMETADC = 12'i32
      OBJ_METADC = 4'i32
      PFD_DOUBLEBUFFER = 0x00000001
      PFD_STEREO = 0x00000002
      PFD_DRAW_TO_WINDOW = 0x00000004
      PFD_DRAW_TO_BITMAP = 0x00000008
      PFD_SUPPORT_GDI = 0x00000010
      PFD_SUPPORT_OPENGL = 0x00000020
      PFDtyp_RGBA = 0'i8
      PFD_MAIN_PLANE = 0'i8
      PFD_OVERLAY_PLANE = 1'i8
      PFD_UNDERLAY_PLANE = int32(- 1)
    var
      PFDescriptor: TPixelFormatDescriptor
      PixelFormat: int32
      AType: int32
    PFDescriptor.nSize = SizeOf(PFDescriptor).int16
    PFDescriptor.nVersion = 1'i16
    PFDescriptor.dwFlags = PFD_SUPPORT_OPENGL
    AType = GetObjectType(DC)
    if AType == 0: OSError()
    if AType == OBJ_MEMDC or AType == OBJ_METADC or AType == OBJ_ENHMETADC:
      PFDescriptor.dwFlags = PFDescriptor.dwFlags or PFD_DRAW_TO_BITMAP
    else:
      PFDescriptor.dwFlags = PFDescriptor.dwFlags or PFD_DRAW_TO_WINDOW
    if opDoubleBuffered in Options:
      PFDescriptor.dwFlags = PFDescriptor.dwFlags or PFD_DOUBLEBUFFER
    if opGDI in Options:
      PFDescriptor.dwFlags = PFDescriptor.dwFlags or PFD_SUPPORT_GDI
    if opStereo in Options:
      PFDescriptor.dwFlags = PFDescriptor.dwFlags or PFD_STEREO
    PFDescriptor.iPixelType = PFDtyp_RGBA
    PFDescriptor.cColorBits = ColorBits.toU8
    PFDescriptor.cDepthBits = zBits.toU8
    PFDescriptor.cStencilBits = StencilBits.toU8
    PFDescriptor.cAccumBits = AccumBits.toU8
    PFDescriptor.cAuxBuffers = AuxBuffers.toU8
    if Layer == 0: PFDescriptor.iLayerType = PFD_MAIN_PLANE
    elif Layer > 0: PFDescriptor.iLayerType = PFD_OVERLAY_PLANE
    else: PFDescriptor.iLayerType = int8(PFD_UNDERLAY_PLANE)
    PixelFormat = ChoosePixelFormat(DC, addr(PFDescriptor))
    if PixelFormat == 0: OSError()
    if GetPixelFormat(DC) != PixelFormat:
      if SetPixelFormat(DC, PixelFormat, addr(PFDescriptor)) == 0'i32:
        OSError()
    DescribePixelFormat(DC, PixelFormat.int32, SizeOf(PFDescriptor).int32,
                        addr(PFDescriptor))
    Result = wglCreateContext(DC)
    if Result == 0: OSError()
    else: LastPixelFormat = 0

  proc DestroyRenderingContext(RC: HGLRC) =
    discard wglDeleteContext(RC)

  proc ActivateRenderingContext(DC: HDC, RC: HGLRC) =
    discard wglMakeCurrent(DC, RC)

  proc DeactivateRenderingContext() =
    discard wglMakeCurrent(0, 0)
