/*
ARG_SETS: -revert=?
ARG_SETS: -revert=h
TEST_OUTPUT:
----
Revertable language changes listed by -revert=name:
  =all              Enables all available revertable language changes
  =dip25            revert DIP25 changes https://github.com/dlang/DIPs/blob/master/DIPs/archive/DIP25.md [DEPRECATED]
  =dip1000          revert DIP1000 changes https://github.com/dlang/DIPs/blob/master/DIPs/other/DIP1000.md (Scoped Pointers)
  =intpromote       revert integral promotions for unary + - ~ operators
  =dtorfields       don't destruct fields of partially constructed objects
  =fieldwise        don't use fieldwise comparisons for struct equality (https://dlang.org/changelog/2.085.0.html#no-cmpsb)
----
*/
