/**
License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)
*/
/**
 * Normal Distribution
 *
 * Copyright: Based on the CEPHES math library, which is
 *            Copyright (C) 1994 Stephen L. Moshier (moshier@world.std.com).
 * Authors:   Stephen L. Moshier, ported to D by Don Clugston and David Nadlinger. Adopted to Mir by Ilya Yaroshenko.
 */
/**
 * Macros:
 *  NAN = $(RED NAN)
 *  INTEGRAL = &#8747;
 *  POWER = $1<sup>$2</sup>
 *      <caption>Special Values</caption>
 *      $0</table>
 */

module mir.stat.distribution.normal;

public import mir.math.func.normal: normalPDF, normalCDF, normalInvCDF;
