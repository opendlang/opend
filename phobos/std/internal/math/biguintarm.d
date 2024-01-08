/** Optimised asm arbitrary precision arithmetic ('bignum')
 * routines for ARM processors.
 *
 * All functions operate on arrays of uints, stored LSB first.
 * If there is a destination array, it will be the first parameter.
 * Currently, all of these functions are subject to change, and are
 * intended for internal use only.
 */

/*          Copyright Kai Nacke 2016.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */

/**
 * Like the generic module biguintnoasm, some functions assume
 * non-empty arrays.
 */

module std.internal.math.biguintarm;

version (LDC):
version (ARM):

import ldc.llvmasm;

static import stdnoasm = std.internal.math.biguintnoasm;

@trusted:

public:
alias BigDigit = stdnoasm.BigDigit; // A Bignum is an array of BigDigits.

    // Limits for when to switch between multiplication algorithms.
enum : int { KARATSUBALIMIT = 10 }; // Minimum value for which Karatsuba is worthwhile.
enum : int { KARATSUBASQUARELIMIT=12 }; // Minimum value for which square Karatsuba is worthwhile


/** Multi-byte addition or subtraction
 *    dest[] = src1[] + src2[] + carry (0 or 1).
 * or dest[] = src1[] - src2[] - carry (0 or 1).
 * Returns carry or borrow (0 or 1).
 * Set op == '+' for addition, '-' for subtraction.
 */
uint multibyteAddSub(char op)(uint[] dest, const(uint) [] src1,
    const (uint) [] src2, uint carry) pure @nogc nothrow
{
    assert(carry == 0 || carry == 1);
    assert(src1.length >= dest.length && src2.length >= dest.length);
    static if (op == '+')
    {
        enum opcs = "adcs"; // Use "addition with carry"
        enum foc = "@";     // Use comment
    }
    else
    {
        enum opcs = "sbcs"; // Use "subtraction with carry"
        enum foc = "eor";   // Use "exclusive or"
    }
    return __asm!uint(` cmp    $2,#0                 @ Check dest.length
                        beq    1f
                      `~foc~`  $0,$0,#1              @ Flip carry or comment
                         mov   r5,#0                 @ Initialize index
                       2:
                         ldr   r6,[${3:m},r5,LSL #2] @ Load *(src1.ptr + index)
                         ldr   r7,[${4:m},r5,LSL #2] @ Load *(src2.ptr + index)
                         lsrs  $0,$0,#1              @ Set carry
                     `~opcs~`  r6,r6,r7              @ Add/Sub with carry
                         str   r6,[${1:m},r5,LSL #2] @ Store *(dest.ptr + index)
                         adc   $0,$0,#0              @ Store carry
                         add   r5,r5,#1              @ Increment index
                         cmp   $2,r5
                         bhi   2b
                      `~foc~`  $0,$0,#1              @ Flip carry or comment
                       1:`,
                      "=&r,=*m,r,*m,*m,0,~{r5},~{r6},~{r7},~{cpsr}",
                      dest.ptr, dest.length, src1.ptr, src2.ptr, carry);
}

unittest
{
    // Some simple checks to validate the interface
    uint carry;
    uint [] a = new uint[40];
    uint [] b = new uint[40];
    uint [] c = new uint[40];

    // Add
    a[0] = 0xFFFFFFFE;
    b[0] = 0x00000001;
    c[1] = 0xDEADBEEF;
    carry = multibyteAddSub!('+')(c[0..1], a[0..1], b[0..1], 0);
    assert(c[0] == 0xFFFFFFFF);
    assert(carry == 0);

    a[0] = 0xFFFFFFFE;
    b[0] = 0x00000000;
    carry = multibyteAddSub!('+')(c[0..1], a[0..1], b[0..1], 1);
    assert(c[0] == 0xFFFFFFFF);
    assert(carry == 0);

    a[0] = 0xFFFFFFFF;
    b[0] = 0x00000001;
    carry = multibyteAddSub!('+')(c[0..1], a[0..1], b[0..1], 0);
    assert(c[0] == 0x00000000);
    assert(carry == 1);

    a[0] = 0xFFFFFFFF;
    b[0] = 0x00000000;
    carry = multibyteAddSub!('+')(c[0..1], a[0..1], b[0..1], 1);
    assert(c[0] == 0x00000000);
    assert(carry == 1);

    a[0] = 0xFFFFFFFF;
    a[1] = 0x00000000;
    b[0] = 0x00000001;
    b[1] = 0x00000000;
    c[0] = 0xDEADBEEF;
    c[1] = 0xDEADBEEF;
    c[2] = 0xDEADBEEF;
    carry = multibyteAddSub!('+')(c[0..2], a[0..2], b[0..2], 0);
    assert(c[0] == 0x00000000);
    assert(c[1] == 0x00000001);
    assert(c[2] == 0xDEADBEEF);
    assert(carry == 0);

    a[0] = 0xFFFF0000;
    b[0] = 0x0001FFFF;
    for (size_t i = 1; i < 9; i++)
    {
        a[i] = 0x0000FFFF;
        b[i] = 0xFFFF0000;
        c[i] = 0xDEADBEEF;
    }
    a[9] = 0x00000000;
    b[9] = 0x00000000;
    c[9] = 0xDEADBEEF;
    c[10] = 0xDEADBEEF;
    carry = multibyteAddSub!('+')(c[0..10], a[0..10], b[0..10], 0);
    assert(c[0] == 0x0000FFFF);
    for (size_t i = 1; i < 9; i++)
        assert(c[i] == 0x00000000);
    assert(c[9] == 0x00000001);
    assert(c[10] == 0xDEADBEEF);
    assert(carry == 0);


    // Sub
    a[0] = 0xFFFFFFFF;
    b[0] = 0x00000000;
    c[1] = 0xDEADBEEF;
    carry = multibyteAddSub!('-')(c[0..1], a[0..1], b[0..1], 1);
    assert(c[0] == 0xFFFFFFFE);
    assert(c[1] == 0xDEADBEEF);
    assert(carry == 0);

    a[0] = 0xFFFFFFFF;
    b[0] = 0x00000001;
    c[1] = 0xDEADBEEF;
    carry = multibyteAddSub!('-')(c[0..1], a[0..1], b[0..1], 1);
    assert(c[0] == 0xFFFFFFFD);
    assert(c[1] == 0xDEADBEEF);
    assert(carry == 0);
    
    a[0] = 0xC0000000;
    a[1] = 0x7000BEEF;
    b[0] = 0x80000000;
    b[1] = 0x3000BABE;
    c[0] = 0x40000000;
    c[1] = 0x40000431;
    carry = multibyteAddSub!('-')(c[0..2], a[0..2], b[0..2], 0);
    assert(c[0] == 0x40000000);
    assert(c[1] == 0x40000431);
    assert(carry == 0);
}

unittest
{
    uint [] a = new uint[40];
    uint [] b = new uint[40];
    uint [] c = new uint[40];
    for (size_t i = 0; i < a.length; ++i)
    {
        if (i&1) a[i]=cast(uint)(0x8000_0000 + i);
        else a[i]=cast(uint)i;
        b[i]= 0x8000_0003;
    }
    c[19]=0x3333_3333;
    uint carry = multibyteAddSub!('+')(c[0..18], b[0..18], a[0..18], 0);
    assert(c[0]==0x8000_0003);
    assert(c[1]==4);
    assert(c[19]==0x3333_3333); // check for overrun
    assert(carry==1);
    for (size_t i = 0; i < a.length; ++i)
    {
        a[i] = b[i] = c[i] = 0;
    }
    a[8]=0x048D159E;
    b[8]=0x048D159E;
    a[10]=0x1D950C84;
    b[10]=0x1D950C84;
    a[5] =0x44444444;
    carry = multibyteAddSub!('-')(a[0..12], a[0..12], b[0..12], 0);
    assert(a[11] == 0);
    for (size_t i = 0; i < 10; ++i)
        if (i != 5)
            assert(a[i] == 0);

    for (size_t q = 3; q < 36; ++q)
    {
        for (size_t i = 0; i< a.length; ++i)
        {
            a[i] = b[i] = c[i] = 0;
        }
        a[q-2]=0x040000;
        b[q-2]=0x040000;
       carry = multibyteAddSub!('-')(a[0..q], a[0..q], b[0..q], 0);
       assert(a[q-2]==0);
    }
}


/** dest[] += carry, or dest[] -= carry.
 *  op must be '+' or '-'
 *  Returns final carry or borrow (0 or 1)
 */
uint multibyteIncrementAssign(char op)(uint[] dest, uint carry)
    pure @nogc nothrow
{
    static if (op == '+')
    {
        enum ops = "adds";
        enum bcc = "bcc";
    }
    else
    {
        enum ops = "subs";
        enum bcc = "bcs";
    }
    return __asm!uint(`  cmp   $2,0                  @ Check dest.length
                         beq   1f
                         ldr   r6,$1                 @ Load *(dest)
                       `~ops~` r6,r6,$0              @ Add/Sub
                         str   r6,$1                 @ Store *(dest + index)
                         mov   $0,#0                 @ Assume result "carry 0"
                       `~bcc~` 1f
                         cmp   $2,#1
                         beq   2f
                         mov   r5,#1                 @ Initialize index
                       3:
                         ldr   r6,[${1:m},r5,LSL #2] @ Load *(dest + index)
                       `~ops~` r6,r6,#1              @ Add/Sub
                         str   r6,[${1:m},r5,LSL #2] @ Store *(dest + index)
                       `~bcc~` 1f
                         add   r5,r5,#1              @ Increment index
                         cmp   $2,r5
                         bhi   3b
                       2:
                         mov   $0,#1                 @ Result "carry 1"
                       1:`,
                      "=&r,=*m,r,0,~{r5},~{r6},~{cpsr}",
                      dest.ptr, dest.length, carry);
}

unittest
{
    // Some simple checks to validate the interface
    uint carry;
    uint [] a = new uint[40];

    // Add
    a[0] = 0xFFFFFFFE;
    a[1] = 0xDEADBEEF;
    carry = multibyteIncrementAssign!('+')(a[0..1], 1);
    assert(a[0] == 0xFFFFFFFF);
    assert(a[1] == 0xDEADBEEF);
    assert(carry == 0);

    a[0] = 0xFFFFFFFF;
    a[1] = 0xDEADBEEF;
    carry = multibyteIncrementAssign!('+')(a[0..1], 0);
    assert(a[0] == 0xFFFFFFFF);
    assert(a[1] == 0xDEADBEEF);
    assert(carry == 0);

    a[0] = 0xFFFFFFFF;
    a[1] = 0xDEADBEEF;
    carry = multibyteIncrementAssign!('+')(a[0..1], 1);
    assert(a[0] == 0x00000000);
    assert(a[1] == 0xDEADBEEF);
    assert(carry == 1);

    a[0] = 0xFFFFFFFF;
    a[1] = 0x0000FFFF;
    a[2] = 0xDEADBEEF;
    carry = multibyteIncrementAssign!('+')(a[0..2], 1);
    assert(a[0] == 0x00000000);
    assert(a[1] == 0x00010000);
    assert(a[2] == 0xDEADBEEF);
    assert(carry == 0);

    a[0] = 0xFFFFFFFF;
    a[1] = 0xFFFFFFFF;
    a[2] = 0x0000FFFF;
    a[3] = 0xDEADBEEF;
    carry = multibyteIncrementAssign!('+')(a[0..3], 1);
    assert(a[0] == 0x00000000);
    assert(a[1] == 0x00000000);
    assert(a[2] == 0x00010000);
    assert(a[3] == 0xDEADBEEF);
    assert(carry == 0);

    a[0] = 0xFFFFFFFF;
    a[1] = 0xFFFFFFFF;
    a[2] = 0xFFFFFFFF;
    a[3] = 0xDEADBEEF;
    carry = multibyteIncrementAssign!('+')(a[0..3], 1);
    assert(a[0] == 0x00000000);
    assert(a[1] == 0x00000000);
    assert(a[2] == 0x00000000);
    assert(a[3] == 0xDEADBEEF);
    assert(carry == 1);


    // Sub
    a[0] = 0xFFFFFFFF;
    a[1] = 0xDEADBEEF;
    carry = multibyteIncrementAssign!('-')(a[0..1], 1);
    assert(a[0] == 0xFFFFFFFE);
    assert(a[1] == 0xDEADBEEF);
    assert(carry == 0);

    a[0] = 0xFFFFFFFF;
    a[1] = 0xDEADBEEF;
    carry = multibyteIncrementAssign!('-')(a[0..1], 0);
    assert(a[0] == 0xFFFFFFFF);
    assert(a[1] == 0xDEADBEEF);
    assert(carry == 0);

    a[0] = 0x00000000;
    a[1] = 0xDEADBEEF;
    carry = multibyteIncrementAssign!('-')(a[0..1], 1);
    assert(a[0] == 0xFFFFFFFF);
    assert(a[1] == 0xDEADBEEF);
    assert(carry == 1);

    a[0] = 0x00000000;
    a[1] = 0x00000000;
    a[2] = 0xDEADBEEF;
    carry = multibyteIncrementAssign!('-')(a[0..2], 1);
    assert(a[0] == 0xFFFFFFFF);
    assert(a[1] == 0xFFFFFFFF);
    assert(a[2] == 0xDEADBEEF);
    assert(carry == 1);

    a[0] = 0x00000000;
    a[1] = 0x00000000;
    a[2] = 0x00000000;
    a[3] = 0xDEADBEEF;
    carry = multibyteIncrementAssign!('-')(a[0..3], 1);
    assert(a[0] == 0xFFFFFFFF);
    assert(a[1] == 0xFFFFFFFF);
    assert(a[2] == 0xFFFFFFFF);
    assert(a[3] == 0xDEADBEEF);
    assert(carry == 1);

    a[0] = 0x00000000;
    a[1] = 0x00000000;
    a[2] = 0x00000010;
    a[3] = 0xDEADBEEF;
    carry = multibyteIncrementAssign!('-')(a[0..3], 1);
    assert(a[0] == 0xFFFFFFFF);
    assert(a[1] == 0xFFFFFFFF);
    assert(a[2] == 0x0000000F);
    assert(a[3] == 0xDEADBEEF);
    assert(carry == 0);
}

/** dest[] = src[] << numbits
 *  numbits must be in the range 1..31
 */
uint multibyteShl(uint [] dest, const(uint) [] src, uint numbits)
    pure @nogc nothrow
{
    assert(dest.length > 0 && src.length >= dest.length);
    assert(numbits >= 1 && numbits <= 31);
    return __asm!uint(`  mov   $0,#0                 @ result = 0
                         mov   r5,#0                 @ Initialize index
                       1:
                         ldr   r6,[${3:m},r5,LSL #2] @ Load *(src + index)
                         lsl   r7,r6,$4
                         add   r7,r7,$0
                         str   r7,[${1:m},r5,LSL #2] @ Store *(dest + index)
                         lsr   $0,r6,$5
                         add   r5,r5,#1
                         cmp   $2,r5
                         bhi   1b`,
                      "=&r,=*m,r,*m,r,r,~{r5},~{r6},~{r7},~{cpsr}",
                      dest.ptr, dest.length, src.ptr, numbits, 32-numbits);
}


/** dest[] = src[] >> numbits
 *  numbits must be in the range 1..31
 */
void multibyteShr(uint [] dest, const(uint) [] src, uint numbits)
    pure @nogc nothrow
{
    assert(dest.length > 0 && src.length >= dest.length);
    assert(numbits >= 1 && numbits <= 31);
    __asm(`  mov   r0,#0                 @ result = 0
             mov   r5,$1                 @ Initialize index
           1:
             sub   r5,#1
             ldr   r6,[${2:m},r5,LSL #2] @ Load *(src + index)
             lsr   r7,r6,$3
             add   r7,r7,r0
             str   r7,[${0:m},r5,LSL #2] @ Store *(dest + index)
             lsl   r0,r6,$4
             cmp   $1,r5
             bhi   1b`,
          "=*m,r,*m,r,r,~{r0},~{r5},~{r6},~{r7},~{cpsr}",
          dest.ptr, dest.length, src.ptr, numbits, 32-numbits);
}

unittest
{
    uint [] aa = [0x1222_2223, 0x4555_5556, 0x8999_999A, 0xBCCC_CCCD, 0xEEEE_EEEE];
    multibyteShr(aa[0..$-2], aa, 4);
    assert(aa[0] == 0x6122_2222 && aa[1] == 0xA455_5555 && aa[2] == 0x0899_9999);
    assert(aa[3] == 0xBCCC_CCCD);

    aa = [0x1222_2223, 0x4555_5556, 0x8999_999A, 0xBCCC_CCCD, 0xEEEE_EEEE];
    multibyteShr(aa[0..$-1], aa, 4);
    assert(aa[0] == 0x6122_2222 && aa[1] == 0xA455_5555
        && aa[2] == 0xD899_9999 && aa[3] == 0x0BCC_CCCC);

    aa = [0xF0FF_FFFF, 0x1222_2223, 0x4555_5556, 0x8999_999A, 0xBCCC_CCCD,
        0xEEEE_EEEE];
    multibyteShl(aa[1..4], aa[1..$], 4);
    assert(aa[0] == 0xF0FF_FFFF && aa[1] == 0x2222_2230
        && aa[2]==0x5555_5561 && aa[3]==0x9999_99A4 && aa[4]==0x0BCCC_CCCD);
}

/** dest[] = src[] * multiplier + carry.
 * Returns carry.
 */
uint multibyteMul(uint[] dest, const(uint)[] src, uint multiplier, uint carry)
    pure @nogc nothrow
{
    assert(src.length >= dest.length);
    return __asm!uint(`  cmp   $2,#0                 @ Check dest.length
                         beq   1f
                         mov   r5,#0                 @ Initialize index

                         movs  r8,$2,LSR #1          @ Loop unrolled 2 times
                         beq   2f
                         lsl   r8,#1
                       3:
                         mov   r7,#0                 @ Clear high word
                         ldr   r6,[${3:m},r5,LSL #2] @ Load *(src + index)
                         umlal $0,r7,r6,$4           @ r6 * $4 + r7:$0
                         str   $0,[${1:m},r5,LSL #2] @ Store *(dest + index)
                         add   r5,r5,#1
                         mov   $0,#0                 @ Clear high word
                         ldr   r6,[${3:m},r5,LSL #2] @ Load *(src + index)
                         umlal r7,$0,r6,$4           @ r6 * $4 + $0:r7
                         str   r7,[${1:m},r5,LSL #2] @ Store *(dest + index)
                         add   r5,r5,#1
                         cmp   r8,r5
                         bhi   3b
                         cmp   $2,r5
                         beq   1f

                       2:
                         mov   r7,#0                 @ Clear high word
                         ldr   r6,[${3:m},r5,LSL #2] @ Load *(src + index)
                         umlal $0,r7,r6,$4           @ r6 * $4 + r7:$0
                         str   $0,[${1:m},r5,LSL #2] @ Store *(dest + index)
                         mov   $0,r7                 @ Move high word to low word
                         @add   r5,r5,#1
                         @cmp   $2,r5
                         @bhi   2b
                       1:`,
                      "=&r,=*m,r,*m,r,0,~{r5},~{r6},~{r7},~{r8},~{cpsr}",
                      dest.ptr, dest.length, src.ptr, multiplier, carry);
}

unittest
{
    uint [] aa = [0xF0FF_FFFF, 0x1222_2223, 0x4555_5556, 0x8999_999A,
        0xBCCC_CCCD, 0xEEEE_EEEE];
    multibyteMul(aa[1..4], aa[1..4], 16, 0);
    assert(aa[0] == 0xF0FF_FFFF && aa[1] == 0x2222_2230 && aa[2]==0x5555_5561
        && aa[3]==0x9999_99A4 && aa[4]==0x0BCCC_CCCD);
}

/**
 * dest[] += src[] * multiplier + carry(0..FFFF_FFFF).
 * Returns carry out of MSB (0..FFFF_FFFF).
 */
uint multibyteMulAdd(char op)(uint [] dest, const(uint)[] src,
    uint multiplier, uint carry) pure @nogc nothrow
{
    assert(dest.length > 0 && dest.length == src.length);
    static if (op == '+')
    {
        enum adds = "adds";
        enum adc = "adc";
        enum com = "@";
    }
    else
    {
        enum adds = "rsbs";
        enum adc = "rsc";
        enum com = "";
    }
    return __asm!uint(`  mov   r5,#0                 @ Initialize index
                       1:
                         mov   r8,#0                 @ High word of carry r8:$0
                         ldr   r6,[${3:m},r5,LSL #2] @ Load *(src + index)
                         ldr   r7,[${1:m},r5,LSL #2] @ Load *(dest + index)
                         umlal $0,r8,r6,$4           @ r6 * $4 + r8:$0
                       `~adds~` $0,$0,r7
                         str   $0,[${1:m},r5,LSL #2] @ Store *(dest + index)
                       `~adc~` $0,r8,#0
                       `~com~`      rsb $0,$0,#0 @ FIXME: Fold negate into rsc
                         add   r5,r5,#1
                         cmp   $2,r5
                         bhi   1b`,
                      "=r,=*m,r,*m,r,0,~{r5},~{r6},~{r7},~{r8},~{cpsr}",
                      dest.ptr, dest.length, src.ptr, multiplier, carry);
}

unittest
{

    uint [] aa = [0xF0FF_FFFF, 0x1222_2223, 0x4555_5556, 0x8999_999A,
        0xBCCC_CCCD, 0xEEEE_EEEE];
    uint [] bb = [0x1234_1234, 0xF0F0_F0F0, 0x00C0_C0C0, 0xF0F0_F0F0,
        0xC0C0_C0C0];
    multibyteMulAdd!('+')(bb[1..$-1], aa[1..$-2], 16, 5);
    assert(bb[0] == 0x1234_1234 && bb[4] == 0xC0C0_C0C0);
    assert(bb[1] == 0x2222_2230 + 0xF0F0_F0F0 + 5
        && bb[2] == 0x5555_5561 + 0x00C0_C0C0 + 1
        && bb[3] == 0x9999_99A4 + 0xF0F0_F0F0 );
    multibyteMulAdd!('-')(bb[1..$-1], aa[1..$-2], 16, 5);
    assert(bb[0] == 0x1234_1234 && bb[1] == 0xF0F0_F0F0);
    assert(bb[2] == 0x00C0_C0C0 && bb[3] == 0xF0F0_F0F0);
    assert(bb[4] == 0xC0C0_C0C0);
}


/**
   Sets result = result[0..left.length] + left * right

   It is defined in this way to allow cache-efficient multiplication.
   This function is equivalent to:
    ----
    for (size_t i = 0; i< right.length; ++i) {
        dest[left.length + i] = multibyteMulAdd(dest[i..left.length+i],
                left, right[i], 0);
    }
    ----
 */
void multibyteMultiplyAccumulate(uint [] dest, const(uint)[] left, const(uint)
        [] right) pure @nogc nothrow
{
    for (size_t i = 0; i < right.length; ++i)
    {
        dest[left.length + i] = multibyteMulAdd!('+')(dest[i..left.length+i],
                left, right[i], 0);
    }
}

/**  dest[] /= divisor.
 * overflow is the initial remainder, and must be in the range 0..divisor-1.
 */
uint multibyteDivAssign(uint [] dest, uint divisor, uint overflow)
    pure @nogc nothrow
{
    ulong c = cast(ulong)overflow;
    for(ptrdiff_t i = dest.length-1; i>= 0; --i)
    {
        c = (c<<32) + cast(ulong)(dest[i]);
        uint q = cast(uint)(c/divisor);
        c -= divisor * q;
        dest[i] = q;
    }
    return cast(uint)c;
}

unittest
{
    uint [] aa = new uint[101];
    for (uint i = 0; i < aa.length; ++i)
        aa[i] = 0x8765_4321 * (i+3);
    uint overflow = multibyteMul(aa, aa, 0x8EFD_FCFB, 0x33FF_7461);
    uint r = multibyteDivAssign(aa, 0x8EFD_FCFB, overflow);
    for (uint i=0; i<aa.length; ++i)
    {
        assert(aa[i] == 0x8765_4321 * (i+3));
    }
    assert(r == 0x33FF_7461);

}

// Set dest[2*i..2*i+1]+=src[i]*src[i]
void multibyteAddDiagonalSquares(uint[] dest, const(uint)[] src)
    pure @nogc nothrow
{
    assert(dest.length >= 2*src.length);
    __asm(`  cmp   $2,0                  @ Check src.length
             beq   1f
             mov   r5,#0                 @ Initialize index 1
             mov   r6,${0:m}             @ Initialize dest
             mov   r3,#0                 @ Initialize carry lo
             mov   r4,#0                 @ Initialize carry hi
           2:
             ldr   r7,[${1:m},r5,LSL #2] @ Load *(src + index)
             ldr   r8,[r6]               @ Load *(dest + 2*index)
             umlal r3,r4,r7,r7           @ r7 * r7 + r4:r3
             adds  r3,r8
             str   r3,[r6],#4            @ Store *(dest + 2*index)
             ldr   r8,[r6]               @ Load *(dest + 2*index +1)
             adcs  r3,r4,r8
             str   r3,[r6],#4            @ Store *(dest + 2*index + 1)
             mov   r4,#0                 @ Initialize carry hi
             adc   r3,r4,#0              @ Initialize carry lo
             add   r5,r5,#1
             cmp   $2,r5
             bhi   2b
           1:`,
          "=*m,*m,r,~{r3},~{r4},~{r5},~{r6},~{r7},~{r8},~{cpsr}",
          dest.ptr, src.ptr, src.length);
}

// Does half a square multiply. (square = diagonal + 2*triangle)
void multibyteTriangleAccumulate(uint[] dest, const(uint)[] x)
    pure @nogc nothrow
{
    assert(dest.length >= 2*x.length && x.length > 0);
    // x[0]*x[1...$] + x[1]*x[2..$] + ... + x[$-2]x[$-1..$]
    dest[x.length] = multibyteMul(dest[1 .. x.length], x[1..$], x[0], 0);
    if (x.length < 4)
    {
        if (x.length == 3)
        {
            ulong c = cast(ulong)(x[$-1]) * x[$-2]  + dest[2*x.length-3];
            dest[2*x.length - 3] = cast(uint)c;
            c >>= 32;
            dest[2*x.length - 2] = cast(uint)c;
        }
        return;
    }
    for (size_t i = 2; i < x.length - 2; ++i)
    {
        dest[i-1+ x.length] = multibyteMulAdd!('+')(
             dest[i+i-1 .. i+x.length-1], x[i..$], x[i-1], 0);
    }
        // Unroll the last two entries, to reduce loop overhead:
    ulong  c = cast(ulong)(x[$-3]) * x[$-2] + dest[2*x.length-5];
    dest[2*x.length-5] = cast(uint)c;
    c >>= 32;
    c += cast(ulong)(x[$-3]) * x[$-1] + dest[2*x.length-4];
    dest[2*x.length-4] = cast(uint)c;
    c >>= 32;
    c += cast(ulong)(x[$-1]) * x[$-2];
    dest[2*x.length-3] = cast(uint)c;
    c >>= 32;
    dest[2*x.length-2] = cast(uint)c;
}

void multibyteSquare(BigDigit[] result, const(BigDigit) [] x) pure @nogc nothrow
{
    multibyteTriangleAccumulate(result, x);
    result[$-1] = multibyteShl(result[1..$-1], result[1..$-1], 1); // mul by 2
    result[0] = 0;
    multibyteAddDiagonalSquares(result, x);
}

version (unittest)
{
    static import std.internal.math.biguintnoasm;
    import core.stdc.stdio : printf;
    import std.random;

    size_t rndArraySz(size_t sz = maxArraySz)
    {
        return uniform(1, sz);
    }

    immutable tombstone = 0xDEADBEEF;

    void rndNum(uint[] a, size_t sz)
    {
        for (int i = 0; i < sz; i++)
            a[i] = uniform!uint();
        for (int i = sz; i < a.length; i++)
            a[i] = tombstone;
    }

    void initNum(uint[] a)
    {
        for (int i = 0; i < a.length; i++)
            a[i] = tombstone;
    }

    void println(string str, uint[] a)
    {
        printf("%.*s: ", str.length, str.ptr);
        for (size_t i = 0; i < a.length; i++) printf("%08X ", a[i]);
        printf("\n");
    }

    void println(string str, uint[] a, size_t sz)
    {
        printf("%.*s: ", str.length, str.ptr);
        for (size_t i = 0; i < sz; i++) printf("%08X ", a[i]);
        printf("\n");
    }

    immutable loopMax = 100_000;

    immutable size_t maxArraySz = 273;
    uint[] a = new uint[maxArraySz+1];
    uint[] b = new uint[maxArraySz+1];
    uint[] r1 = new uint[maxArraySz+1];
    uint[] r2 = new uint[maxArraySz+1];

    void testMultibyteAddSub()
    {
        for (int j = 0; j < loopMax; j++)
        {
            auto arraySz = rndArraySz();

            rndNum(a, arraySz);
            rndNum(b, arraySz);
            initNum(r1);
            initNum(r2);
            immutable uint carry = uniform(0, 2);
            // Add
            auto c1 = multibyteAddSub!('+')(r1[0..arraySz], a[0..arraySz], b[0..arraySz], carry);
            auto c2 = std.internal.math.biguintnoasm.multibyteAddSub!('+')(r2[0..arraySz], a[0..arraySz], b[0..arraySz], carry);
            assert(r1[0..arraySz] == r2[0..arraySz]);
            assert(c1 == c2);
            assert(c1 == 0 || c1 == 1);
            assert(a[arraySz] == tombstone);
            assert(b[arraySz] == tombstone);
            assert(r1[arraySz] == tombstone);
            assert(r2[arraySz] == tombstone);
            // Sub
            c1 = multibyteAddSub!('-')(r1[0..arraySz], a[0..arraySz], b[0..arraySz], carry);
            c2 = std.internal.math.biguintnoasm.multibyteAddSub!('-')(r2[0..arraySz], a[0..arraySz], b[0..arraySz], carry);
            assert(r1[0..arraySz] == r2[0..arraySz]);
            assert(c1 == c2);
            assert(c1 == 0 || c1 == 1);
            assert(a[arraySz] == tombstone);
            assert(b[arraySz] == tombstone);
            assert(r1[arraySz] == tombstone);
            assert(r2[arraySz] == tombstone);
        }
    }

    void testMultibyteIncrementAssign()
    {
            auto arraySz = rndArraySz();

            rndNum(r1, arraySz);
            a[] = r1[];
            b[] = r1[];
            immutable uint carry = uniform!uint();
            // Add
            auto c1 = multibyteIncrementAssign!('+')(a[0..arraySz], carry);
            auto c2 = std.internal.math.biguintnoasm.multibyteIncrementAssign!('+')(b[0..arraySz], carry);
            assert(a[0..arraySz] == b[0..arraySz]);
            assert(c1 == c2);
            assert(c1 == 0 || c1 == 1);
            assert(a[arraySz] == tombstone);
            assert(b[arraySz] == tombstone);
            // Sub
            a[] = r1[];
            b[] = r1[];
            c1 = multibyteIncrementAssign!('-')(a[0..arraySz], carry);
            c2 = std.internal.math.biguintnoasm.multibyteIncrementAssign!('-')(b[0..arraySz], carry);
            assert(a[0..arraySz] == b[0..arraySz]);
            assert(c1 == c2);
            assert(c1 == 0 || c1 == 1);
            assert(a[arraySz] == tombstone);
            assert(b[arraySz] == tombstone);
    }

    void testMultibyteShl()
    {
        for (int i = 0; i < loopMax; i++)
        {
            auto arraySz = rndArraySz();

            rndNum(a, arraySz);
            initNum(r1);
            initNum(r2);
            immutable uint shift = uniform(1, 32);
            auto sh1 = multibyteShl(r1[0..arraySz], a[0..arraySz], shift);
            auto sh2 = std.internal.math.biguintnoasm.multibyteShl(r2[0..arraySz], a[0..arraySz], shift);
            assert(r1[0..arraySz] == r2[0..arraySz]);
            assert(sh1 == sh2);
            assert(a[arraySz] == tombstone);
            assert(r1[arraySz] == tombstone);
            assert(r2[arraySz] == tombstone);
        }
    }

    void testMultibyteShr()
    {
        for (int i = 0; i < loopMax; i++)
        {
            auto arraySz = rndArraySz();

            rndNum(a, arraySz);
            initNum(r1);
            initNum(r2);
            immutable uint shift = uniform(1, 32);
            multibyteShr(r1[0..arraySz], a[0..arraySz], shift);
            std.internal.math.biguintnoasm.multibyteShr(r2[0..arraySz], a[0..arraySz], shift);
            assert(r1[0..arraySz] == r2[0..arraySz]);
            assert(a[arraySz] == tombstone);
            assert(r1[arraySz] == tombstone);
            assert(r2[arraySz] == tombstone);
        }
    }

    void testMultibyteMul()
    {
        for (int i = 0; i < loopMax; i++)
        {
            auto arraySz = rndArraySz();

            rndNum(a, arraySz);
            initNum(r1);
            initNum(r2);
            immutable uint mult = uniform!uint();
            immutable uint carry = uniform(0, 2);
            auto c1 = multibyteMul(r1[0..arraySz], a[0..arraySz], mult, carry);
            auto c2 = std.internal.math.biguintnoasm.multibyteMul(r2[0..arraySz], a[0..arraySz], mult, carry);
            assert(r1[0..arraySz] == r2[0..arraySz]);
            assert(c1 == c2);
            assert(a[arraySz] == tombstone);
            assert(r1[arraySz] == tombstone);
            assert(r2[arraySz] == tombstone);
        }
    }

    void testMultibyteMulAdd()
    {
        for (int i = 0; i < loopMax; i++)
        {
            auto arraySz = rndArraySz();

            rndNum(a, arraySz);
            initNum(r1);
            initNum(r2);
            immutable uint mult = uniform!uint();
            immutable uint carry = uniform(0, 2);
            // Add
            auto c1 = multibyteMulAdd!('+')(r1[0..arraySz], a[0..arraySz], mult, carry);
            auto c2 = std.internal.math.biguintnoasm.multibyteMulAdd!('+')(r2[0..arraySz], a[0..arraySz], mult, carry);
            assert(r1[0..arraySz] == r2[0..arraySz]);
            assert(c1 == c2);
            assert(a[arraySz] == tombstone);
            assert(r1[arraySz] == tombstone);
            assert(r2[arraySz] == tombstone);
            // Sub
            c1 = multibyteMulAdd!('-')(r1[0..arraySz], a[0..arraySz], mult, carry);
            c2 = std.internal.math.biguintnoasm.multibyteMulAdd!('-')(r2[0..arraySz], a[0..arraySz], mult, carry);
            assert(r1[0..arraySz] == r2[0..arraySz]);
            assert(c1 == c2);
            assert(a[arraySz] == tombstone);
            assert(r1[arraySz] == tombstone);
            assert(r2[arraySz] == tombstone);
        }
    }

    void testMultibyteAddDiagonalSquares()
    {
        for (int i = 0; i < loopMax; i++)
        {
            auto arraySz = rndArraySz(maxArraySz/2);

            rndNum(a, arraySz);
            initNum(r1);
            initNum(r2);
            multibyteAddDiagonalSquares(r1, a[0..arraySz]);
            std.internal.math.biguintnoasm.multibyteAddDiagonalSquares(r2, a[0..arraySz]);
            assert(r1[0..2*arraySz] == r2[0..2*arraySz]);
            assert(a[arraySz] == tombstone);
            assert(r1[2*arraySz+1] == tombstone);
            assert(r2[2*arraySz+1] == tombstone);
        }
    }

    unittest
    {
        testMultibyteAddSub();
        testMultibyteIncrementAssign();
        testMultibyteShl();
        testMultibyteShr();
        testMultibyteMul();
        testMultibyteMulAdd();
        testMultibyteAddDiagonalSquares();
    }
}
//version = timings;
version (timings)
{
    static import std.internal.math.biguintnoasm;
    import core.stdc.stdio : printf;
    import core.time : TickDuration;
    import std.datetime : StopWatch;
    import std.random;

    void report(string name, TickDuration time1, TickDuration time2)
    {
        printf("Result for %.*s: Speedup = %.4f\n", name.length, name.ptr, cast(float)time2.hnsecs / cast(float)time1.hnsecs);
        printf("Opt:  %lld usec %lld nsec\n", cast(ulong)time1.usecs, cast(ulong)time1.hnsecs);
        printf("Base: %lld usec %lld nsec\n", cast(ulong)time2.usecs, cast(ulong)time2.hnsecs);
    }

    void main()
    {
        StopWatch sw;
        immutable size_t loopCount = 10_000;
        immutable size_t arraySz = 380;
        immutable size_t dataSz = 1000;
        uint[][] data = new uint[][dataSz];
        foreach (ref d; data)
        {
            d = new uint[arraySz];
            foreach (ref i; d) i = uniform!uint();
        }
        uint[] r = new uint[arraySz];

        // Warm-up
        for (size_t i = 0; i < dataSz; i +=2)
        {
            auto c1 = multibyteAddSub!('+')(r, data[i], data[i+1], 0);
        }
        // Time
        sw.start();
        for (size_t j = 0; j < loopCount; j++)
        {
            for (size_t i = 0; i < dataSz; i +=2)
            {
                auto c1 = multibyteAddSub!('+')(r, data[i], data[i+1], 0);
            }
        }
        sw.stop();
        auto time1 = sw.peek();

        // Warm-up
        for (size_t i = 0; i < dataSz; i +=2)
        {
            auto c1 = std.internal.math.biguintnoasm.multibyteAddSub!('+')(r, data[i], data[i+1], 0);
        }
        // Time
        sw.start();
        for (size_t j = 0; j < loopCount; j++)
        {
            for (size_t i = 0; i < dataSz; i +=2)
            {
                auto c1 = std.internal.math.biguintnoasm.multibyteAddSub!('+')(r, data[i], data[i+1], 0);
            }
        }
        sw.stop();
        auto time2 = sw.peek();

        // Print result
        report("multibyteAddSub!('+')", time1, time2);

        // Warm-up
        for (size_t i = 0; i < dataSz; i +=2)
        {
            auto c1 = multibyteMul(r, data[i], 17, 0);
        }
        // Time
        sw.start();
        for (size_t j = 0; j < loopCount; j++)
        {
            for (size_t i = 0; i < dataSz; i +=2)
            {
                auto c1 = multibyteMul(r, data[i], 17, 0);
            }
        }
        sw.stop();
        auto time3 = sw.peek();

        // Warm-up
        for (size_t i = 0; i < dataSz; i +=2)
        {
            auto c1 = std.internal.math.biguintnoasm.multibyteMul(r, data[i], 17, 0);
        }
        // Time
        sw.start();
        for (size_t j = 0; j < loopCount; j++)
        {
            for (size_t i = 0; i < dataSz; i +=2)
            {
                auto c1 = std.internal.math.biguintnoasm.multibyteMul(r, data[i], 17, 0);
            }
        }
        sw.stop();
        auto time4 = sw.peek();

        // Print result
        report("multibyteMul", time3, time4);

        // Warm-up
        for (size_t i = 0; i < dataSz; i +=2)
        {
            auto c1 = multibyteMulAdd!('+')(r, data[i], 17, 0);
        }
        // Time
        sw.start();
        for (size_t j = 0; j < loopCount; j++)
        {
            r[] = 0;
            for (size_t i = 0; i < dataSz; i +=2)
            {
                auto c1 = multibyteMulAdd!('+')(r, data[i], 17, 0);
            }
        }
        sw.stop();
        auto time5 = sw.peek();

        // Warm-up
        for (size_t i = 0; i < dataSz; i +=2)
        {
            auto c1 = std.internal.math.biguintnoasm.multibyteMulAdd!('+')(r, data[i], 17, 0);
        }
        // Time
        sw.start();
        for (size_t j = 0; j < loopCount; j++)
        {
            r[] = 0;
            for (size_t i = 0; i < dataSz; i +=2)
            {
                auto c1 = std.internal.math.biguintnoasm.multibyteMulAdd!('+')(r, data[i], 17, 0);
            }
        }
        sw.stop();
        auto time6 = sw.peek();

        // Print result
        report("multibyteMulAdd!('+')", time5, time6);
    }
}
