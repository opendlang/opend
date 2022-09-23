/++
+/
module mir.ion.internal.basic_types;

import mir.bignum.decimal: Decimal;
import mir.bignum.integer: BigInt;
import mir.lob: Blob, Clob;
import mir.timestamp: Timestamp;
import mir.functional: Tuple;

package(mir) enum isBigInt(T) = is(immutable T == immutable BigInt!size, size_t size);
package(mir) enum isBlob(T) = is(immutable T == immutable Blob);
package(mir) enum isClob(T) = is(immutable T == immutable Clob);
package(mir) enum isDecimal(T) = is(immutable T == immutable Decimal!size, size_t size);
package(mir) enum isTimestamp(T) = is(immutable T == immutable Timestamp);
package(mir) enum isTuple(T) = is(immutable T == immutable Tuple!Types, Types);
