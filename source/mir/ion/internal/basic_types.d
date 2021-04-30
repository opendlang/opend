/++
+/
module mir.ion.internal.basic_types;

import mir.bignum.decimal: Decimal;
import mir.bignum.integer: BigInt;
import mir.lob: Blob, Clob;
import mir.timestamp: Timestamp;
import std.traits: Unqual;

package(mir.ion) enum isBigInt(T) = is(Unqual!T == BigInt!size, size_t size);
package(mir.ion) enum isBlob(T) = is(Unqual!T == Blob);
package(mir.ion) enum isClob(T) = is(Unqual!T == Clob);
package(mir.ion) enum isDecimal(T) = is(Unqual!T == Decimal!size, size_t size);
package(mir.ion) enum isTimestamp(T) = is(Unqual!T == Timestamp);
