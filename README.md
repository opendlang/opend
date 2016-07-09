[![codecov.io](https://codecov.io/github/libmir/cpuid/coverage.svg?branch=master)](https://codecov.io/github/libmir/cpuid?branch=master)
[![Latest version](https://img.shields.io/github/tag/libmir/cpuid.svg?maxAge=3600)](http://code.dlang.org/packages/cpuid)
[![Gitter](https://img.shields.io/gitter/room/libmir/public.svg)](https://gitter.im/libmir/public)

[![Circle CI](https://circleci.com/gh/libmir/cpuid.svg?style=svg)](https://circleci.com/gh/libmir/cpuid)
[![Build Status](https://travis-ci.org/libmir/cpuid.svg?branch=master)](https://travis-ci.org/libmir/cpuid) | [![Build Status](https://travis-ci.org/libmir/cpuid.svg?branch=master)](https://travis-ci.org/libmir/cpuid)
[![Build status](https://ci.appveyor.com/api/projects/status/f2n4dih5s4c32q7u/branch/master?svg=true)](https://ci.appveyor.com/project/9il/cpuid/branch/master)

[![Dub version](https://img.shields.io/dub/v/cpuid.svg)](http://code.dlang.org/packages/cpuid)
[![Dub downloads](https://img.shields.io/dub/dt/cpuid.svg)](http://code.dlang.org/packages/cpuid)
[![License](https://img.shields.io/dub/l/cpuid.svg)](http://code.dlang.org/packages/cpuid)

# Low Level CPU Information

X86
---
	
	 - Vendor name
	 - Brand name
	 - `_cpuid` function

	### Intel

		 - TLB information
		 - Cache sizes information

	### AMD

		 - TLB information
		 - Cache sizes information

This package also can be used as workaround for [core.cpuid Issue 16028](https://issues.dlang.org/show_bug.cgi?id=16028).
