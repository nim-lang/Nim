In this directory you will find the iOS platform cross-calculator sample.

The iOS version of the code builds a view controller in charge of displaying
the interface to the user. The Nim backend code is compiled into C code and
put into build/nimrod as a pre-build phase of the project.

When the calculate button is used the view controller calls the Nim code to
delegate the logic of the operation and puts the result in a label for display.
All interface error checks are implemented in the view controller.

This version of the iOS project is known to work with Xcode 4.2 and Xcode
4.4.1. The final binary can be deployed on iOS 3.x to 5.x supporting all iOS
platforms and versions available at the moment.
