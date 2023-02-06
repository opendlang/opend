/++
This module contains constants used in statistical algorithms.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022-3 Mir Stat Authors.

+/

module mir.stat.constant;

import mir.math.common: log, sqrt;
import mir.math.constant: PI;

///
enum real LOGPI = log(PI);
///
enum real LOGSQRT2PI = 0.91893853320467274178032973640561764L; // log(sqrt(2pi))
///
enum real SQRTPI = sqrt(PI);
///
enum real SQRTPIINV = 1 / SQRTPI;