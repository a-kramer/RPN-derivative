# Source Modules

The source files are organized into parts described by the subsections
below. Any part that is shared between the binaries produced by the
[Makefile](../Makefile) is put into one of these modules.

The list implementation used here is _linked lists_, the _symbols_ are structs
with no nested allocations. 


## (Reverse) Polish Notation

Reverse Polish Notation (rpn) is most useful for evaluating and
expression (list of symbols), while Polish notation (pn) is useful for
calculating derivatives. 

An rpn expression starts with operands (numbers and
variables) and ends with operators and functions.

An example is: `2 3 +`. This type of expression is what `dc` expects as input:
```bash
$ dc -e '2 3 + p'
5
```
where `p` means _print_.

Because derivatives and simplification happen backwards (I don't know
of another way), we have to reverse lists of symbols some times,
switching back and forth between Polish and reverse Polish notation.

For derivatives, we first look at the operator (`+`) and then the
operands it affects. To understand what an operator affects we
calculate it's _depth_. The depth of `2 3 +` is 2, because 2 symbols
to the right are affected by the `+` operator. The depth of `+` in `1
2 3 * +` is 4, while the depth of `*` is 2.

Most importantly: `derivative()`, `simplify()`, `depth()` need Polish
notation. 

Many of the functions don't need to know the contents of the
expression lists, e.g. `rpn_print()`, but they retain the _rpn_ prefix
of the module they are in.

## Symbol

Symbols are structs that store at least the _type_ of the symbol and
the number of arguments _nargs_ that type of symbol can
affect. Numbers and variables have no arguments, so _nargs_ is 0.

The further contents of the struct describe more specific properties
of the symbol: numbers have a _value_, variables have a _name_.

In all cases the contents of the struct don't point to external
locations, so `free()`, `memcpy()`, and `memcmp()` can be used with
symbols.

## Linked List

Linked lists are not very fast, and we do need the symbol lists in
reversed order at times.
 
So, it may be better to implement the lists as doubly linked lists for
convenience.  But, it is important to note here, that neither singly
linked lists, nor doubly linked lists are very fast and the code
itself is not written for performance. Rather, I would like to keep it
as simple as I can make it.

It seems difficult to me to use arrays instead of linked lists,
because the expressions frequently need to be disassembled. But, it's
not impossible. 

So, if performance becomes a concern, then an array of symbols may be
much better.
