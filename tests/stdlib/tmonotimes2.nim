{.emit:"""

#include <iostream>
#include <ctime>
#include <ratio>
#include <chrono>
#include <cassert>

NIM_EXTERNC void fun1(){
  using namespace std::chrono;
  auto t1 = steady_clock::now();
  auto t2 = steady_clock::now();
  auto time_span = duration_cast<nanoseconds>(t2 - t1);
  std::cout << time_span.count() << std::endl;
  // assert(time_span.count() > 0.0);
}

NIM_EXTERNC void fun2(){
  using namespace std::chrono;
  auto t1 = high_resolution_clock::now();
  auto t2 = high_resolution_clock::now();
  auto time_span = duration_cast<nanoseconds>(t2 - t1);
  std::cout << time_span.count() << std::endl;
  // assert(time_span.count() > 0.0);
}


""".}

proc fun1(){.importc.}
proc fun2(){.importc.}

import std/times

template mainAux(algo) =
  let t = cpuTime()
  # for i in 0..<10000:
  for i in 0..<30:
    algo()
  let t2 = cpuTime()
  echo ("tot", t2 - t)

proc main =
  mainAux(fun1)
  mainAux(fun2)
main()