/* Atomic operations for Nimrod */

#if defined(_MSCVER)
__declspec(naked) int __fastcall Xadd (volatile int* pNum, int val)
{
    __asm
    {
        lock xadd dword ptr [ECX], EDX
        mov EAX, EDX
        ret
    }
}



#endif


#define ATOMIC_ASM(type,op)     \
    __asm __volatile ("lock; " op : "=m" (*(type *)p) : "ir" (v), "0" (*(type *)p))

#define ATOMIC_ASM_NOLOCK(type,op)     \
    __asm __volatile (op : "=m" (*(type *)p) : "ir" (v), "0" (*(type *)p))

static __inline void
atomic_add_int(void *p, u_int v)
{
        ATOMIC_ASM(int, "addl %1,%0");
}

static __inline void
atomic_add_int_nolock(void *p, u_int v)
{
        ATOMIC_ASM_NOLOCK(int, "addl %1,%0");
}



/*
Atomic.h

Joshua Scholar
May 26, 2003

This header contains:

a multiprocessor nonblocking FIFO,  

a multiprocessor nonblocking LIFO

multiprocessor nonblocking reference counting (including volatile pointers 
that can be safely shared between processors)

nonblocking memory allocation routines

template types that encapsulate variables meant to be shared between 
processors - all changes to these variables are atomic and globally visible

All kinds of atomic operations that are useful in a multiprocessor context.

The philosophy behind this code is that I created templates that encapsulate
atomic access so that while the templates themselves may not be the easiest
code to read, code that uses these templates can be simple, abstract and
reliable.

I also created regular C style functions, overloaded by type for some of
the more basic operations.  If you have regular variables or memory 
locations that you want to use in a globally visible way you have two 
choices.

If the operation you want is one of the basic building blocks you can
call one of the overloaded functions like InterlockedSetIfEqual().

Otherwise it's perfectly safe to cast a pointer to your data to be a pointer
to one of the atomic types so that you can use their methods.  For instance:
if (((AtomicInt *)foo)->CompareSomeBitsAndExchangeSomeOtherBits(exchange, 
        bitsToExchange,
        comperand, 
        bitsToCompare))
    ...
or even

//atomically allocate n bytes out of the pool
 data = ((*(AtomicPtr<char> *)curPool)+= n) - n;



State of code:

Unlike other libraries of similar routines that I wrote in the past, this
has not been thoroughly tested. In fact I don't remember how much of it has
been tested at this point.

It would take an 8 way machine for me to really pound on the routines.



Overview

Some basic types are:
typedef Atomic<int> AtomicInt;
typedef Atomic<unsigned int> AtomicUInt;
typedef Atomic<__int64> AtomicInt64;
typedef Atomic<unsigned __int64> AtomicUInt64;

Fancier types include
template <typename T> struct AtomicPtr;
This is a pointer that has the same semantics as the above integer types

template <typename T>struct AtomicPtrWithCount;

AtomicPtrWithCount<T> is a very important type.  It has 32 bits of pointer
and 32 bits of counter.  There are a number of algorithms that are possible
when a pointer and a counter can be changed atomically together including a
lock free pushdown stack and reference counted garbage collection where
multiple processors can share pointers as well as sharing the data that's
pointed at.

template <typename T> struct AtomicPtrWithMark;

This is similar to AtomicPtrWithCount<T> but the extra 32 bits are accessed
as individual bits instead of being accessed as a counter.  It's not as
important.  I was playing with algorithms before I realized that the
important ones I was afraid of using had been published independently of my
former employer.



The atomic number types act as integer variables, but all changes to these
variable happen through interlocked atomic instructions.
All changes are therefor "globally visible" in Intel's parlance.

Note that incrementing (or decrementing or adding to) one of these uses
InterlockedExchangeAdd, which for 64 bit numbers ends up relying on "lock
CMPXCHG8B"

There's an Exchange method.

There are also special methods that use compare exchange in some forms that
I've found useful:

T CompareExchange(T exchange, T comperand)
bool SetIfEqual(T exchange, T comperand)

and fancier ones I found some uses for

 inline bool SetIfSomeBitsAreEqual(T exchange, T comperand, T bitsToCompare)
 inline bool SetSomeBitsIfThoseBitsAreEqual(T exchange, 
                                             T comperand, 
                                             T bitsToCompare)
 inline bool SetSomeBitsIfSomeOtherBitsAreEqual(T exchange,
              T bitsToExchange,
              T comperand,
              T bitsToCompare
              )

 inline T CompareSomeBitsAndExchange(T exchange, 
                                     T comperand, 
                                     T bitsToCompare)
 inline T CompareSomeBitsAndExchangeThoseBits(T exchange, 
                                             T comperand, 
                                             T bitsToCompare)
 inline T CompareSomeBitsAndExchangeSomeOtherBits(T exchange,
              T bitsToExchange,
              T comperand,
              T bitsToCompare
              )

There are also atomic bit test, bit test and set etc. methods:

 inline bool BTS(int bit)
 inline bool BTC(int bit)
 inline bool BTR(int bit)
 inline bool BT(int bit)

ALGORITHMS and their classes:

The important ones are:

struct Counted
Use this as the base type for any object you want to be reference counted

template <typename T> class CountedPtr;
Safely acts as pointer to a reference counted type.  This pointer can not be
shared between threads safely.

template <typename T> class AtomicCountedPtr;
Like CountedPtr<T> but this pointer CAN be shared between threads/processors
safely.

template <typename T> class MPQueue;
Multiprocessor queue.  This is the nonblocking shared FIFO.

Note, for the sake of convenience there is a Fifo that has the same
semantics but can only be used single threaded:
template <typename T> class Queue ;

class MPCountStack;
This is the multiprocessor nonblocking LIFO stack.  Note that what gets
pushed on the stack are pointers to MPStackElement. Your data must be
objects derived from MPStackElements.  Note that it is not legal to push a
NULL onto the stack - NULL is used to signal an empty stack.

Note that for the sake of convienience there is, once again, a single
threaded version of the stack:
class SimpleStack.

There are also classes for allocators that use the MPCountStack as a
freelist.
template <typename T, typename BLOCK_ALLOCATOR>
struct MPCountFreeListAllocator;

This template is recursive in the sense that each allocator gets new blocks
from a shared allocatorn passed in the constructor (of type
BLOCK_ALLOCATOR).  You can build a tree of allocators this way.  The root of
the tree should be of type SimpleAllocator<T> which just calls new and
delete.

Once again, for the sake of simplicity, there is a single threaded version
of the block allocator called
template <typename T, typename BLOCK_ALLOCATOR> struct SimpleBlockAllocator

*/
#ifndef ATOMIC_H
#define ATOMIC_H
#include <windows.h>
#include <assert.h>
#include <new>
using namespace std;
/* 
    windows defines the following interlocked routines
    we need to define the equivalent for volatiles (which 
    they should have been in the first place, and the following 
    types voltatile long, volatile int, volatile unsigned long, 
    volatile unsigned int,  volatile T*, volatile __int64, 
    volatile unsigned __int64.

    Note: I use the platform SDK which has different header files 
    for interlocked instructions than the Windows includes in Visual 
    C

    If you have the platform SDK and the code doesn't compile then
    you need to make sure that 
    "C:\Program Files\Microsoft Platform SDK\include"
    is the first directory listed under menus "Tools" -> menu item
    "Options" -> tab "Directories" (of course if you installed the 
    platform SDK in a different directory than 
    "C:\Program Files\Microsoft Platform SDK" then you should use 
    YOUR path.

    If you don't have the plaform SDK then InterlockedCompareExchange 
    is defined for void * instead of being defined for longs...  and 
    there is no InterlockedCompareExchangePointer

    The whole point of Microsoft having different headers was an update
    to support 64 bit platforms which doesn't matter here at all (some 
    of the code here relies on CMPXCHG8B swaping out both a pointer AND
    a counter - a trick that won't work on the current 64 bit platforms).

    In any case, if you don't have the platform SDK then just 
    appropriate casts to make the code compile.  Keep in mind that 
    casting from 64 bit types to 32 bit types is wrong - where there's 
    a 64 bit type I meant it to call one of my assembly language
    routines that uses CMPXCHG8B.

    LONG
    InterlockedIncrement(
    LPLONG lpAddend
    );

    LONG
    InterlockedDecrement(
    LPLONG lpAddend
    );

    LONG
    InterlockedExchange(
    LPLONG Target,
    LONG Value
    );

    LONG
    InterlockedExchangeAdd(
    LPLONG Addend,
    LONG Value
    );

    LONG
    InterlockedCompareExchange (
    PLONG Destination,
    LONG ExChange,
    LONG Comperand
    );

    PVOID
    InterlockedExchangePointer (
    PVOID *Target,
    PVOID Value
    );

    PVOID
    InterlockedCompareExchangePointer (
    PVOID *Destination,
    PVOID ExChange,
    PVOID Comperand
    );
*/

//we'll need a special cases for volatile __int64 and 
//volatile unsigned __int64

template <typename T>
inline T InterlockedIncrement(volatile T * ptr)
{
    return (T)InterlockedIncrement((LPLONG)ptr);
}

template <typename T>
inline T InterlockedDecrement(volatile T * ptr)
{
    return (T)InterlockedDecrement((LPLONG)ptr);
}

template <typename T>
inline T InterlockedExchange(volatile T * target,T value)
{
    return (T)InterlockedExchange((LPLONG)target,(LONG)value);
}

template <typename T>
inline T InterlockedExchangeAdd(volatile T *addend,T value)
{
    return (T)InterlockedExchangeAdd((LPLONG)addend,(LONG)value);
}

template <typename T>
T InterlockedCompareExchange (volatile T * dest,T exchange,T comperand)
{
    return (T)InterlockedCompareExchange ((LPLONG)dest,
                                        (LONG)exchange,
                                        (LONG)comperand);
}
//most common use of InterlockedCompareExchange
template <typename T>
bool InterlockedSetIfEqual (volatile T * dest,T exchange,T comperand)
{
    return comperand==InterlockedCompareExchange(dest,exchange,comperand);
}

//disable the no return value warning, because the assembly language
//routines load the appropriate registers directly
#pragma warning(disable:4035)

inline unsigned __int64 
InterlockedCompareExchange(volatile unsigned __int64 *dest
                           ,unsigned __int64 exchange
                           ,unsigned __int64 comperand) 
{
    //value returned in eax::edx
    __asm {
        lea esi,comperand;
        lea edi,exchange;
        
        mov eax,[esi];
        mov edx,4[esi];
        mov ebx,[edi];
        mov ecx,4[edi];
        mov esi,dest;
        //lock CMPXCHG8B [esi] is equivalent to the following except
        //that it's atomic:
        //ZeroFlag = (edx:eax == *esi);
        //if (ZeroFlag) *esi = ecx:ebx;
        //else edx:eax = *esi;
        lock CMPXCHG8B [esi];			
    }
}

//most common use of InterlockedCompareExchange
//It's more efficient to use the z flag than to do another compare
inline bool 
InterlockedSetIfEqual(volatile unsigned __int64 *dest
                      ,unsigned __int64 exchange
                      ,unsigned __int64 comperand) 
{
    //value returned in eax
    __asm {
        lea esi,comperand;
        lea edi,exchange;
        
        mov eax,[esi];
        mov edx,4[esi];
        mov ebx,[edi];
        mov ecx,4[edi];
        mov esi,dest;
        //lock CMPXCHG8B [esi] is equivalent to the following except
        //that it's atomic:
        //ZeroFlag = (edx:eax == *esi);
        //if (ZeroFlag) *esi = ecx:ebx;
        //else edx:eax = *esi;
        lock CMPXCHG8B [esi];			
        mov eax,0;
        setz al;
    }
}
#pragma warning(default:4035)

inline unsigned __int64 InterlockedIncrement(volatile unsigned __int64 * ptr)
{
    unsigned __int64 comperand;
    unsigned __int64 exchange;
    do {
        comperand = *ptr;
        exchange = comperand+1;
    }while(!InterlockedSetIfEqual(ptr,exchange,comperand));
    return exchange;
}

inline unsigned __int64 InterlockedDecrement(volatile unsigned __int64 * ptr)
{
    unsigned __int64 comperand;
    unsigned __int64 exchange;
    do {
        comperand = *ptr;
        exchange = comperand-1;
    }while(!InterlockedSetIfEqual(ptr,exchange,comperand));
    return exchange;
}

inline unsigned __int64 InterlockedExchange(volatile unsigned __int64 * target,
                                            unsigned __int64 value)
{
    unsigned __int64 comperand;
    do {
        comperand = *target;
    }while(!InterlockedSetIfEqual(target,value,comperand));
    return comperand;
}

inline unsigned __int64 InterlockedExchangeAdd(volatile unsigned __int64 *addend,
                                               unsigned __int64 value)
{
    unsigned __int64 comperand;
    do {
        comperand = *addend;
    }while(!InterlockedSetIfEqual(addend,comperand+value,comperand));
    return comperand;
}

#pragma warning(disable:4035)
inline __int64 
InterlockedCompareExchange(volatile __int64 *dest
                           ,__int64 exchange
                           ,__int64 comperand) 
{
    //value returned in eax::edx
    __asm {
        lea esi,comperand;
        lea edi,exchange;
        
        mov eax,[esi];
        mov edx,4[esi];
        mov ebx,[edi];
        mov ecx,4[edi];
        mov esi,dest;
        //lock CMPXCHG8B [esi] is equivalent to the following except
        //that it's atomic:
        //ZeroFlag = (edx:eax == *esi);
        //if (ZeroFlag) *esi = ecx:ebx;
        //else edx:eax = *esi;
        lock CMPXCHG8B [esi];			
    }
}

//most common use of InterlockedCompareExchange
//It's more efficient to use the z flag than to do another compare
inline bool 
InterlockedSetIfEqual(volatile __int64 *dest
                      ,__int64 exchange
                      ,__int64 comperand) 
{
    //value returned in eax
    __asm {
        lea esi,comperand;
        lea edi,exchange;
        
        mov eax,[esi];
        mov edx,4[esi];
        mov ebx,[edi];
        mov ecx,4[edi];
        mov esi,dest;
        //lock CMPXCHG8B [esi] is equivalent to the following except
        //that it's atomic:
        //ZeroFlag = (edx:eax == *esi);
        //if (ZeroFlag) *esi = ecx:ebx;
        //else edx:eax = *esi;
        lock CMPXCHG8B [esi];			
        mov eax,0;
        setz al;
    }
}
#pragma warning(default:4035)

inline __int64 InterlockedIncrement(volatile __int64 * dest)
{
    __int64 comperand;
    __int64 exchange;
    do {
        comperand = *dest;
        exchange = comperand+1;
    }while(!InterlockedSetIfEqual(dest,exchange,comperand));
    return exchange;
}

inline __int64 InterlockedDecrement(volatile __int64 * dest)
{
    __int64 comperand;
    __int64 exchange;
    do {
        comperand = *dest;
        exchange = comperand-1;
    }while(!InterlockedSetIfEqual(dest,exchange,comperand));
    return exchange;
}

inline __int64 InterlockedExchange(volatile __int64 * target,__int64 value)
{
    __int64 comperand;
    do {
        comperand = *target;
    }while(!InterlockedSetIfEqual(target,value,comperand));
    return comperand;
}

inline __int64 InterlockedExchangeAdd(volatile __int64 *addend,
                                      __int64 value)
{
    __int64 comperand;
    do {
        comperand = *addend;
    }while(!InterlockedSetIfEqual(addend,comperand+value,comperand));
    return comperand;
}

#pragma warning(disable:4035)
//I've just thought of some algorithms that use BTS and all so I'm including them
inline bool InterlockedBTS(volatile int *dest, int bit)
{
    //value returned in eax
    __asm{
        mov eax,bit;
        mov ebx,dest;
        lock bts [ebx],eax;
        mov eax,0;
        setc al;
    }
}
inline bool InterlockedBTC(volatile int *dest, int bit)
{
    //value returned in eax
    __asm{
        mov eax,bit;
        mov ebx,dest;
        lock btc [ebx],eax;
        mov eax,0;
        setc al;
    }
}
inline bool InterlockedBTR(volatile int *dest, int bit)
{
    //value returned in eax
    __asm{
        mov eax,bit;
        mov ebx,dest;
        lock btr [ebx],eax;
        mov eax,0;
        setc al;
    }
}
//you can lock BT but since it doesn't change memory there isn't really any point
inline bool BT(volatile int *dest, int bit)
{
    //value returned in eax
    __asm{
        mov eax,bit;
        mov ebx,dest;
        bt [ebx],eax;
        mov eax,0;
        setc al;
    }
}
#pragma warning(default:4035)

inline bool InterlockedBTS(volatile unsigned *dest, int bit)
{
    return InterlockedBTS((volatile int *)dest,bit);
}
inline bool InterlockedBTC(volatile unsigned *dest, int bit)
{
    return InterlockedBTC((volatile int *)dest,bit);
}
inline bool InterlockedBTR(volatile unsigned *dest, int bit)
{
    return InterlockedBTR((volatile int *)dest,bit);
}
inline bool BT(volatile unsigned *dest, int bit)
{
    return BT((volatile int *)dest,bit);
}

inline bool InterlockedBTS(volatile unsigned long *dest, int bit)
{
    return InterlockedBTS((volatile int *)dest,bit);
}
inline bool InterlockedBTC(volatile unsigned long *dest, int bit)
{
    return InterlockedBTC((volatile int *)dest,bit);
}
inline bool InterlockedBTR(volatile unsigned long *dest, int bit)
{
    return InterlockedBTR((volatile int *)dest,bit);
}
inline bool BT(volatile unsigned long *dest, int bit)
{
    return BT((volatile int *)dest,bit);
}

inline bool InterlockedBTS(volatile long *dest, int bit)
{
    return InterlockedBTS((volatile int *)dest,bit);
}
inline bool InterlockedBTC(volatile long *dest, int bit)
{
    return InterlockedBTC((volatile int *)dest,bit);
}
inline bool InterlockedBTR(volatile long *dest, int bit)
{
    return InterlockedBTR((volatile int *)dest,bit);
}
inline bool BT(volatile long *dest, int bit)
{
    return BT((volatile int *)dest,bit);
}

inline bool InterlockedBTS(volatile __int64 *dest, int bit)
{
    if (bit<32) return InterlockedBTS((volatile int *)&dest,bit);
    return InterlockedBTS(1+(volatile int *)&dest,bit-32);
}
inline bool InterlockedBTC(volatile __int64 *dest, int bit)
{
    if (bit<32) return InterlockedBTC((volatile int *)&dest,bit);
    return InterlockedBTC(1+(volatile int *)&dest,bit-32);
}
inline bool InterlockedBTR(volatile __int64 *dest, int bit)
{
    if (bit<32) return InterlockedBTR((volatile int *)&dest,bit);
    return InterlockedBTR(1+(volatile int *)&dest,bit-32);
}
inline bool BT(volatile __int64 *dest, int bit)
{
    if (bit<32) return BT((volatile int *)&dest,bit);
    return BT(1+(volatile int *)&dest,bit-32);
}
inline bool InterlockedBTS(volatile unsigned __int64 *dest, int bit)
{
    if (bit<32) return InterlockedBTS((volatile int *)&dest,bit);
    return InterlockedBTS(1+(volatile int *)&dest,bit-32);
}
inline bool InterlockedBTC(volatile unsigned __int64 *dest, int bit)
{
    if (bit<32) return InterlockedBTC((volatile int *)&dest,bit);
    return InterlockedBTC(1+(volatile int *)&dest,bit-32);
}
inline bool InterlockedBTR(volatile unsigned __int64 *dest, int bit)
{
    if (bit<32) return InterlockedBTR((volatile int *)&dest,bit);
    return InterlockedBTR(1+(volatile int *)&dest,bit-32);
}
inline bool BT(volatile unsigned __int64 *dest, int bit)
{
    if (bit<32) return BT((volatile int *)&dest,bit);
    return BT(1+(volatile int *)&dest,bit-32);
}

//T can be int, unsigned int, long, unsigned long
//__int64 or unsigned __int64
template <typename T>
struct Atomic 
{
    volatile T value;
    
    inline Atomic(){}
    
    explicit inline Atomic(T n)
    { //so that it's globally visible (to use intel's terminology)
        InterlockedExchange(&value,n);
    }
    
    //if you need an atomic load then use (*this += 0)
    //but I haven't found any algorithms that
    //require an atomic load
    inline operator T() const
    {
        return value;
    }
    
    inline T CompareExchange(T exchange, T comperand)
    {
        return InterlockedCompareExchange(&value,exchange,comperand);
    }
    
    //useful - simulates having a compareexchange that ignores some bits in
    //the compare
    inline T CompareSomeBitsAndExchange(T exchange, T comperand, T bitsToCompare)
    {
        T returned;
        T bitsToIgnore = ~bitsToCompare;
        for (;;){
            returned = InterlockedCompareExchange(&value,exchange,comperand);
            if (returned == comperand) return returned;
            if (0 != ((returned ^ comperand) & bitsToCompare)) break;
            comparand = (comparand&bitsToCompare) | (bitsToIgnore&returned);
        }
        return returned;
    }
    
    //useful - simulates having a compareexchange that ignores some bits in
    //the compare and in the set
    inline T CompareSomeBitsAndExchangeThoseBits(T exchange, T comperand, T bitsToCompare)
    {
        T returned = comperand;
        T bitsToIgnore = ~bitsToCompare;
        for (;;){
            exchange = (exchange&bitsToCompare) | (bitsToIgnore&returned);
            returned = InterlockedCompareExchange(&value,exchange,comperand);
            if (returned == comperand) return returned;
            if (0 != ((returned ^ comperand) & bitsToCompare)) break;
            comparand = (comparand&bitsToCompare) | (bitsToIgnore&returned);
        }
        return returned;
    }
    
    //useful - simulates having a compareexchange that ignores some bits in
    //the compare and others in the set
    inline T CompareSomeBitsAndExchangeSomeOtherBits(T exchange, 
        T bitsToExchange,
        T comperand, 
        T bitsToCompare
        )
    {
        T returned = value;
        T bitsToIgnore = ~bitsToCompare;
        T bitsToLeave = ~bitsToExchange;
        for (;;){
            exchange = (exchange&bitsToExchange) | (bitsToLeave&returned);
            returned = InterlockedCompareExchange(&value,exchange,comperand);
            if (returned == comperand) return returned;
            if (0 != ((returned ^ comperand) & bitsToCompare)) break;
            comparand = (comparand&bitsToCompare) | (bitsToIgnore&returned);
        }
        return returned;
    }
    
    inline T Exchange(T exchange) 
    {
        return InterlockedExchange(&value,exchange);
    }
    
    inline bool SetIfEqual(T exchange, T comperand)
    {
        return InterlockedSetIfEqual(&value,exchange,comperand);
    }
    
    //useful - simulates having a compareexchange that ignores some bits in
    //the compare
    inline bool SetIfSomeBitsAreEqual(T exchange, T comperand, T bitsToCompare)
    {
        T returned;
        T bitsToIgnore = ~bitsToCompare;
        for (;;){
            returned = InterlockedCompareExchange(&value,exchange,comperand);
            if (returned == comperand) return true;
            if (0 != ((returned ^ comperand) & bitsToCompare)) break;
            comparand = (comparand&bitsToCompare) | (bitsToIgnore&returned);
        }
        return false;
    }
    
    //useful - simulates having a compareexchange that ignores some bits in
    //the compare and in the set
    inline bool SetSomeBitsIfThoseBitsAreEqual(T exchange, T comperand, T bitsToCompare)
    {
        T returned = comperand;
        T bitsToIgnore = ~bitsToCompare;
        for (;;){
            exchange = (exchange&bitsToCompare) | (bitsToIgnore&returned);
            returned = InterlockedCompareExchange(&value,exchange,comperand);
            if (returned == comperand) return true;
            if (0 != ((returned ^ comperand) & bitsToCompare)) break;
            comperand = (comperand&bitsToCompare) | (bitsToIgnore&returned);
        }
        return false;
    }
    //useful - simulates having a compareexchange that ignores some bits in
    //the compare and others in the set
    inline bool SetSomeBitsIfSomeOtherBitsAreEqual(T exchange, 
        T bitsToExchange,
        T comperand, 
        T bitsToCompare
        )
    {
        T returned = value;
        T bitsToIgnore = ~bitsToCompare;
        T bitsToLeave = ~bitsToExchange;
        for (;;){
            exchange = (exchange&bitsToExchange) | (bitsToLeave&returned);
            returned = InterlockedCompareExchange(&value,exchange,comperand);
            if (returned == comperand) return true;
            if (0 != ((returned ^ comperand) & bitsToCompare)) break;
            comperand = (comperand&bitsToCompare) | (bitsToIgnore&returned);
        }
        return false;
    }
    
    inline T operator =(T exchange)
    {
        Exchange(exchange);
        return exchange;
    }
    
    inline T operator +=(T n)
    {
        return n + InterlockedExchangeAdd(&value, n);
    }
    
    inline T operator -=(T n)
    {
        return InterlockedExchangeAdd(&value, -n) - n;
    }
    inline T operator ++()
    {
        return (*this += 1);
    }
    
    inline T operator --() 
    {
        return (*this -= 1);
    }
    
    inline T operator ++(int)
    {
        return InterlockedExchangeAdd(&value, (T)1);
    }
    
    inline T operator --(int)
    {
        return InterlockedExchangeAdd(&value, (T)-1);
    }
    
    inline T operator &=(T n)
    {
        T comperand;
        T exchange;
        do {
            comperand = value; 
            exchange = comperand & n;
        }while(!SetIfEqual(exchange, comperand));
        return exchange;
    }
    
    inline T operator |= (T n) 
    {
        T comperand;
        T exchange;
        do {
            comperand = value; 
            exchange = comperand | n;
        }while(!SetIfEqual(exchange, comperand));
        return exchange;
    }
    
    //yes this isn't standard, but it's useful
    inline T Mask(T bitsToKeep, T bitsToSet) 
    {
        T comperand;
        T exchange;
        do {
            comperand = value ; 
            exchange = ((comperand & bitsToKeep) | bitsToSet);
        }while(!SetIfEqual(exchange, comperand));
        return exchange;
    }
    
    inline T operator ^= (T n)
    {
        T comperand;
        T exchange;
        do {
            comperand = value;  
            exchange = comperand ^ n;
        }while(!SetIfEqual(exchange, comperand));
        return exchange;
    }
    inline T operator *= (T n) 
    {
        T comperand;
        T exchange;
        do {
            comperand = value;  
            exchange = comperand * n;
        }while(!SetIfEqual(exchange, comperand));
        return exchange;
    }
    
    inline T operator /= (T n) 
    {
        T comperand;
        T exchange;
        do {
            comperand = value;
            exchange = comperand / n;
        }while(!SetIfEqual(exchange, comperand));
        return exchange;
    }
    
    inline T operator >>= (unsigned n) 
    {
        T comperand;
        T exchange;
        do {
            comperand = value;
            exchange = comperand >> n;
        }while(!SetIfEqual(exchange, comperand));
        return exchange;
    }
    
    inline T operator <<= (unsigned n)
    {
        T comperand;
        T exchange;
        do {
            comperand = value;
            exchange = comperand << n;
        }while(!SetIfEqual(exchange, comperand));
        return exchange;
    }
    inline bool BTS(int bit)
    {
        return InterlockedBTS(&value,bit);
    }
    inline bool BTC(int bit)
    {
        return InterlockedBTC(&value,bit);
    }
    inline bool BTR(int bit)
    {
        return InterlockedBTR(&value,bit);
    }
    inline bool BT(int bit)
    {
        return BT(&value,bit);
    }
}; 

template <typename T>
T * InterlockedCompareExchangePointer (
                                       T *volatile *dest,
                                       T * exchange,
                                       T * comperand
                                       )
{
    return (T*)InterlockedCompareExchangePointer((PVOID *)dest,(PVOID)exchange,(PVOID)comperand);
}

template <typename T>
struct AtomicPtr 
{
    T * volatile value;
    
    inline AtomicPtr(){}
    
    explicit inline AtomicPtr(T *n)
    { //so that it's globally visible (to use intel's terminology)
        InterlockedExchange(&value,n);
    }
    explicit inline AtomicPtr(const T *n)
    { //so that it's globally visible (to use intel's terminology)
        InterlockedExchange(&value,(T *)n);
    }
    
    inline operator T *() const
    {
        return value;
    }
    
    inline operator const T *() const
    {
        return value;
    }
    
    inline T *CompareExchange(T *exchange, T *comperand)
    {
        return InterlockedCompareExchangePointer(&value,exchange,comperand);
    }
    
    //useful - simulates having a compareexchange that ignores some bits in
    //the compare
    inline T * CompareSomeBitsAndExchange(T * exchange, T * comperand, int bitsToCompare)
    {
        T  *returned;
        int bitsToIgnore = ~bitsToCompare;
        for (;;){
            returned = InterlockedCompareExchangePointer(&value,exchange,comperand);
            if (returned == comperand) return returned;
            if (0 != ((returned ^ comperand) & bitsToCompare)) break;
            comparand = (comparand&bitsToCompare) | (bitsToIgnore&returned);
        }
        return returned;
    }
    
    //useful - simulates having a compareexchange that ignores some bits in
    //the compare and in the set
    inline T * CompareSomeBitsAndExchangeThoseBits(T * exchange, T * comperand, int bitsToCompare)
    {
        T *returned = comperand;
        int bitsToIgnore = ~bitsToCompare;
        for (;;){
            exchange = (T*)((int)exchange&bitsToCompare) | (bitsToIgnore&(int)returned);
            returned = InterlockedCompareExchangePointer(&value,exchange,comperand);
            if (returned == comperand) return returned;
            if (0 != ((returned ^ comperand) & bitsToCompare)) break;
            comparand = (T*)((int)comparand&bitsToCompare) | (bitsToIgnore&(int)returned);
        }
        return returned;
    }
    //useful - simulates having a compareexchange that ignores some bits in
    //the compare and others in the set
    inline T* CompareSomeBitsAndExchangeSomeOtherBits(T *exchange, 
        int bitsToExchange,
        T * comperand, 
        int bitsToCompare
        )
    {
        T * returned = value;
        int bitsToIgnore = ~bitsToCompare;
        int bitsToLeave = ~bitsToExchange;
        for (;;){
            exchange = (T*)((int)exchange&bitsToExchange) | (bitsToLeave&(int)returned);
            returned = InterlockedCompareExchange(&value,exchange,comperand);
            if (returned == comperand) return returned;
            if (0 != ((returned ^ comperand) & bitsToCompare)) break;
            comparand = (T*)((int)comparand&bitsToCompare) | (bitsToIgnore&(int)returned);
        }
        return returned;
    }
    
    inline T * operator ->() const
    {
        assert (value != NULL);
        return value;
    }
    
    inline T *Exchange(T *exchange) 
    {
        return InterlockedExchange(&value,exchange);
    }
    
    inline bool SetIfEqual(T *exchange, T *comperand)
    {
        return comperand==InterlockedCompareExchangePointer(&value,exchange,comperand);
    }
    
    //useful - simulates having a compareexchange that ignores some bits in
    //the compare
    inline bool SetIfSomeBitsAreEqual(T * exchange, T * comperand, int bitsToCompare)
    {
        T  *returned;
        int bitsToIgnore = ~bitsToCompare;
        for (;;){
            returned = InterlockedCompareExchangePointer(&value,exchange,comperand);
            if (returned == comperand) return true;
            if (0 != ((returned ^ comperand) & bitsToCompare)) break;
            comparand = (comparand&bitsToCompare) | (bitsToIgnore&returned);
        }
        return false;
    }
    
    //useful - simulates having a compareexchange that ignores some bits in
    //the compare and in the set
    inline bool SetSomeBitsIfThoseBitsAreEqual(T * exchange, T * comperand, int bitsToCompare)
    {
        T *returned = comperand;
        int bitsToIgnore = ~bitsToCompare;
        for (;;){
            exchange = (T*)((int)exchange&bitsToCompare) | (bitsToIgnore&(int)returned);
            returned = InterlockedCompareExchangePointer(&value,exchange,comperand);
            if (returned == comperand) return true;
            if (0 != ((returned ^ comperand) & bitsToCompare)) break;
            comparand = (T*)((int)comparand&bitsToCompare) | (bitsToIgnore&(int)returned);
        }
        return false;
    }
    
    //useful - simulates having a compareexchange that ignores some bits in
    //the compare and others in the set
    inline bool SetSomeBitsIfSomeOtherBitsAreEqual(T *exchange, 
        int bitsToExchange,
        T * comperand, 
        int bitsToCompare
        )
    {
        T * returned = value;
        int bitsToIgnore = ~bitsToCompare;
        int bitsToLeave = ~bitsToExchange;
        for (;;){
            exchange = (T*)((int)exchange&bitsToExchange) | (bitsToLeave&(int)returned);
            returned = InterlockedCompareExchange(&value,exchange,comperand);
            if (returned == comperand) return true;
            if (0 != ((returned ^ comperand) & bitsToCompare)) break;
            comparand = (T*)((int)comparand&bitsToCompare) | (bitsToIgnore&(int)returned);
        }
        return false;
    }
    
    inline T *operator =(T *exchange)
    {
        Exchange(exchange);
        return exchange;
    }
    
    template <typename INT_TYPE>
        inline T *operator +=(INT_TYPE n)
    {
        return n + (T *)InterlockedExchangeAdd((LPLONG)&value, (LONG)(n * (LONG)sizeof(T)));
    }
    
    template <typename INT_TYPE>
        inline T *operator -=(INT_TYPE n)
    {
        return (T *)InterlockedExchangeAdd((LPLONG)&value, (LONG)(-n * (LONG)sizeof(T))) - n;
    }
    inline T *operator ++()
    {
        return (T *)InterlockedExchangeAdd((LPLONG)&value, (LONG)(sizeof(T))) + 1;
    }
    
    inline T *operator --() 
    {
        return (T *)InterlockedExchangeAdd((LPLONG)&value, -(LONG)(sizeof(T))) - 1;
    }
    
    inline T *operator ++(int)
    {
        return (T*)InterlockedExchangeAdd((LPLONG)&value, (LONG)sizeof(T));
    }
    
    inline T *operator --(int)
    {
        return (T*)InterlockedExchangeAdd((LPLONG)&value, -(LONG)sizeof(T));
    }
    
    //yes this isn't standard, but it's useful
    template <typename INT_TYPE>
        inline T *operator &=(INT_TYPE n)
    {
        T * comperand;
        T * exchange;
        do {
            comperand = value; 
            exchange = (T *)((LONG)comperand & n);
        }while(!SetIfEqual(exchange, comperand));
        return exchange;
    }
    
    //yes this isn't standard, but it's useful
    template <typename INT_TYPE>
        inline T *operator |= (INT_TYPE n) 
    {
        T * comperand;
        T * exchange;
        do {
            comperand = value; 
            exchange = (T *)((LONG)comperand | n);
        }while(!SetIfEqual(exchange, comperand));
        return exchange;
    }
    
    //yes this isn't standard, but it's useful
    template <typename INT_TYPE>
        inline T operator ^= (INT_TYPE n)
    {
        T * comperand;
        T * exchange;
        do {
            comperand = value;  
            exchange = (T *)((LONG)comperand ^ n);
        }while(!SetIfEqual(exchange, comperand));
        return exchange;
    }
    
    //yes this isn't standard, but it's useful
    template <typename INT_TYPE_A, typename INT_TYPE_B>
        inline T * Mask(INT_TYPE_A bitsToKeep, INT_TYPE_B bitsToSet) 
    {
        T * comperand;
        T * exchange;
        do {
            comperand = value ; 
            exchange = (T *)(((LONG)comperand & bitsToKeep) | bitsToSet);
        }while(!SetIfEqual(exchange, comperand));
        return exchange;
    }
    
    
    inline bool BTS(int bit)
    {
        return InterlockedBTS((volatile int *)&value,bit);
    }
    inline bool BTC(int bit)
    {
        return InterlockedBTC((volatile int *)&value,bit);
    }
    inline bool BTR(int bit)
    {
        return InterlockedBTR((volatile int *)&value,bit);
    }
    inline bool BT(int bit)
    {
        return BT((volatile int *)&value,bit);
    }
};

typedef Atomic<int> AtomicInt;
typedef Atomic<unsigned int> AtomicUInt;
typedef Atomic<__int64> AtomicInt64;
typedef Atomic<unsigned __int64> AtomicUInt64;

template
<typename T, typename A = AtomicUInt64>
struct AtomicUnion
{
    A whole;
    
    AtomicUnion()
    {
        assert(sizeof(T)<=sizeof(A));
        new((void *)&whole) T();//in place new
        
    }
    
    ~AtomicUnion()
    {
        ((T *)&whole)->~T();
    }
    
    T &Value() 
    {
        return *(T *)&whole;
    }
    const T &Value() const
    {
        return *(const T *)&whole;
    }
};


template <typename T>
struct AtomicPtrWithCountStruct
{
    AtomicPtr<T> ptr;
    AtomicInt count;
};


template <typename T>
struct PtrWithCountStruct
{
    T* ptr;
    int count;
};

template <typename T, int MARKBITS=3>
struct BitMarkedAtomicPtr : public AtomicPtr<T>
{
    const int MarkMask() const
    {
        return (1<<MARKBITS)-1;
    }
    
    const int DataMask() const
    {
        return ~ThreadBitMask();
    }
    
    static T * MaskPtr(T *data)
    {
        return (T*)((int)data & DataMask());
    }
    
    static int MaskMark(T * data)
    {
        return ((int)data & MarkMask());
    }
    
    static T* Mark(T * data, int bit)
    {
        return (T*)((int)data | 1<<bit);
    }
    
    static T* Unmark(T * data, int bit)
    {
        return (T*)((int)data & ~(1<<bit));
    }
    
    T * MaskPtr()
    {
        return MaskPtr(value);
    }
    
    int MaskMark()
    {
        return MaskMark(value);
    }
    
    //note new value has the marks in exchange not the original marks
    inline bool SetIfMarked(T *exchange, int bit)
    {
        assert(bit<MARKBITS);
        return SetIfSomeBitsAreEqual(exchange,DataMask(),(T*)(1<<bit),1<<bit);
    }
    
    //note new value has the marks in exchange not the original marks
    T * ExchangeIfMarked(T *exchange, int bit)
    {
        assert(bit<MARKBITS);
        return CompareSomeBitsAndExchange(exchange,DataMask(),(T*)(1<<bit),1<<bit);
    }
    
    inline bool SetAndClearMarksIfMarked(T *exchange, int bit)
    {
        return SetIfMarked(MaskPtr(exchange),bit);
    }
    
    inline T * ExchangeAndClearMarksIfMarked(T *exchange, int bit)
    {
        return ExchangeIfMarked(MaskPtr(exchange),bit);
    }
    
    inline bool SetAndClearOtherMarksIfMarked(T *exchange, int bit)
    {
        return SetIfMarked(Mark(MaskPtr(exchange),bit),
            bit);
    }
    
    //note new value has the marks in exchange not the original marks
    T * ExchangeAndClearOtherMarksIfMarked(T *exchange, int bit)
    {
        return ExchangeIfMarked(Mark(MaskPtr(exchange),bit),
            bit);
    }
    
    inline bool SetAndMarkIfMarked(T *exchange, int bit)
    {
        return SetSomeBitsIfSomeOtherBitsAreEqual(
            Mark(MaskPtr(exchange),bit),
            DataMask() | 1<<bit,
            (T*)(1<<bit),
            1<<bit);
    }
    
    inline T * ExchangeAndMarkIfMarked(T *exchange, int bit)
    {
        return CompareSomeBitsAndExchangeSomeOtherBits(
            Mark(MaskPtr(exchange),bit),
            DataMask() | 1<<bit,
            (T*)(1<<bit),
            1<<bit);
    }	 
    
    bool Mark(int bit)
    {
        assert(bit<MARKBITS);
        return BTS(bit);
    }
    
    bool Unmark(int bit)
    {
        assert(bit<MARKBITS);
        return BTC(bit);
    }
    
    bool InvertMark(int bit)
    {
        assert(bit<MARKBITS);
        return BTR(bit);
    }
    
    bool IsMarked(int bit)
    {
        assert(bit<MARKBITS);
        return BT(bit);
    }
};

template <typename T>
struct AtomicPtrWithCount : public AtomicUnion< AtomicPtrWithCountStruct<T> >
{
    typedef AtomicUnion< PtrWithCountStruct<T>, unsigned __int64 > SimpleUnionType;
    AtomicPtrWithCount()
    {
        whole = 0;
    }
    AtomicPtrWithCount(unsigned __int64 o)
    {
        whole = o.whole;
    }
    AtomicPtrWithCount(T *ptr)
    {
        SimpleUnionType o;
        o.Value().ptr = ptr;
        o.Value().count = 0;
        whole = o.whole;
    }
    
    operator unsigned __int64() const
    {
        return whole;
    }
    T *Ptr() const
    {
        return Value().ptr;
    }
    int Count() const
    {
        return Value().count;
    }
    unsigned __int64 Whole() const
    {
        return whole;
    }
    
    AtomicPtr<T> & Ptr()
    {
        return Value().ptr;
    }
    AtomicInt & Count()
    {
        return Value().count;
    }
    AtomicUInt64 & Whole()
    {
        return whole;
    }
    unsigned __int64 SetPtrAndIncCount(T *ptr)
    {
        SimpleUnionType was;
        SimpleUnionType to;
        to.Value().ptr = ptr;
        do {
            was.whole = whole;
            to.Value().count = was.Value().count+1;
        }while(!whole.SetIfEqual(to.whole,was.whole));
        return to.whole;
    }
    bool SetIfPtrEqualAndIncCount(T *exchange, T *comperand)
    {
        SimpleUnionType was;
        SimpleUnionType to;
        to.ptr = exchange;
        do {
            was.whole = whole;
            if (was.Value().ptr != comperand) return false;
            to.Value().count = was.Value().count+1;
        }while(!whole.SetIfEqual(to.whole,was.whole));
        return true;
    }
    unsigned __int64 ExchangeIfPtrEqualAndIncCount(T *exchange, T *comperand)
    {
        SimpleUnionType was;
        SimpleUnionType to;
        to.ptr = exchange;
        do {
            was.whole = whole;
            if (was.Value().ptr != comperand) return was.whole;
            to.Value().count = was.Value().count+1;
        }while(!whole.SetIfEqual(to.whole,was.whole));
        return was.whole;
    }
    inline T *operator =(T *exchange)
    {
        SetPtrAndIncCount(exchange);
        return exchange;
    }
    
    template <typename INT_TYPE>
        inline T *operator +=(INT_TYPE n)
    {
        T *was;
        T *to;
        do {
            was = Ptr();
            to = was + n;
        }while (!SetIfPtrEqualAndIncCount(to,was));
        return to;
    }
    
    template <typename INT_TYPE>
        inline T *operator -=(INT_TYPE n)
    {
        T *was;
        T *to;
        do {
            was = Ptr();
            to = was - n;
        }while (!SetIfPtrEqualAndIncCount(to,was));
        return to;
    }
    inline T *operator ++()
    {
        return (*this += 1);
    }
    
    inline T *operator --() 
    {
        return (*this -= 1);
    }
    
    inline T *operator ++(int)
    {
        return (++ *this) - 1;
    }
    
    inline T *operator --(int)
    {
        return (-- *this) + 1;
    }
};

template <typename T>
struct AtomicPtrWithMarkStruct
{
    AtomicPtr<T> ptr;
    AtomicUInt mark;
};


template <typename T>
struct PtrWithMarkStruct
{
    T* ptr;
    unsigned int mark;
};

template <typename T>
struct AtomicPtrWithMark : public AtomicUnion< AtomicPtrWithMarkStruct<T> >
{
    typedef AtomicUnion< PtrWithMarkStruct<T>, unsigned __int64 > SimpleUnionType;
    AtomicPtrWithMark()
    {
        whole = 0;
    }
    AtomicPtrWithMark(unsigned __int64 o)
    {
        whole = o.whole;
    }
    AtomicPtrWithMark(T *ptr)
    {
        SimpleUnionType o;
        o.Value().ptr = ptr;
        o.Value().mark = 0;
        whole = o.whole;
    }
    
    operator unsigned __int64() const
    {
        return whole;
    }
    T *Ptr() const
    {
        return Value().ptr;
    }
    int Mark() const
    {
        return Value().mark;
    }
    unsigned __int64 Whole() const
    {
        return whole;
    }
    
    AtomicPtr<T> & Ptr()
    {
        return Value().ptr;
    }
    AtomicInt & Mark()
    {
        return Value().mark;
    }
    AtomicUInt64 & Whole()
    {
        return whole;
    }
    
    inline bool SetAndClearOtherMarksIfMarked(T *exchange, int bit)
    {
        assert(bit<32);
        SimpleUnionType compareMask;
        compareMask.Value().ptr = NULL;
        compareMask.Value().mark = 1u<<bit;
        
        SimpleUnionType exchangeValue;
        exchangeValue.Value().ptr = exchange;
        exchangeValue.Value().mark = compareMask.Value().mark;
        
        return whole.SetSomeBitsIfSomeOtherBitsAreEqual(exchangeValue.whole,
            (unsigned __int64)-1i64,
            compareMask.whole,
            compareMask.whole);
    }
    inline bool SetAndClearMarksIfPtrEqual(T *exchange, T*comparend)
    {
        SimpleUnionType compareMask;
        compareMask.Value().ptr = (T*)-1;
        compareMask.Value().mark = 0;
        
        SimpleUnionType compareValue;
        compareValue.Value().ptr = comparend;
        compareValue.Value().mark = 0;
        
        SimpleUnionType exchangeValue;
        exchangeValue.Value().ptr = exchange;
        exchangeValue.Value().mark = 0;
        
        return whole.SetSomeBitsIfThoseBitsAreEqual(exchangeValue.whole,
            compareValue.whole,
            compareMask.whole);
    }
    
    inline bool SetAndClearMarksIfMarked(T *exchange, int bit)
    {
        assert(bit<32);
        SimpleUnionType compareMask;
        compareMask.Value().ptr = NULL;
        compareMask.Value().mark = 1u<<bit;
        
        SimpleUnionType exchangeValue;
        exchangeValue.Value().ptr = exchange;
        exchangeValue.Value().mark = 0;
        
        return whole.SetSomeBitsIfSomeOtherBitsAreEqual(exchangeValue.whole,
            (unsigned __int64)-1i64,
            compareMask.whole,
            compareMask.whole);
    }
    //note new value has the marks in exchange not the original marks
    unsigned __int64 ExchangeAndClearOtherMarksIfMarked(T *exchange, int bit)
    {
        assert(bit<32);
        SimpleUnionType compareMask;
        compareMask.Value().ptr = NULL;
        compareMask.Value().mark = 1u<<bit;
        
        SimpleUnionType exchangeValue;
        exchangeValue.Value().ptr = exchange;
        exchangeValue.Value().mark = compareMask.Value().mark;
        
        return whole.CompareSomeBitsAndExchangeSomeOtherBits(exchangeValue.whole,
            exchangeMask.whole,
            compareMask.whole,
            compareMask.whole);
    }
    
    unsigned __int64 ExchangeAndClearMarksIfMarked(T *exchange, int bit)
    {
        assert(bit<32);
        SimpleUnionType compareMask;
        compareMask.Value().ptr = NULL;
        compareMask.Value().mark = 1u<<bit;
        
        SimpleUnionType exchangeValue;
        exchangeValue.Value().ptr = exchange;
        exchangeValue.Value().mark = 0;
        
        return whole.CompareSomeBitsAndExchangeSomeOtherBits(exchangeValue.whole,
            exchangeMask.whole,
            compareMask.whole,
            compareMask.whole);
    }
    
    
    bool Mark(int bit)
    {
        assert(bit<32);
        return whole.BTS(bit);
    }
    
    bool Unmark(int bit)
    {
        assert(bit<32);
        return whole.BTC(bit);
    }
    
    bool InvertMark(int bit)
    {
        assert(bit<32);
        return whole.BTR(bit);
    }
    
    bool IsMarked(int bit)
    {
        assert(bit<32);
        return whole.BT(bit);
    }
};

struct MPStackElement
{
    MPStackElement * next;
};

class MPMarkStack
{
protected:
    AtomicPtrWithMark<MPStackElement> tos;
    AtomicUInt availableThreadBits;
    AtomicInt lastReserved;
    
public:
    
    MPStackElement* ExchangeStack(MPStackElement *newStack = NULL)
    {
        AtomicPtrWithMark<MPStackElement>::SimpleUnionType newWhole, ret;
        newWhole.Value().mark = 0;
        newWhole.Value().ptr = newStack;
        ret.whole = tos.whole.Exchange(newWhole.whole);
        return ret.Value().ptr;
    }
    
    MPMarkStack()
    {
        lastReserved = 0;
        tos.whole = 0;
        availableThreadBits = (unsigned)-1;
    }
    
    //expensive - call once per thread to reserve a bit
    int ReserveThreadBit()
    {
        int offset = lastReserved;
        //since locked operations are slow we only do
        //bit tests on bits that look acceptable because
        //of a nonlocked read.
        unsigned readOnce = availableThreadBits;
        for (int i=0; i< 32;++i){
            const int bit = (31&(i+offset));
            const unsigned mask = 1u<<bit;
            if ((readOnce & mask)!=0){
                if (availableThreadBits.BTR(bit)) {
                    lastReserved = ((bit+1)&31);//try the next one
                    return bit+1;
                }
                readOnce = availableThreadBits;
            }
        }
        return 0;
    }
    int BlockingReserveThreadBit()
    {
        int i;
        while (0==(i=ReserveThreadBit()));
        return i;
    }
    int ReturnThreadBit(int i)
    {
        availableThreadBits.BTS(i-1);
    }
    
    void PushElement(MPStackElement *element)
    {
        MPStackElement * next;
        do {
            next = tos.Value().ptr;
            element->next = tos.Value().ptr;
        }while(!tos.SetAndClearMarksIfPtrEqual(element,next));
    }
    
    void PushList(MPStackElement *top, MPStackElement *bottom)
    {
        MPStackElement * next;
        do {
            next = tos.Value().ptr;
            bottom->next = tos.Value().ptr;
        }while(!tos.SetAndClearMarksIfPtrEqual(top,next));
    }
    
    MPStackElement* PopElement(int i)
    {
        for(;;) {
            tos.Value().mark.BTS(i-1);
            MPStackElement * was = tos.Value().ptr;
            if (was == NULL) return NULL;
            if (tos.SetAndClearMarksIfMarked(was->next,i-1)) return was;
        }
    }
    MPStackElement* PopElement()
    {
        int id = BlockingReserveThreadBit();
        MPStackElement * ret = PopElement(id);
        ReturnThreadBit(id);
        return ret;
    }
};
class MPCountStack
{
protected:
    AtomicPtrWithCount<MPStackElement> tos;
    
public:
    
    MPStackElement* ExchangeStack(MPStackElement *newStack = NULL)
    {
        return tos.Value().ptr.Exchange(newStack);
    }
    
    MPCountStack()
    {
        tos = 0;
    }
    
    
    void PushElement(MPStackElement *element)
    {
        MPStackElement * next;
        do {
            next = tos.Value().ptr;
            element->next = tos.Value().ptr;
        }while(!tos.Value().ptr.SetIfEqual(element,next));
    }
    
    void PushList(MPStackElement *top, MPStackElement *bottom)
    {
        MPStackElement * next;
        do {
            next = tos.Value().ptr;
            bottom->next = tos.Value().ptr;
        }while(!tos.Value().ptr.SetIfEqual(top,next));
    }
    
    MPStackElement* PopElement()
    {
        AtomicPtrWithCount<MPStackElement>::SimpleUnionType was;
        AtomicPtrWithCount<MPStackElement>::SimpleUnionType to;
        do {
            was.whole = tos.whole;
            if (was.Value().ptr == NULL) return NULL;
            to.Value().count = was.Value().count + 1;
            to.Value().ptr = was.Value().ptr->next;
        }while(!tos.whole.SetIfEqual(was.whole,to.whole));
        return was.Value().ptr;
    }
};

class SimpleStack
{
protected:
    MPStackElement * tos;
    
public:
    
    MPStackElement* ExchangeStack(MPStackElement *newStack = NULL)
    {
        MPStackElement* was = tos;
        tos = newStack;
        return was;
    }
    
    SimpleStack()
    {
        tos = 0;
    }
    
    
    void PushElement(MPStackElement *element)
    {
        element->next = tos;
        tos = element;
    }
    
    void PushList(MPStackElement *top, MPStackElement *bottom)
    {
        bottom->next = tos;
        tos = top;
    }
    
    MPStackElement* PopElement()
    {
        MPStackElement* was = tos;
        if (was) tos = was->next;
        return was;
    }
};

template <typename T>
struct MPMemBlock : public MPStackElement
{
    T data;
    char bottomOfBlock;
};

#define OFFSET_OF_MEMBER(type,member) ((int)&(((type *)0)->member))

//put one of these in each thread object 
//and you have thread local allocation
template <typename T, typename BLOCK_ALLOCATOR>
struct SimpleBlockAllocator
{
    SimpleStack data;
    
    typedef SimpleBlockAllocator<T,BLOCK_ALLOCATOR> AllocatorType;
    
    BLOCK_ALLOCATOR & MyAllocator;
    
    SimpleBlockAllocator(BLOCK_ALLOCATOR &source)
        :MyAllocator(source)
    {}
    
    int ReserveThreadBit(){return 1;}
    int BlockingReserveThreadBit(){return 1;}
    void ReturnThreadBit(int){  }
    
    int Size() const { return sizeof(T); }
    void AddBlock()
    {
        int blockSize = MyAllocator.Size();
        int elementSize = sizeof(MPMemBlock<T>);
        assert( MyAllocator.Size() >= elementSize);
        MPMemBlock<T> *bottom = (MPMemBlock<T> *)MyAllocator.Allocate();
        void *prev = 0;
        MPMemBlock<T> *top = bottom;  
        do {
            top->bottomOfBlock = 0;
            top->next = prev;
            prev = (void *)top;
            ++top;
        }while( (blockSize-=elementSize) >= elementSize);
        bottom->bottomOfBlock = 1;
        data.PushList(top-1,bottom);
    }
    void *Allocate(int) 
    {	
        return Allocate();
    }
    void *Allocate() 
    {	
        MPMemBlock<T> *ret;
        for(;;) {
            ret = (MPMemBlock<T> *)data.PopElement();
            if (ret!=NULL) return &ret->data;
            AddBlock();
        }
    }
    void Deallocate(void *ob) 
    {
        if (!ob) return;
        MPMemBlock<T> *ret = (MPMemBlock<T> *)
            ((char *)data - OFFSET_OF_MEMBER(MPMemBlock<T>,ob));
        data.PushElement(ret);
    }
    //all memory allocated must be Deallocated before Clear() or the destructor is called
    void Clear() 
    {
        MPMemBlock<T> *stackWas = (MPMemBlock<T> *)data.ExchangeStack(NULL);
        MPMemBlock<T> *blocks = NULL;
        while(stackWas){
            if (stackWas->bottomOfBlock){
                if (blocks) {
                    blocks->next = stackWas;
                }
                blocks = stackWas;
            }
            stackWas = (MPMemBlock<T> *)(stackWas->next);
        }
        while(blocks)
        {
            stackWas = (MPMemBlock<T> *)blocks->next;
            MyAllocator.Deallocate(blocks);
            blocks = stackWas;
        }
    }
    //all memory allocated must be Deallocated before Clear() or the destructor is called
    ~SimpleBlockAllocator()
    {
        Clear();
    }
};

template<class T>
struct SimpleAllocator
{
    void *Allocate() { return (void *)new char[sizeof(T)]; }
    void *Allocate(int) { return Allocate(); }
    
    int ReserveThreadBit(){return 1;}
    int BlockingReserveThreadBit(){return 1;}
    void ReturnThreadBit(int){}
    
    void Deallocate(void *data) { delete[] (char[])data; }
    int Size() const { return sizeof(T); }
    typedef SimpleAllocator AllocatorType;
};

enum DontReserve{ DONT_RESERVE };

template<class T>
struct ThreadMarkedAllocator
{
    T& allocator;
    int bit;
    
    ThreadMarkedAllocator(T &sourceAllocator)
        :allocator(sourceAllocator)
        ,bit(sourceAllocator.BlockingReserveThreadBit())
    {}
    
    ThreadMarkedAllocator(T &sourceAllocator,DontReserve)
        :allocator(sourceAllocator)
        ,bit(0)
    {}
    
    ~ThreadMarkedAllocator()
    {
        allocator.ReturnThreadBit(bit);
    }
    
    bool ReserveThreadBit()
    {
        if (bit==0) bit=sourceAllocator.ReserveThreadBit();
        return bit!=0;
    }
    void BlockingReserveThreadBit()
    {
        if (bit==0) bit=sourceAllocator.BlockingReserveThreadBit();
    }
    void ReturnThreadBit()
    {
        int was = bit;
        bit = 0;
        sourceAllocator.ReturnThreadBit(was);
    }
    
    void *Allocate() 
    { 
        assert(bit!=0);
        return allocator.Allocate(bit); 
    }
    
    void Deallocate(void *data) { allocator.Deallocate(data); }
    int Size() const { return Allocator.Size(); }
    typedef ThreadMarkedAllocator<T> AllocatorType;
};

template <typename T, typename BLOCK_ALLOCATOR>
struct MPMarkFreeListAllocator
{
    MPMarkStack data;
    
    typedef MPMarkFreeListAllocator<T,BLOCK_ALLOCATOR> AllocatorType;
    
    BLOCK_ALLOCATOR &MyAllocator;
    
    MPMarkFreeListAllocator(BLOCK_ALLOCATOR &source)
        :MyAllocator(source)
    {}
    
    int ReserveThreadBit(){return data.ReserveThreadBit();}
    int BlockingReserveThreadBit(){return data.BlockingReserveThreadBit();}
    void ReturnThreadBit(int bit){ data.ReturnThreadBit(bit); }
    
    int Size() const { return sizeof(T); }
    void AddBlock()
    {
        int blockSize = MyAllocator.Size();
        int elementSize = sizeof(MPMemBlock<T>);
        assert( MyAllocator.Size() >= elementSize);
        MPMemBlock<T> *bottom = (MPMemBlock<T> *)MyAllocator.Allocate();
        void *prev = 0;
        MPMemBlock<T> *top = bottom;  
        do {
            top->bottomOfBlock = 0;
            top->next = prev;
            prev = (void *)top;
            ++top;
        }while( (blockSize-=elementSize) >= elementSize);
        bottom->bottomOfBlock = 1;
        data.PushList(top-1,bottom);
    }
    void *Allocate(int mark) 
    {	
        MPMemBlock<T> *ret;
        for(;;) {
            ret = (MPMemBlock<T> *)data.PopElement(mark);
            if (ret!=NULL) return ret;
            AddBlock();
        }
    }
    void *Allocate() 
    {	
        MPMemBlock<T> *ret;
        for(;;) {
            ret = (MPMemBlock<T> *)data.PopElement();
            if (ret!=NULL) return &ret->data;
            AddBlock();
        }
    }
    void Deallocate(void *ob) 
    {
        if (!ob) return;
        MPMemBlock<T> *ret = (MPMemBlock<T> *)
            ((char *)data - OFFSET_OF_MEMBER(MPMemBlock<T>,ob));
        data.PushElement(ret);
    }
    //all memory allocated must be Deallocated before Clear() or the destructor is called
    void Clear()
    {
        MPMemBlock<T> *stackWas = (MPMemBlock<T> *)data.ExchangeStack(NULL);
        MPMemBlock<T> *blocks = NULL;
        while(stackWas){
            if (stackWas->bottomOfBlock){
                if (blocks) {
                    blocks->next = stackWas;
                }
                blocks = stackWas;
            }
            stackWas = (MPMemBlock<T> *)(stackWas->next);
        }
        while(blocks)
        {
            stackWas = (MPMemBlock<T> *)blocks->next;
            MyAllocator.Deallocate(blocks);
            blocks = stackWas;
        }
    }
    //all memory allocated must be Deallocated before Clear() or the destructor is called
    ~MPMarkFreeListAllocator()
    {
        Clear();
    }
};
template <typename T, typename BLOCK_ALLOCATOR>
struct MPCountFreeListAllocator
{
    MPCountStack data;
    
    typedef MPCountFreeListAllocator<T,BLOCK_ALLOCATOR> AllocatorType;
    
    BLOCK_ALLOCATOR & MyAllocator;
    
    MPCountFreeListAllocator(BLOCK_ALLOCATOR &source)
        :MyAllocator(source)
    {}
    
    int ReserveThreadBit(){return 1;}
    int BlockingReserveThreadBit(){return 1;}
    void ReturnThreadBit(int){  }
    
    int Size() const { return sizeof(T); }
    void AddBlock()
    {
        int blockSize = MyAllocator.Size();
        int elementSize = sizeof(MPMemBlock<T>);
        assert( MyAllocator.Size() >= elementSize);
        MPMemBlock<T> *bottom = (MPMemBlock<T> *)MyAllocator.Allocate();
        void *prev = 0;
        MPMemBlock<T> *top = bottom;  
        do {
            top->bottomOfBlock = 0;
            top->next = prev;
            prev = (void *)top;
            ++top;
        }while( (blockSize-=elementSize) >= elementSize);
        bottom->bottomOfBlock = 1;
        data.PushList(top-1,bottom);
    }
    void *Allocate(int) 
    {	
        return Allocate();
    }
    void *Allocate() 
    {	
        MPMemBlock<T> *ret;
        for(;;) {
            ret = (MPMemBlock<T> *)data.PopElement();
            if (ret!=NULL) return &ret->data;
            AddBlock();
        }
    }
    void Deallocate(void *ob) 
    {
        if (!ob) return;
        MPMemBlock<T> *ret = (MPMemBlock<T> *)
            ((char *)data - OFFSET_OF_MEMBER(MPMemBlock<T>,ob));
        data.PushElement(ret);
    }
    //all memory allocated must be Deallocated before Clear() or the destructor is called
    void Clear() 
    {
        MPMemBlock<T> *stackWas = (MPMemBlock<T> *)data.ExchangeStack(NULL);
        MPMemBlock<T> *blocks = NULL;
        while(stackWas){
            if (stackWas->bottomOfBlock){
                if (blocks) {
                    blocks->next = stackWas;
                }
                blocks = stackWas;
            }
            stackWas = (MPMemBlock<T> *)(stackWas->next);
        }
        while(blocks)
        {
            stackWas = (MPMemBlock<T> *)blocks->next;
            MyAllocator.Deallocate(blocks);
            blocks = stackWas;
        }
    }
    //all memory allocated must be Deallocated before Clear() or the destructor is called
    ~MPCountFreeListAllocator()
    {
        Clear();
    }
};

struct Counted
{
    mutable AtomicInt refCount;
    Counted():refCount(0){}
};

//it is NOT safe to read or write from more than one thread at a time
template <typename T> 
class CountedPtr
{
    
protected:
    T *value;
    void decRefCount()
    {
        decRefCount(value);
    }
public:
    static void decRefCount(T *ptr)
    {
        if (ptr && 0 == --ptr->refCount){
            delete ptr;
        }
    }
    void SetValueIgnoringRefCounts(T *ptr) 
    { 
        value = ptr; 
    }
    CountedPtr():letter(NULL){}
    
    CountedPtr(T *ptr)
    {
        value = ptr;
        if (value) ++value->refCount;
    }
    
    operator const T *() const { return value; }
    operator T *() { return value; }
    
    CountedPtr<T> & operator=(const T *ptr)
    {
        if (ptr) ++ptr->refCount;
        decRefCount();
        value = ptr;
        return *this;
    }
    
    operator bool() const
    { return value!=NULL; }
    
    bool operator !() const
    { return value==NULL; }
    
    
    const T & operator*() const
    { return *value; }
    
    T & operator*()
    { return *value; }
    
    T * operator->()
    { assert(value); return value; }
    const T * operator->()const
    { assert(value); return value; }
    
    ~CountedPtr()
    {
        decRefCount();
    }
};

template <typename T>
class AtomicCountedPtr
{
protected:
    mutable AtomicPtrWithCount<T> value;
public:
    
    
    CountedPtr<T> & LoadValue(CountedPtr<T> &dest) const 
    { 
retry:
    AtomicPtrWithCount<T>::SimpleUnionType inc;
    inc.Value().ptr = 0;
    inc.Value().count = 1;
    AtomicPtrWithCount<T>::SimpleUnionType ret;
    ret.whole = (value.whole+=inc.whole); //increment in ptr
    dest = ret.Value().ptr ; //increment in object
    AtomicPtrWithCount<T>::SimpleUnionType update;
    update.Value().ptr = ret.Value().ptr;
    for(;;){
        update.Value().count = ret.Value().count-1;
        AtomicPtrWithCount<T>::SimpleUnionType current;
        current.whole = value.whole.SetIfEqual(update.whole,ret.whole);
        if (current.whole == ret.whole) break; //successfully decremented in ptr
        if (current.Value().ptr != ret.Value().ptr) || current.Value().count < 1){
            //because of the line "dest = ret.Value().ptr" above
            //the old value will decrement in the prev object as the next object is loaded
            goto retry; 
        }
        ret.Value().count = current.Value().count;
    }
    return dest; 
    }
    
    CountedPtr<T> & LoadValue(CountedPtr<T> &dest, int &count) const 
    { 
retry:
    AtomicPtrWithCount<T>::SimpleUnionType inc;
    inc.Value().ptr = 0;
    inc.Value().count = 1;
    AtomicPtrWithCount<T>::SimpleUnionType ret;
    ret.whole = (value.whole+=inc.whole); //increment in ptr
    dest = ret.Value().ptr ; //increment in object
    AtomicPtrWithCount<T>::SimpleUnionType update;
    update.Value().ptr = ret.Value().ptr;
    for(;;){
        update.Value().count = ret.Value().count-1;
        AtomicPtrWithCount<T>::SimpleUnionType current;
        current.whole = value.whole.SetIfEqual(update.whole,ret.whole);
        if (current.whole == ret.whole) break; //successfully decremented in ptr
        if (current.Value().ptr != ret.Value().ptr) || current.Value().count < 1){
            //because of the line "dest = ret.Value().ptr" above
            //the old value will decrement in the prev object as the next object is loaded
            goto retry; 
        }
        ret.Value().count = current.Value().count;
    }
    count = ret.Value().count;
    return dest; 
    }
    
    CountedPtr<T> & ExchangeInPlace(CountedPtr<T> &dest)
    { 
        AtomicPtrWithCount<T>::SimpleUnionType destWhole;
        destWhole.Value().ptr = dest;
        destWhole.Value().count = 0;
        destWhole.whole = value.whole.Exchange(destWhole.whole);
        if (destWhole.Value().ptr != NULL && destWhole.Value().count != 0) 
            destWhole.Value().ptr->refCount += destWhole.Value().count;
        dest.SetValueIgnoringRefCounts(destWhole.Value().ptr);
        return dest; 
    }
    
    CountedPtr<T> & Exchange(CountedPtr<T> &dest, T *source)
    { 
        dest = source;
        return ExchangeInPlace(dest);
    }
    
    bool CompareExchange(CountedPtr<T> &dest, T *exchange, T * comparend)
    { 
        CountedPtr<T> holdExchange(exchange);
retry:
        AtomicPtrWithCount<T>::SimpleUnionType comp;
        if (LoadValue(dest,comp.Value().count) != comparend) return false;
        comp.Value().ptr = dest;
        AtomicPtrWithCount<T>::SimpleUnionType exch;
        exch.Value().ptr=exchange;
        exch.Value().count = 0;
        AtomicPtrWithCount<T>::SimpleUnionType ret;
        for (;;){
            ret.whole = value.whole.CompareExchange(exch.whole,comp.whole);
            if (ret.whole == comp.whole) {
                //transfer increment from holdExchange to this
                holdExchange.SetValueIgnoringRefCounts(NULL);
                //had inc from Load and the one from this 
                if (dest) {
                    const int dec = 1-comp.Value().count;
                    if (dec!=0) dest->refCount -= dec;
                }
                return true;
            }
            if (ret.Value().ptr != comp.Value().ptr) {
                //cant return the new pointer because there's no
                //reason to think it hasn't been collected already
                goto retry;
            }
            comp.Value().count = ret.Value().count;
        }
    }
    
    bool SetIfEqual(T *exchange, T * comparend)
    { 
        CountedPtr<T> holdExchange(exchange);
retry:
        AtomicPtrWithCount<T>::SimpleUnionType comp;
        comp.whole = value.whole;
        if (comp.Value().ptr != comparend) return false;
        AtomicPtrWithCount<T>::SimpleUnionType exch;
        exch.Value().ptr=exchange;
        exch.Value().count = 0;
        AtomicPtrWithCount<T>::SimpleUnionType ret;
        for (;;){
            ret.whole = value.whole.CompareExchange(exch.whole,comp.whole);
            if (ret.whole == comp.whole) {
                if (comp.Value().ptr) {
                    const int dec = 1-comp.Value().count;
                    if (dec!=0 && 0==(comp.Value().ptr->refCount -= dec)){
                        delete comp.Value().ptr;
                    };
                }
                //transfer increment from holdExchange to this
                holdExchange.SetValueIgnoringRefCounts(NULL);
                return true;
            }
            if (ret.Value().ptr != comp.Value().ptr) {
                return false;
            }
            comp.Value().count = ret.Value().count;
        }
    }
    
    void operator = (const T *ptr)
    {
        CountedPtr<T> dest(ptr);
        ExchangeInPlace(dest);
    }
    
    //not recommended because value won't be consistant throughout 
    //a given expression
    operator bool() const
    { return value.Value().ptr!=NULL; }
    
    //not recommended because value won't be consistant throughout 
    //a given expression
    bool operator !() const
    { return value.Value().ptr==NULL; }
    
    
    AtomicCountedPtr()
    {}
    
    ~AtomicCountedPtr()
    {
        *this = (T*)NULL;
    }
};

class MPQueueBase
{
    AtomicUInt * data;
    int len;
    
    struct AtomicHeadAndTail{
        AtomicInt head;
        AtomicInt tail;
    };
    
    AtomicUnion<AtomicHeadAndTail> headAndTail;
    
    struct HeadAndTailStruct{
        int head;
        int tail;
    };
    union HeadAndTailUnion
    {
        HeadAndTailStruct value;
        unsigned __int64 whole;
    };
    
    AtomicUInt & Index(int i)
    {
        return data[i & (len-1)];
    }
    bool IsNil(int i)
    {
        return (i & 1) != 0;
    }
    
    public:
        
        int Used() const
        {
            HeadAndTailUnion ht;
            ht.whole = headAndTail.whole;
            return ht.value.head-ht.value.tail;
            
        }
        bool Empty() const
        {
            HeadAndTailUnion ht;
            ht.whole = headAndTail.whole;
            return ht.value.head==ht.value.tail;
        }
        int Available() const
        {
            return MaxLen()-Used();
            
        }
        int MaxLen() const
        {
            return len;
        }
        
        MPQueueBase(int lenLn2)
            :len(1<<lenLn2)
        {
            headAndTail.whole = 0;
            data = new AtomicUInt[len];
            for (int i=0;i<len;++i) data[i] = 1;
        }
        
        ~MPQueueBase()
        {
            delete [] data;
        }
        
        bool Put(int v)
        {
            assert((v&1)==0);
            for(;;){
                HeadAndTailUnion ht;
                ht.whole = headAndTail.whole;
                if (ht.value.head-ht.value.tail >= len) return false;
                
                int wasThere = Index(ht.value.head);
                
                if (IsNil(wasThere)){
                    if (Index(ht.value.head).SetIfEqual(v,wasThere)){
                        headAndTail.Value().head.SetIfEqual(1+ht.value.head,ht.value.head);
                        return true;
                    }
                }
                headAndTail.Value().head.SetIfEqual(1+ht.value.head,ht.value.head);
            }
        }
        int Get()
        {
            for(;;){
                HeadAndTailUnion ht;
                ht.whole = headAndTail.whole;
                if (ht.value.head-ht.value.tail < 1) return 0;
                
                int wasThere = Index(ht.value.tail);
                int newNil = (ht.value.tail|1);
                
                if (!IsNil(wasThere)){
                    if (Index(ht.value.tail).SetIfEqual(newNil,wasThere)){
                        headAndTail.Value().tail.SetIfEqual(1+ht.value.tail,ht.value.tail);
                        return wasThere;
                    }
                }
                headAndTail.Value().tail.SetIfEqual(1+ht.value.tail,ht.value.tail);
            }
        }
};

template <typename T>
class MPQueue 
{
    MPQueueBase queue;
public:
    MPQueue(int lenLn2)
        :queue(lenLn2)
    {}
    T *Get()
    {
        return (T*)queue.Get();
    }
    bool Put(T * v)
    {
        return queue.Put((int)v);
    }
    bool Empty() const
    {
        return queue.Empty();
    }
    int Used() const
    {
        return queue.Used();
        
    }
    int Available() const
    {
        return queue.Available();
        
    }
    int MaxLen() const
    {
        return queue.MaxLen();
    }
};

class QueueBase
{
    unsigned * data;
    int len;
    
    int head;
    int tail;
    
    unsigned & Index(int i)
    {
        return data[i & (len-1)];
    }
    
public:
    
    int Used() const
    {
        return head-tail;
        
    }
    bool Empty() const
    {
        return head==tail;
        
    }
    
    int Available() const
    {
        return MaxLen()-Used();
        
    }
    int MaxLen() const
    {
        return len;
    }
    
    QueueBase(int lenLn2)
        :len(1<<lenLn2)
        ,head(0)
        ,tail(0)
    {
        data = new unsigned[len];
        for (int i=0;i<len;++i) data[i] = 1;
    }
    
    ~QueueBase()
    {
        delete [] data;
    }
    
    bool Put(int v)
    {
        if (Available() < 1) return false;
        Index(head++) = v;
        return true;
    }
    
    int Get()
    {
        if (Used() < 1) return 0;
        return Index(tail++);
    }
};
template <typename T>
class Queue 
{
    QueueBase queue;
public:
    Queue(int lenLn2)
        :queue(lenLn2)
    {}
    T *Get()
    {
        return (T*)queue.Get();
    }
    bool Put(T * v)
    {
        return queue.Put((int)v);
    }
    bool Empty() const
    {
        return queue.Empty();
    }
    int Used() const
    {
        return queue.Used();
        
    }
    int Available() const
    {
        return queue.Available();
        
    }
    int MaxLen() const
    {
        return queue.MaxLen();
    }
};


#endif
