/**
 * Internal header file for the backend
 *
 * Compiler implementation of the
 * $(LINK2 https://www.dlang.org, D programming language).
 *
 * Copyright:   Copyright (C) 2000-2024 by The D Language Foundation, All Rights Reserved
 *
 * Authors:     $(LINK2 https://www.digitalmars.com, Walter Bright)
 * License:     $(LINK2 https://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source:      $(LINK2 https://github.com/dlang/dmd/blob/master/src/dmd/backend/backend.d, backend/backend.d)
 */
module dmd.backend.backend;

import dmd.backend.code_x86;
import dmd.backend.el;
