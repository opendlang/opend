/++
Ion Timestamp
+/
module mir.ion.timestamp;

/++
Ion Timestamp

Note: The component values in the binary encoding are always in UTC, while components in the text encoding are in the local time!
This means that transcoding requires a conversion between UTC and local time.

`IonTimestamp` precision is up to `10^-12` seconds;
+/
struct IonTimestamp
{
    ///
    enum Precision : ubyte
    {
        ///
        year,
        ///
        month,
        ///
        day,
        ///
        minute,
        ///
        second,
        ///
        fraction,
    }

    /++
    The offset denotes the local-offset portion of the timestamp, in minutes difference from UTC.
    +/
    short offset;
    /++
    Year
    +/
    ushort year;
    /++
    +/
    Precision precision;

    /++
    Month
    
    If the value equals to thero then this and all the following members are undefined.
    +/
    ubyte month;
    /++
    Day
    
    If the value equals to thero then this and all the following members are undefined.
    +/
    ubyte day;
    /++
    Hour
    +/
    ubyte hour;

    version(D_Ddoc)
    {
    
        /++
        Minute

        Note: the field is implemented as property.
        +/
        ubyte minute;
        /++
        Second

        Note: the field is implemented as property.
        +/
        ubyte second;
        /++
        Fraction

        The `fraction_exponent` and `fraction_coefficient` denote the fractional seconds of the timestamp as a decimal value
        The fractional seconds’ value is `coefficient * 10 ^ exponent`.
        It must be greater than or equal to zero and less than 1.
        A missing coefficient defaults to zero.
        Fractions whose coefficient is zero and exponent is greater than -1 are ignored.
        
        'fractionCoefficient' allowed values are [0 ... 10^12-1].
        'fractionExponent' allowed values are [-12 ... 0].

        Note: the fields are implemented as property.
        +/
        byte fractionExponent;
        /// ditto
        long fractionCoefficient;
    }
    else
    {
        import mir.bitmanip: bitfields;
        version (LittleEndian)
        {

            mixin(bitfields!(
                    ubyte, "minute", 8,
                    ubyte, "second", 8,
                    byte, "fractionExponent", 8,
                    long, "fractionCoefficient", 40,
            ));
        }
        else
        {
            mixin(bitfields!(
                    long, "fractionCoefficient", 40,
                    byte, "fractionExponent", 8,
                    ubyte, "second", 8,
                    ubyte, "minute", 8,
            ));
        }
    }

    ///
    @safe pure nothrow @nogc
    this(ushort year)
    {
        this.year = year;
        this.precision = Precision.year;
    }

    ///
    @safe pure nothrow @nogc
    this(ushort year, ubyte month)
    {
        this.year = year;
        this.month = month;
        this.precision = Precision.month;
    }

    ///
    @safe pure nothrow @nogc
    this(ushort year, ubyte month, ubyte day)
    {
        this.year = year;
        this.month = month;
        this.day = day;
        this.precision = Precision.day;
    }

    ///
    @safe pure nothrow @nogc
    this(ushort year, ubyte month, ubyte day, ubyte hour, ubyte minute)
    {
        this.year = year;
        this.month = month;
        this.day = day;
        this.hour = hour;
        this.minute = minute;
        this.precision = Precision.minute;
    }

    ///
    @safe pure nothrow @nogc
    this(ushort year, ubyte month, ubyte day, ubyte hour, ubyte minute, ubyte second)
    {
        this.year = year;
        this.month = month;
        this.day = day;
        this.hour = hour;
        this.day = day;
        this.minute = minute;
        this.second = second;
        this.precision = Precision.second;
    }

    ///
    @safe pure nothrow @nogc
    this(ushort year, ubyte month, ubyte day, ubyte hour, ubyte minute, ubyte second, byte fractionExponent, ulong fractionCoefficient)
    {
        this.year = year;
        this.month = month;
        this.day = day;
        this.hour = hour;
        this.day = day;
        this.minute = minute;
        this.second = second;
        assert(fractionExponent < 0);
        this.fractionExponent = fractionExponent;
        this.fractionCoefficient = fractionCoefficient;
        this.precision = Precision.fraction;
    }

    ///
    @safe pure nothrow @nogc const
    IonTimestamp withOffset(short offset)
    {
        IonTimestamp ret = this;
        ret.offset = offset;
        return ret;
    }
}
