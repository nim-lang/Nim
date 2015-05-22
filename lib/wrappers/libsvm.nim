#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module is a low level wrapper for `libsvm`:idx:.

{.deadCodeElim: on.}
const 
  LIBSVM_VERSION* = 312
  
when defined(windows):
  const svmdll* = "libsvm.dll"
elif defined(macosx):
  const svmdll* = "libsvm.dylib"
else:
  const svmdll* = "libsvm.so"

type 
  Node*{.pure, final.} = object 
    index*: cint
    value*: cdouble

  Problem*{.pure, final.} = object 
    L*: cint
    y*: ptr cdouble
    x*: ptr ptr Node

  Type*{.size: sizeof(cint).} = enum 
    C_SVC, NU_SVC, ONE_CLASS, EPSILON_SVR, NU_SVR
  
  KernelType*{.size: sizeof(cint).} = enum 
    LINEAR, POLY, RBF, SIGMOID, PRECOMPUTED
  
  Parameter*{.pure, final.} = object 
    typ*: Type
    kernelType*: KernelType
    degree*: cint             # for poly 
    gamma*: cdouble           # for poly/rbf/sigmoid 
    coef0*: cdouble           # for poly/sigmoid 
                              # these are for training only 
    cache_size*: cdouble      # in MB 
    eps*: cdouble             # stopping criteria 
    C*: cdouble               # for C_SVC, EPSILON_SVR and NU_SVR 
    nr_weight*: cint          # for C_SVC 
    weight_label*: ptr cint   # for C_SVC 
    weight*: ptr cdouble      # for C_SVC 
    nu*: cdouble              # for NU_SVC, ONE_CLASS, and NU_SVR 
    p*: cdouble               # for EPSILON_SVR 
    shrinking*: cint          # use the shrinking heuristics 
    probability*: cint        # do probability estimates 
{.deprecated: [Tnode: Node, Tproblem: Problem, Ttype: Type,
              TKernelType: KernelType, Tparameter: Parameter].}

#
# svm_model
# 

type 
  Model*{.pure, final.} = object 
    param*: Parameter         # parameter 
    nr_class*: cint           # number of classes, = 2 in regression/one class svm 
    L*: cint                  # total #SV 
    SV*: ptr ptr Node         # SVs (SV[l])
    sv_coef*: ptr ptr cdouble # coefficients for SVs in decision functions (sv_coef[k-1][l]) 
    rho*: ptr cdouble         # constants in decision functions (rho[k*(k-1)/2]) 
    probA*: ptr cdouble       # pariwise probability information 
    probB*: ptr cdouble       # for classification only 
    label*: ptr cint          # label of each class (label[k]) 
    nSV*: ptr cint            # number of SVs for each class (nSV[k]) 
                              # nSV[0] + nSV[1] + ... + nSV[k-1] = l 
                              # XXX 
    free_sv*: cint            # 1 if svm_model is created by svm_load_model
                              # 0 if svm_model is created by svm_train
{.deprecated: [TModel: Model].}

proc train*(prob: ptr Problem, param: ptr Parameter): ptr Model{.cdecl, 
    importc: "svm_train", dynlib: svmdll.}
proc cross_validation*(prob: ptr Problem, param: ptr Parameter, nr_fold: cint, 
                       target: ptr cdouble){.cdecl, 
    importc: "svm_cross_validation", dynlib: svmdll.}
proc save_model*(model_file_name: cstring, model: ptr Model): cint{.cdecl, 
    importc: "svm_save_model", dynlib: svmdll.}
proc load_model*(model_file_name: cstring): ptr Model{.cdecl, 
    importc: "svm_load_model", dynlib: svmdll.}
proc get_svm_type*(model: ptr Model): cint{.cdecl, importc: "svm_get_svm_type", 
    dynlib: svmdll.}
proc get_nr_class*(model: ptr Model): cint{.cdecl, importc: "svm_get_nr_class", 
    dynlib: svmdll.}
proc get_labels*(model: ptr Model, label: ptr cint){.cdecl, 
    importc: "svm_get_labels", dynlib: svmdll.}
proc get_svr_probability*(model: ptr Model): cdouble{.cdecl, 
    importc: "svm_get_svr_probability", dynlib: svmdll.}
proc predict_values*(model: ptr Model, x: ptr Node, dec_values: ptr cdouble): cdouble{.
    cdecl, importc: "svm_predict_values", dynlib: svmdll.}
proc predict*(model: ptr Model, x: ptr Node): cdouble{.cdecl, 
    importc: "svm_predict", dynlib: svmdll.}
proc predict_probability*(model: ptr Model, x: ptr Node, 
                          prob_estimates: ptr cdouble): cdouble{.cdecl, 
    importc: "svm_predict_probability", dynlib: svmdll.}
proc free_model_content*(model_ptr: ptr Model){.cdecl, 
    importc: "svm_free_model_content", dynlib: svmdll.}
proc free_and_destroy_model*(model_ptr_ptr: ptr ptr Model){.cdecl, 
    importc: "svm_free_and_destroy_model", dynlib: svmdll.}
proc destroy_param*(param: ptr Parameter){.cdecl, importc: "svm_destroy_param", 
    dynlib: svmdll.}
proc check_parameter*(prob: ptr Problem, param: ptr Parameter): cstring{.
    cdecl, importc: "svm_check_parameter", dynlib: svmdll.}
proc check_probability_model*(model: ptr Model): cint{.cdecl, 
    importc: "svm_check_probability_model", dynlib: svmdll.}

proc set_print_string_function*(print_func: proc (arg: cstring) {.cdecl.}){.
    cdecl, importc: "svm_set_print_string_function", dynlib: svmdll.}
