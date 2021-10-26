# v1.xx.x - yyyy-mm-dd

## Changes affecting backward compatibility

## Standard library additions and changes

### New compile flag (`-d:nimNoGetRandom`) when building `std/sysrand` to remove dependency on linux `getrandom` syscall

This compile flag only affects linux builds and is necessary if either compiling on a linux kernel version < 3.17, or if code built will be executing on kernel < 3.17.

On linux kernels < 3.17 (such as kernel 3.10 in RHEL7 and CentOS7), the `getrandom` syscall was not yet introduced. Without this, the `std/sysrand` module will not build properly, and if code is built on a kernel >= 3.17 without the flag, any usage of the `std/sysrand` module will fail to execute on a kernel < 3.17 (since it attempts to perform a syscall to `getrandom`, which isn't present in the current kernel). A compile flag has been added to force the `std/sysrand` module to use /dev/urandom (available since linux kernel 1.3.30), rather than the `getrandom` syscall. This allows for use of a cryptographically secure PRNG, regardless of kernel support for the `getrandom` syscall.

When building for RHEL7/CentOS7 for example, the entire build process for nim from a source package would then be:
```sh
$ yum install devtoolset-8 # Install GCC version 8 vs the standard 4.8.5 on RHEL7/CentOS7. Alternatively use -d:nimEmulateOverflowChecks. See issue #13692 for details
$ scl enable devtoolset-8 bash # Run bash shell with default toolchain of gcc 8
$ sh build.sh  # per unix install instructions
$ bin/nim c koch  # per unix install instructions
$ ./koch boot -d:release  # per unix install instructions
$ ./koch tools -d:nimNoGetRandom  # pass the nimNoGetRandom flag to compile std/sysrand without support for getrandom syscall
```

This is necessary to pass when building nim on kernel versions < 3.17 in particular to avoid an error of "SYS_getrandom undeclared" during the build process for stdlib (sysrand in particular).

## Language changes


## Compiler changes


## Tool changes
