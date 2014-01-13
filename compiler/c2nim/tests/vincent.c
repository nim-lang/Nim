#include <stdlib.h>
#include <stdio.h>

int rand(void);

int main() {
    float f = .2,
          g = 2.,
          h = 1.0+rand(),
          i = 1.0e+3;
    int j, a;
    for(j = 0, a = 10; j < 0; j++, a++) ;
    do {
        printf("howdy");
    } while(--i, 0);
    if(1)
        printf("1"); // error from this comment
    else
        printf("2");
    return '\x00';
}
