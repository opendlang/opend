# Custom Serialization Formats

mir-ion can be used as generic (de)serialization framework for structured file formats. It handles things such as mapping structs / user-defined types to serializer method calls as well as processing annotations for custom field names, ignoring fields, handling properties, etc. This way users can use the same standard `mir.serde` annotations on all custom type definitions.

Users can define custom structures like these:

```d
struct Transaction
{
	bool confirmed;
	string iban;
	long txValue;
}

struct Account
{
	string iban;
	string accountHolder;
	Transaction[] transactions;
}
```

It's possible to convert these types to and from generic structured file formats like JSON, CSV, YAML, etc. when there are (de)serializers available.

```d
import std;
import mir.ser.json;

Account account = {
	iban: "DE00123456789",
	accountHolder: "Max Mustermann",
	transactions: [
		Transaction(true, "DE00987654321", 123_45),
		Transaction(true, "DE00987654322", -45_11),
		Transaction(false, "DE00987654323", -12_87),
	]
};

/*
{
	"iban": "DE00123456789",
	"accountHolder": "Max Mustermann",
	"transactions": [
		{
			"confirmed": true,
			"iban": "DE00987654321",
			"txValue": 12345
		},
		{
			"confirmed": true,
			"iban": "DE00987654322",
			"txValue": -4511
		},
		{
			"confirmed": false,
			"iban": "DE00987654323",
			"txValue": -1287
		}
	]
}
*/
writeln(account.serializeJsonPretty);
```

Without mir-ion you would normally need to implement going over all the fields of a type using compile time introspection. Using mir-ion helps you avoid such repetitive tasks and defines a common interface to do both serialization and deserialization as well as giving the user a lot of control over those.

## Serialization

Writing custom serializers is probably going to be the easier part, depending on your output format. In this tutorial we will start by writing a custom transaction serializer that would output the above struct in the following format:

```
iban:DE00123456789
accountHolder:Max Mustermann
transactions:
- ✓	DE00987654321	+12345
- ✓	DE00987654322	-4511
- ✗	DE00987654323	-1287
```

Generally a mir-ion serializer is most useful if it doesn't assume too much on the output format and uses what the user defines in their type model. This hypothetical model directly prints keys and values, separated by a colon. When inside an array, it switches to a column based output.

Serializers in mir-ion work by calling serialization functions such as `putKey` and `putValue` on your own custom struct or class implementing the [`ISerializer`](../source/mir/ser/interfaces.d) interface.

To call a custom serializer you use

```d disabled
import mir.ser;

MySerializer serializer = ...;
serializeValue(serializer, account);
// user expected to extract data from serializer somehow, or serializer directly writing into a file, etc.
```

and with this for the value above, the following functions are called on `serializer` through the `serializeValue` function:

```d disabled
serializer.structBegin(size_t.max);
	serializer.putKey("iban");
	serializer.putValue("DE00123456789");

	serializer.putKey("accountHolder");
	serializer.putValue("Max Mustermann");

	serializer.putKey("transactions");
	serializer.listBegin(size_t.max);
		serializer.elemBegin();
			serializer.structBegin(size_t.max);
				serializer.putKey("confirmed");
				serializer.putValue(true);

				serializer.putKey("iban");
				serializer.putValue("DE00987654321");

				serializer.putKey("txValue");
				serializer.putValue(12345);
			serializer.structEnd(0);
		serializer.elemBegin();
			serializer.structBegin(size_t.max);
				serializer.putKey("confirmed");
				serializer.putValue(true);

				serializer.putKey("iban");
				serializer.putValue("DE00987654322");

				serializer.putKey("txValue");
				serializer.putValue(-4511);
			serializer.structEnd(0);
		serializer.elemBegin();
			serializer.structBegin(size_t.max);
				serializer.putKey("confirmed");
				serializer.putValue(false);

				serializer.putKey("iban");
				serializer.putValue("DE00987654323");

				serializer.putKey("txValue");
				serializer.putValue(-1287);
			serializer.structEnd(0);
	serializer.listEnd(0);
serializer.structEnd(0);
```

(whitespace added for readability)

<details>

<summary>Debug serializer showing this kind of output</summary>

```d
// debug serializer, prints each method call, doesn't output anything
import mir.ser;
import mir.bignum.decimal: Decimal;
import mir.bignum.integer: BigInt;
import mir.lob: Blob, Clob;
import mir.timestamp: Timestamp;
import mir.ion.type_code : IonTypeCode;

struct DebugSerializer
{
	private enum definedMethods = [
		"void putStringPart(scope const(char)[] value)",
		"void stringEnd(size_t state)",
		"size_t structBegin(size_t length = size_t.max)",
		"void structEnd(size_t state)",
		"size_t listBegin(size_t length = size_t.max)",
		"void listEnd(size_t state)",
		"size_t sexpBegin(size_t length = size_t.max)",
		"void sexpEnd(size_t state)",
		"void putSymbol(scope const char[] symbol)",
		"void putAnnotation(scope const(char)[] annotation)",
		"size_t annotationsEnd(size_t state)",
		"size_t annotationWrapperBegin()",
		"void annotationWrapperEnd(size_t annotationsState, size_t state)",
		"void nextTopLevelValue()",
		"void putKey(scope const char[] key)",
		"void putValue(long value)",
		"void putValue(ulong value)",
		"void putValue(float value)",
		"void putValue(double value)",
		"void putValue(real value)",
		"void putValue(scope ref const BigInt!128 value)",
		"void putValue(scope ref const Decimal!128 value)",
		"void putValue(typeof(null))",
		"void putNull(IonTypeCode code)",
		"void putValue(bool b)",
		"void putValue(scope const char[] value)",
		"void putValue(scope Clob value)",
		"void putValue(scope Blob value)",
		"void putValue(Timestamp value)",
		"void elemBegin()",
		"void sexpElemBegin()",
		"int serdeTarget() const @property"
	];

@safe:
	static foreach (method; definedMethods)
		mixin(method ~ " { writeln(__FUNCTION__ ~ `(`, __traits(parameters), `)`);
			static if (!is(typeof(return) == void)) return typeof(return).init; }");
}

DebugSerializer serializer;
serializeValue(serializer, account);
```

</details>

### Example Implementation

Based on the example format specified above we start making a small serializer writing into an `appender!string`.

```d
import mir.ser;
import mir.ion.type_code;
import std.array;

struct MySerializer
{
@safe:
private:
	Appender!string output = appender!string;
	bool arrayMode;
	bool beginStruct = true;

public:
	size_t structBegin()
	{
		beginStruct = true;
		return 0; // state
	}

	void structEnd(size_t state)
	{
	}

	size_t listBegin(size_t length = size_t.max)
	{
		arrayMode = true;
		return 0; // state
	}

	void listEnd(size_t state)
	{
		arrayMode = false;
	}

	void putKey(scope const char[] key)
	{
		if (arrayMode)
		{
			if (beginStruct)
				beginStruct = false;
			else
				output.put("\t");
		}
		else
		{
			if (beginStruct)
				beginStruct = false;
			else
				output.put("\n");

			output.put(key);
			output.put(":");
		}
	}

	void putValue(scope const(char)[] value)
	{
		output.put(value);
	}

	void elemBegin()
	{
		output.put("\n- ");
	}

	void putValue(T)(const T value)
	if (is(T == long) || is(T == ulong))
	{
		if (value == 0)
			output.put("0");
		else if (value > 0)
			output.put(format!"+%d"(value));
		else if (value < 0)
			output.put(format!"%d"(value));
	}

	void putValue(const bool value)
	{
		output.put(value ? "✓" : "✗");
	}

	void putNull(const IonTypeCode code)
	{
		output.put("(null)");
	}
}
```

and to help the user we also want to provide a convenience-method to directly create strings:

```d
string serializeMyFormat(T)(T value)
{
	MySerializer serializer;
	serializeValue(serializer, value);
	return serializer.output.data;
}
```

now we can simply call this to get our output:
```d
writeln(serializeMyFormat(account));
/*
iban:DE00123456789
accountHolder:Max Mustermann
transactions:
- ✓	DE00987654321	+12345
- ✓	DE00987654322	-4511
- ✗	DE00987654323	-1287
*/
```

## Deserializer

Deserialization with mir-ion works a little bit differently to serialization. Instead of providing a direct way to deserialize, you generate a stream of values / keys / etc. that can be interpreted by the binary Ion format. Amazon's Ion is a format similar to JSON, but a bit more flexible and descriptive as well as supporting text and binary data.

You can think of it simply being a representation of telling the deserializer what keys and values are present, the Ion deserializer then does the work of mapping keys and values into your actual D value instances.

It's possible to manually build binary ion data just into a `ubyte[]`, which is very low-level, but may benefit runtime performance. This is for example what the standard JSON implementation does. For the easiest implementation it's possible to simply use the `ionSerializer` function and call the serialization interface methods like what mir-ion does with our custom serializers above.

So if we take in the above output again and try to parse it back into usable D data, we would first define a method that would generate put all the values into ion. Ideally the ion serializer calls should be representable exactly the same as how our custom serializer was called to generate the serialized data.

However with our current model definition it's not possible to deserialize the format we have defined, because the keys inside an array are discarded on outputting. We could solve this in a variety of ways:

- specify the format to also output keys - it might not be possible to do this though
- hardcode keys inside the deserializer (might not be desirable)
- use a proxy (affects both serialization as well as deserialization)
- put ion deserialization code inside the struct

For this specific format there is no good all-encompasing solution yet, although with future mir-ion updates we might get the possibility to do things like representing structs as tuples more easily. So for now we will simply redefine the Transaction and use a custom deserializer in there:

```d name=deser
import std;

import mir.deser.ion;
import mir.ion.exception;
import mir.ion.value;
import mir.serde;

static struct Transaction
{
	bool confirmed;
	string iban;
	long txValue;

	@safe pure
	IonException deserializeFromIon(scope const char[][] symbolTable, scope IonDescribedValue value)
	{
		size_t i = 0;
		foreach (IonErrorCode error, scope elem; value.get!IonList)
		{
			if (error)
				return error.ionException;
			switch (i)
			{
			case 0: confirmed = deserializeIon!bool(symbolTable, elem); break;
			case 1: iban = deserializeIon!string(symbolTable, elem); break;
			case 2: txValue = deserializeIon!long(symbolTable, elem); break;
			default: return new IonException("More than 3 values received");
			}
			i++;
		}
		if (i != 3)
			return new IonException("Did not receive 3 values");
		return null;
	}
}

static struct Account
{
	string iban;
	string accountHolder;
	Transaction[] transactions;
}
```

```d name=deser
void parseMyFormat(T)(scope const(char)[] inputData, ref T serializer)
{
	import std.algorithm;
	import std.string;

	size_t root = serializer.structBegin();
	size_t listState;
	bool inArray = false;

	void endArray()
	{
		if (inArray)
		{
			serializer.listEnd(listState);
			inArray = false;
		}
	}

	void putValue(scope const(char)[] rawData)
	{
		if (rawData == "✓")
			serializer.putValue(true);
		else if (rawData == "✗")
			serializer.putValue(false);
		else if (rawData == "0")
			serializer.putValue(0);
		else if (rawData.length && rawData[0] == '+')
			serializer.putValue(rawData[1 .. $].to!ulong);
		else if (rawData.length && rawData[0] == '-')
			serializer.putValue(rawData.to!long);
		else
			serializer.putValue(rawData); // raw string
	}

	foreach (line; inputData.lineSplitter)
	{
		// ignore empty lines and comments
		if (!line.strip.length || line.strip.startsWith("#"))
			continue;

		if (inArray && !line.startsWith("- "))
			endArray();

		if (inArray)
		{
			auto rowItems = line[2 .. $].split("\t");
			serializer.elemBegin();
			auto itemTuple = serializer.listBegin();
			foreach (item; rowItems)
				putValue(item);
			serializer.listEnd(itemTuple);
		}
		else
		{
			auto parts = line.findSplit(":");
			serializer.putKey(parts[0]);
			if (!parts[2].length)
			{
				// assume empty value means array start
				listState = serializer.listBegin();
				inArray = true;
			}
			else
			{
				putValue(parts[2]);
			}
		}
	}
	endArray();

	serializer.structEnd(root);
}

@trusted
immutable(ubyte)[] myFormatToIon(scope const(char)[] inputData)
{
	import mir.appender : scopedBuffer;
	import mir.ion.symbol_table: IonSymbolTable;
    import mir.ion.internal.data_holder: ionPrefix;
	import mir.ser.ion : ionSerializer;
	import mir.serde : SerdeTarget;
	enum nMax = 4096;

	auto buf = scopedBuffer!ubyte;
	
	IonSymbolTable!false table = void;
	table.initialize;
	auto serializer = ionSerializer!(nMax * 8, null, false);
	serializer.initialize(table);

	parseMyFormat(inputData, serializer);

	serializer.finalize;

	buf.put(ionPrefix);
	if (table.initialized)
	{
		table.finalize;
		buf.put(table.data);
	}
	buf.put(serializer.data);

	return buf.data.idup;
}
```

Of course in a real serializer we would have much more things like input validation and grammar that makes more sense, but for a basic example this will suffice.

We can now also define a convenience function to deserialize from our custom format into any user-defined struct without the user needing to use ion.

```d name=deser
template deserializeMyFormat(T)
{
	void deserializeMyFormat(scope ref T value, scope const(char)[] data)
	{
		import mir.deser.ion : deserializeIon;

		return deserializeIon!T(value, myFormatToIon(data));
	}

	T deserializeMyFormat(scope const(char)[] data)
	{
		T value;
		deserializeMyFormat(value, data);
		return value;
	}
}
```

```d name=deser
string inputData = `
iban:DE00123456789
accountHolder:Max Mustermann

# we have comments too
transactions:
- ✓	DE00987654321	+12345
- ✓	DE00987654322	-4511
- ✗	DE00987654323	-1287
`;

auto parsedAccount = deserializeMyFormat!Account(inputData);

assert(parsedAccount.iban == "DE00123456789");
assert(parsedAccount.accountHolder == "Max Mustermann");
assert(parsedAccount.transactions == [
	Transaction(true, "DE00987654321", 12345),
	Transaction(true, "DE00987654322", -4511),
	Transaction(false, "DE00987654323", -1287)
]);
```
