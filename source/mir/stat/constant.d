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
enum real LOGPI =      0x1.250d048e7a1bd0bd5f956c6a843f4p+0L;  // log(pi)
///
enum real LOGSQRT2PI = 0x0.eb3f8e4325f5a53494bc900144192p+0L;  // log(sqrt(2pi))
///
enum real SQRTPI =     0x1.c5bf891b4ef6aa79c3b0520d5db93p+0L; // sqrt(PI);
///
enum real M_SQRTPI =  0x0.906eba8214db688d71d48a7f6bfec3p+0L; // 1/sqrt(pi)



                       