In this directory you will find the Android platform cross-calculator sample.

Due to the nature of Android being java and Nim generating C code, the build
process is slightly more complex because jni code has to be written to bridge
both languages. In a distant future it may be possible for Nim to generate
the whole jni bridge, but for the moment this is manual work.

For the jni bridge to work first the java code is compiled with the Nim code
just declared as a native method which will be resolved at runtime. The scripts
nimbuild.sh and jnibuild.sh are in charge of building the Nim code and
generating the jni bridge from the java code respectively. Finally, the
ndk-build command from the android ndk tools has to be run to build the binary
library which will be installed along the final apk.

All these steps are wrapped in the ant build script through the customization
of the -post-compile rule. If you have the android ndk tools installed and you
modify scripts/nimbuild.sh to point to the directory where you have Nim
installed on your system, you can simply run "ant debug" to build everything.

Once the apk is built you can install it on your device or emulator with the
command "adb install bin/CrossCalculator-debug.apk".

You can use this example as a starting point for your project or look at the
history of the github project at https://github.com/gradha/nimrod-on-android.
That repository documents the individual integration steps you would take for
any Android project (note it uses Eclipse rather than ant to build and
therefore the build process requires more manual fiddling).

This example runs against the Android level 3 API, meaning devices from
Android 1.5 and above should be able to run the generated binary.
