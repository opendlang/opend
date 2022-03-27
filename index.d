Ddoc

$(P Ion, JSON, MsgPack Parsing and Serialization library.)

$(P The following table is a quick reference guide for which Mir Ion modules to
use for a given category of functionality.)


$(BOOKTABLE ,
    $(TR
        $(TH Modules)
        $(TH Description)
    )
    $(LEADINGROW Conversion API)
    $(TR $(TDNW $(MREF mir,ion,conv)) $(TD Conversion between binary $(LINL2 https://amzn.github.io/ion-docs/, Ion) and other formats. ))
    $(LEADINGROW Serialization API)
    $(TR $(TDNW $(MREF mir,ser)) $(TD Custom serialization API ))
    $(TR $(TDNW $(MREF mir,ser,ion)) $(TD $(LINL2 https://amzn.github.io/ion-docs/, Amazon Ion) serialization to a binary form ))
    $(TR $(TDNW $(MREF mir,ser,text)) $(TD $(LINL2 https://amzn.github.io/ion-docs/, Amazon Ion) serialization to a text form ))
    $(TR $(TDNW $(MREF mir,ser,json)) $(TD JSON serialization ))
    $(TR $(TDNW $(MREF mir,ser,msgpack)) $(TD MsgPack serialization ))
    $(TR $(TDNW $(MREF mir,ser,interfaces)) $(TD Unified interface for serialization ))
    $(LEADINGROW Deserialization API)
    $(TR $(TDNW $(MREF mir,ser)) $(TD Custom deserialization API ))
    $(TR $(TDNW $(MREF mir,ser,ion)) $(TD $(LINL2 https://amzn.github.io/ion-docs/, Amazon Ion) deserialization from a binary form ))
    $(TR $(TDNW $(MREF mir,ser,text)) $(TD $(LINL2 https://amzn.github.io/ion-docs/, Amazon Ion) deserialization from a text form ))
    $(TR $(TDNW $(MREF mir,ser,json)) $(TD JSON deserialization ))
    $(TR $(TDNW $(MREF mir,ser,msgpack)) $(TD MsgPack deserialization ))
    $(LEADINGROW Algebraic API)
    $(TR $(TDNW $(MREF mir,ion,conv)) $(TD Conversion between binary $(LINL2 https://amzn.github.io/ion-docs/, Ion) and other formats. ))
    $(LEADINGROW Examples)
    $(TR $(TDNW $(MREF mir,ion,examples)) $(TD Set of ))
    $(LEADINGROW Low level Ion API)
    $(TR $(TDNW $(MREF mir,ion,exception)) $(TD Mir Ion Exceptions ))
    $(TR $(TDNW $(MREF mir,ion,tape)) $(TD Ion low-level output API ))
    $(TR $(TDNW $(MREF mir,ion,type_code)) $(TD Ion Type Code ))
    $(TR $(TDNW $(MREF mir,ion,value)) $(TD Ion Value ))
    $(TR $(TDNW $(MREF mir,ion,stream)) $(TD Ion Value Stream))
    $(TR $(TDNW $(MREF mir,ion,symbol_table)) $(TD Ion Symbol Table utilities))
)

Macros:
        TITLE=Mir Ion
        WIKI=Mir Ion
        DDOC_BLANKLINE=
        _=
