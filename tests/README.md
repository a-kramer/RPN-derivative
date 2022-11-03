# Testing

The script [test.sh](./test.sh) performs some high level tests, where
`derivative`, `to_rpn`, `to_infix`, and `simplify` are supplied string
inputs with known results or easy to calculate results. These high
level tests are written as shell commands.

There is also a lower level test that tests the linked list
functions. This test is written in c.

The normal way to run the tests is to be in the uppmost directory of this repository and execute:

```sh
$ make
$ make test
$ sudo make install # if tests have been successful
```

todo: `make test` should return a non-zero exit status if a failure has occurred.

## Low Level Tests

The file [ll_test.c](./ll_test.c) contains the test calls, once compiled it produced an output like this:
```sh
[...]/tests$ ./ll_test
test:                                 ll_push and ll_pop	success
test:              second ll_pop retrieves te next value	success
test:                          ll_append() appends value	success
test:           a subsequent ll_pop gets the right value	success
test:                    ll_cat() concatenates two lists	success
test:                        ll_cat(a,NULL) does nothing	success
test:                    a=NULL, ll_cat(&a,b) makes a==b	success
test:                       ll_reverse() reverses a list	success
test:                             ll_free() empties list	success
h0: 4
h1: 0
h2: 2
h3: 3
test:                        ll_hash works for [0,1,2,3]	success
test:       ll_cut() cuts the list in the expected place	success
[A] [B] [C]
[A] [_] [C]
test: ll_rm() removes a sub-list and can be used to insert	success
```

This test series is automatically called in the high level test.

It is currently not very well organised. TODO: split all tests into functions.

## High Level Tests

The script [test.sh](./test.sh) currently has to be called from the
repositorie's root directory, because the locally compiled binaries in
the bin folder are tested and the relative path is hard-coded into the test.

The script first calls the low level test, then tests the binaries.

The high level test produces and output like this:

```sh
[...]/RPN-derivative$ tests/test.sh
# omitted: results of low-level test (see above)

binaries
========

(1) compare to known solutions

                               TEST                     RESULT            EXPECTED RESULT
                   simplify 'x 0 *'                          0                          0   success
               simplify 'x 1 * 0 +'                          x                          x   success
         simplify 'x 0 * @sin @cos'                          1                          1   success
    derivative of '-1 a * t * @exp'   -1 a * t * @exp -1 a * *   -1 a * t * @exp -1 a * *   success
      derivative of 'x y *' w.r.t y              0 y * x 1 * +              0 y * x 1 * +   success
       missing newline byte is fine              0 y * x 1 * +              0 y * x 1 * +   success
     input can be without operators                          x                          x   success
                       rpn of 'a+b'                      a b +                      a b +   success
              rpn of '@exp(-1*a*t)'            -1 a * t * @exp            -1 a * t * @exp   success
                       rpn of ' a '                          a                          a   success
                   'a b +' as infix                      (a+b)                      (a+b)   success
           'a b + a b - /' as infix              ((a+b)/(a-b))              ((a+b)/(a-b))   success
            'a b - 2 @pow' as infix               pow((a-b),2)               pow((a-b),2)   success

(2) compare to numerical solutions via 'dc'
    /usr/bin/dc
    math functions cannot be used
    only operators: * + - / ^

                               TEST                 DERIVATIVE         FINITE DIFFERENCES
         '-1 a * t 3 @pow *' at t=3              -2.7000000000              -2.7000005000     0% error
         't t * a t t * + /' at t=3                .0600000000                .0600000500     0% error
          taylor(@exp,t,4) at t=0.1               1.1051666666               1.1051668500     0% error

(3a) compare to numerical solutions via 'octave'
     /usr/bin/octave
     math functions are allowed
     conversion to infix notation required
                               TEST                 DERIVATIVE         FINITE DIFFERENCES
 @exp(-0.5*@pow(x-m,2)/(s*s)) | x=2                  -0.715365                  -0.715365     0% error

(3b) compare to numerical solutions via 'R'
     /usr/bin/Rscript
     math functions are allowed
     conversion to infix notation required
                               TEST                 DERIVATIVE         FINITE DIFFERENCES
 @exp(-0.5*@pow(x-m,2)/(s*s)) | x=2                  -0.715365                  -0.715365     0% error

```

todo: make the script flexible with regard to where it is called from.
