#include <assert.h>
#include "producer.h"

int main(void) {
  NimMain();
  assert(producer_answer_0(41) == 42);
  assert(producer_answer_1(20, 22) == 42);
  assert(producer_identity_2(NULL) == NULL);
  producer_notify_3(42);
  return 0;
}
