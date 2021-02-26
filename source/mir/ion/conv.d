///
module mir.ion.conv;

import mir.ion.exception;
import mir.ion.value;
import mir.ion.type_code;

/++
WIP
+/
version(none)
IonErrorCode ionGetFlexible(IonDescribedValue value, scope ref bool result)
    @safe pure nothrow @nogc
{
    if (value.descriptor.L == 0xF)
    {
        result = false;
        return IonErrorCode.none;
    }
Switch:
    // final
    switch (value.descriptor.type)
    {
        case IonTypeCode.null_:
            return IonErrorCode.nop;
        case IonTypeCode.bool_:
            result = IonBool(value.descriptor).get;
            return IonErrorCode.none;
        case IonTypeCode.uInt:
        case IonTypeCode.nInt:
        case IonTypeCode.float_:
            result = checkData(value.data);
            return IonErrorCode.none;
        case IonTypeCode.decimal:
        {
            IonDescribedDecimal decimal;
            if (auto error = value.trustedGet!IonDecimal.get(decimal))
                return error;
            result = checkData(decimal.coefficient.data);
            return IonErrorCode.none;
        }
        // case IonTypeCode.timestamp:
        // case IonTypeCode.symbol:
        // case IonTypeCode.string:
        // case IonTypeCode.clob:
        // case IonTypeCode.blob:
        // case IonTypeCode.list:
        // case IonTypeCode.sexp:
        // case IonTypeCode.struct_:
        default:
            result = true;
            return IonErrorCode.none;
        case IonTypeCode.annotations:
            IonAnnotations annotations;
            if (auto error = value.trustedGet!IonAnnotationWrapper.unwrap(annotations, value))
                return error;
            goto Switch;
    }
}

private bool checkData(scope const ubyte[] data)
    @safe pure nothrow @nogc
{
    pragma(inline, false);
    foreach(d; data)
        if (d)
            return true;
    return false;
}
