/++
$(H4 High level Msgpack deserialization API)

This module requires msgpack-d package.

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.deser.msgpack;

version(Have_msgpack_d)
{
    /++
    +/
    T deserializeMsgpack(T)(scope const(ubyte)[] data)
    {
        import mir.ion.conv: serde;
        import msgpack: unpack;
        return data.unpack.value.serde!T;
    }

    version(mir_ion_test)
    unittest
    {
        static struct S
        {
            bool compact;
            int schema;
        }
        const ubyte[] data = [0x82, 0xa7, 0x63, 0x6f, 0x6d, 0x70, 0x61, 0x63, 0x74, 0xc3, 0xa6, 0x73, 0x63, 0x68, 0x65, 0x6d, 0x61, 0x04];
        assert(data.deserializeMsgpack!S == S(true, 4));
    }
}
else
version(D_Ddoc)
{
    /++
    +/
    T deserializeMsgpack(T)(scope const(ubyte)[] data){}
}
