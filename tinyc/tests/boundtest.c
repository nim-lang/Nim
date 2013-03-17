#include <stdlib.h>
#include <stdio.h>

#define NB_ITS 1000000
//#define NB_ITS 1
#define TAB_SIZE 100

int tab[TAB_SIZE];
int ret_sum;
char tab3[256];

int test1(void)
{
    int i, sum = 0;
    for(i=0;i<TAB_SIZE;i++) {
        sum += tab[i];
    }
    return sum;
}

/* error */
int test2(void)
{
    int i, sum = 0;
    for(i=0;i<TAB_SIZE + 1;i++) {
        sum += tab[i];
    }
    return sum;
}

/* actually, profiling test */
int test3(void)
{
    int sum;
    int i, it;

    sum = 0;
    for(it=0;it<NB_ITS;it++) {
        for(i=0;i<TAB_SIZE;i++) {
            sum += tab[i];
        }
    }
    return sum;
}

/* ok */
int test4(void)
{
    int i, sum = 0;
    int *tab4;

    tab4 = malloc(20 * sizeof(int));
    for(i=0;i<20;i++) {
        sum += tab4[i];
    }
    free(tab4);

    return sum;
}

/* error */
int test5(void)
{
    int i, sum = 0;
    int *tab4;

    tab4 = malloc(20 * sizeof(int));
    for(i=0;i<21;i++) {
        sum += tab4[i];
    }
    free(tab4);

    return sum;
}

/* error */
/* XXX: currently: bug */
int test6(void)
{
    int i, sum = 0;
    int *tab4;
    
    tab4 = malloc(20 * sizeof(int));
    free(tab4);
    for(i=0;i<21;i++) {
        sum += tab4[i];
    }

    return sum;
}

/* error */
int test7(void)
{
    int i, sum = 0;
    int *p;

    for(i=0;i<TAB_SIZE + 1;i++) {
        p = &tab[i];
        if (i == TAB_SIZE)
            printf("i=%d %x\n", i, p);
        sum += *p;
    }
    return sum;
}

/* ok */
int test8(void)
{
    int i, sum = 0;
    int tab[10];

    for(i=0;i<10;i++) {
        sum += tab[i];
    }
    return sum;
}

/* error */
int test9(void)
{
    int i, sum = 0;
    char tab[10];

    for(i=0;i<11;i++) {
        sum += tab[i];
    }
    return sum;
}

/* ok */
int test10(void)
{
    char tab[10];
    char tab1[10];

    memset(tab, 0, 10);
    memcpy(tab, tab1, 10);
    memmove(tab, tab1, 10);
    return 0;
}

/* error */
int test11(void)
{
    char tab[10];

    memset(tab, 0, 11);
    return 0;
}

/* error */
int test12(void)
{
    void *ptr;
    ptr = malloc(10);
    free(ptr);
    free(ptr);
    return 0;
}

/* error */
int test13(void)
{
    char pad1 = 0;
    char tab[10];
    char pad2 = 0;
    memset(tab, 'a', sizeof(tab));
    return strlen(tab);
}

int (*table_test[])(void) = {
    test1,
    test1,
    test2,
    test3,
    test4,
    test5,
    test6,
    test7,
    test8,
    test9,
    test10,
    test11,
    test12,
    test13,
};

int main(int argc, char **argv)
{
    int index;
    int (*ftest)(void);

    if (argc < 2) {
        printf("usage: boundtest n\n"
               "test TCC bound checking system\n"
               );
        exit(1);
    }

    index = 0;
    if (argc >= 2)
        index = atoi(argv[1]);
    /* well, we also use bounds on this ! */
    ftest = table_test[index];
    ftest();

    return 0;
}

/*
 * without bound   0.77 s
 * with bounds    4.73
 */  
