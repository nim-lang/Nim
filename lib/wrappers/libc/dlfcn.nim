when defined(linux) and defined(amd64):
  include dlfcn/linux_amd64_types
  include dlfcn/linux_amd64_consts
  include dlfcn/linux_amd64_procs
else:
  include dlfcn/other_types
  include dlfcn/other_consts
  include dlfcn/other_procs
