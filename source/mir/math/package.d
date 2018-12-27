/++
$(H1 Math Functionality)
$(BOOKTABLE $(H2 ,Math modules),
$(TR $(TH Module) $(TH Math kind))
$(T2M common, Common math functions)
$(T2M constant, Constants)
)
Copyright: Ilya Yaroshenko, Kaleidic Associates Advisory Limited
Authors: Ilya Yaroshenko
Macros:
SUBREF = $(REF_ALTTEXT $(TT $2), $2, mir, math, $1)$(NBSP)
T2M=$(TR $(TDNW $(MREF mir,math,$1)) $(TD $+))
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
+/
module mir.math;

public import mir.math.common;
public import mir.math.constant;
public import mir.math.ieee;
