/++
+/
module mir.ion.lob;

/++
Ion Clob

Values of type clob are encoded as a sequence of octets that should be interpreted as text
with an unknown encoding (and thus opaque to the application).
+/
struct IonClob
{
    ///
    const(char)[] data;
}

///
@safe pure
version(mir_ion_test) unittest
{
    import mir.ion.type_code;
    import mir.ion.value;
    // null.string
    assert(IonValue([0x9F]).describe.get!IonNull == IonNull(IonTypeCode.clob));
    // empty string
    assert(IonValue([0x90]).describe.get!IonClob.data == "");

    assert(IonValue([0x95, 0x63, 0x6f, 0x76, 0x69, 0x64]).describe.get!IonClob.data == "covid");
}

/++
Ion Blob

This is a sequence of octets with no interpretation (and thus opaque to the application).
+/
struct IonBlob
{
    ///
    const(ubyte)[] data;
}

///
@safe pure
version(mir_ion_test) unittest
{
    import mir.ion.type_code;
    import mir.ion.value;
    // null.string
    assert(IonValue([0xAF]).describe.get!IonNull == IonNull(IonTypeCode.blob));
    // empty string
    assert(IonValue([0xA0]).describe.get!IonBlob.data == "");

    assert(IonValue([0xA5, 0x63, 0x6f, 0x76, 0x69, 0x64]).describe.get!IonBlob.data == "covid");
}
