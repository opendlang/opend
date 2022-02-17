/++
+/
module mir.ion.internal.basic_types;

import mir.bignum.decimal: Decimal;
import mir.bignum.integer: BigInt;
import mir.lob: Blob, Clob;
import mir.timestamp: Timestamp;
import std.traits: Unqual;

package(mir) enum isBigInt(T) = is(Unqual!T == BigInt!size, size_t size);
package(mir) enum isBlob(T) = is(Unqual!T == Blob);
package(mir) enum isClob(T) = is(Unqual!T == Clob);
package(mir) enum isDecimal(T) = is(Unqual!T == Decimal!size, size_t size);
package(mir) enum isTimestamp(T) = is(Unqual!T == Timestamp);
