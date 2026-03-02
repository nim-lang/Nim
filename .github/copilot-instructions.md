## Code Standards

### General Guidelines

Don't modify testing files, instead, you should fix the compiler or library code that is causing the test to fail.


<!-- ### Required Before Each Commit

You need to run `./koch boot -d:release` to ensure the compiler can build -->

### Testing a single case

You can run a single test case by using the command `./koch temp c -r testname`, where `testname` is the name of the test case you want to run. Don't use testament.


### Repository Structure

- `compiler`: Contains the Nim compiler source code.
- `lib`: Contains standard libraries and modules.
- `tests`: Contains test cases for the compiler and standard libraries.
- `doc`: Contains documentation related to the Nim programming language.