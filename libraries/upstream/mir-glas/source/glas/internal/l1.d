/++
Copyright: Copyright © 2016-, Ilya Yaroshenko.
License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Ilya Yaroshenko
+/
module glas.internal.l1;

import mir.ndslice.slice: Slice, SliceKind;
import ldc.attributes: fastmath;
import glas.internal.utility;
import ldc.intrinsics;
static import glas.ndslice;

@fastmath:

pragma(inline, true):

void scal(A, T)(A a, size_t len, sizediff_t str, T* ptr)
{
	if (str == 1)
	{
		static if (isComplex!T && isReal!A)
		{
			len *= 2;
			glas.ndslice.scal(a, len, str, cast(A*)ptr);
		}
		else
		{
			while (len)
			{
				*ptr *= a;
				ptr++;
				len--;
			}
		}
	}
	else
	if (str != 0)
	{
		while (len)
		{
			*ptr *= a;
			ptr += str;
			len--;
		}
	}
}

void copy(T)(size_t len, sizediff_t incx, const(T)* x, sizediff_t incy, T* y)
{
	if (incx == 1 && incy == 1)
	{
		static if (isComplex!T)
		{
			alias R = realType!T;
			len *= 2;
			glas.ndslice.copy(len, incx, cast(const(R)*)x, incy, cast(R*)y);
		}
		else
		{
			for(; len; len--)
				*y++ = *x++;
		}
		return;
	}
	for(; len; len--)
	{
		*y = *x;
		x += incx;
		y += incy;
	}
}

void swap(T)(size_t len, sizediff_t incx, T* x, sizediff_t incy, T* y)
{
	if (incx == 1 && incy == 1)
	{
		static if (isComplex!T)
		{
			alias R = realType!T;
			len *= 2;
			glas.ndslice.swap(len, incx, cast(R*)x, incy, cast(R*)y);
		}
		else
		{
			for(; len; len--)
			{
				auto t = *x;
				*x = *y;
				*y = t;
				x++;
				y++;
			}
		}
		return;
	}
	for(; len; len--)
	{
		auto t = *x;
		*x = *y;
		*y = t;
		x += incx;
		y += incy;
	}
}

void axpy(T)(T a, size_t len, sizediff_t incx, const(T)* x, sizediff_t incy, T* y)
{
	if (incx == 1 && incy == 1)
	{
		for(; len; len--)
			*y++ += a * *x++;
		return;
	}
	for(; len; len--)
	{
		*y += a * *x;
		x += incx;
		y += incy;
	}
}

float nrm2(T : float)(size_t len, sizediff_t incx, const(T)* x)
{
	if (len == 1)
		return llvm_fabs(*x);
	if (incx == 1)
	{
		double ret = 0;
		for(; len; len--)
		{
			auto t = double(*x);
			ret += t * t;
			x++;
		}
		return llvm_sqrt(ret);
	}
	else
	{
		double ret = 0;
		for(; len; len--)
		{
			auto t = double(*x);
			ret += t * t;
			x += incx;
		}
		return llvm_sqrt(ret);
	}
}

float nrm2(T : cfloat)(size_t len, sizediff_t incx, const(T)* x)
{
	if (incx == 1)
	{
		len *= 2;
		return glas.ndslice.nrm2(len, incx, cast(const(float)*) x);
	}
	double ret_re = 0;
	double ret_im = 0;
	for(; len; len--)
	{
		cdouble t = *x;
		ret_re += t.re * t.re;
		ret_im += t.im * t.im;
		x += incx;
	}
	return llvm_sqrt(ret_re + ret_im);
}

double nrm2(T : double)(size_t len, sizediff_t incx, const(T)* x)
{
	if (len == 1)
		return llvm_fabs(*x);
	double scale = 0;
	double ssq = 1;
	for(; len; len--)
	{
		if (auto v = *x)
		{
			auto absxi = llvm_fabs(v);
			if (scale < absxi)
			{
				auto t = scale / absxi;
				ssq = 1 + ssq * (t * t);
				scale = absxi;
			}
			else
			{
				auto t = absxi / scale;
				ssq += t * t;
			}
		}
		x += incx;
	}
	return scale * llvm_sqrt(ssq);
}

double nrm2(T : cdouble)(size_t len, sizediff_t incx, const(T)* x)
{
	double scale = 0;
	double ssq = 1;
	if (len)
	do
	{
		if (auto v = x.re)
		{
			auto absxi = llvm_fabs(v);
			if (scale < absxi)
			{
				auto t = scale / absxi;
				ssq = 1 + ssq * (t * t);
				scale = absxi;
			}
			else
			{
				auto t = absxi / scale;
				ssq += t * t;
			}
		}
		if (auto v = x.im)
		{
			auto absxi = llvm_fabs(v);
			if (scale < absxi)
			{
				auto t = scale / absxi;
				ssq = 1 + ssq * (t * t);
				scale = absxi;
			}
			else
			{
				auto t = absxi / scale;
				ssq += t * t;
			}
		}
		x += incx;
	}
	while(--len);
	return scale * llvm_sqrt(ssq);
}


realType!T asum(T)(size_t len, sizediff_t incx, const(T)* x)
	if (isComplex!T)
{
	if (incx == 1)
	{
		len *= 2;
		return glas.ndslice.asum(len, incx, cast(const(typeof(return))*)x);
	}
	typeof(return) ret_re = 0;
	typeof(return) ret_im = 0;
	if (len)
	do
	{
		ret_re += llvm_fabs(x.re);
		ret_im += llvm_fabs(x.im);
		x += incx;
	}
	while(--len);
	return ret_re + ret_im;
}

T asum(T)(size_t len, sizediff_t incx, const(T)* x)
	if (!isComplex!T)
{
	if (incx == 1)
	{
		typeof(return) ret = 0;
		for(; len; len--)
		{
			ret += llvm_fabs(*x);
			x++;
		}
		return ret;
	}
	else
	{
		typeof(return) ret = 0;
		if (len == 0)
			return ret;
		do
		{
			ret += llvm_fabs(*x);
			x += incx;
		}
		while(--len);
		return ret;
	}
}

ptrdiff_t iamax(T)(size_t len, sizediff_t incx, const(T)* x)
{
	typeof(return) ret = -1;
	auto smax = -realType!T.infinity;
	if (incx == 1)
	{
		foreach(ptrdiff_t i; 0 .. len)
		{
			static if (!isComplex!T)
				auto r = llvm_fabs(x[i]);
			else
				auto r = llvm_fabs(x[i].re) + llvm_fabs(x[i].im);
			if (smax < r)
			{
				smax = r;
				ret = i;
			}
		}
	}
	else
	{
		foreach(ptrdiff_t i; 0 .. len)
		{
			static if (!isComplex!T)
				auto r = llvm_fabs(*x);
			else
				auto r = llvm_fabs(x.re) + llvm_fabs(x.im);
			if (smax < r)
			{
				smax = r;
				ret = i;
			}
			x += incx;
		}
	}
	return ret;
}

U dot(U, T)(size_t len, sizediff_t incx, const(T)* x, sizediff_t incy, const(T)* y)
{
	if (incx == 1 && incy == 1)
	{
		U ret = 0;
		for(; len; len--)
		{
			ret += U(*x) * U(*y);
			x++;
			y++;
		}
		return ret;
	}
	else
	{
		U ret = 0;
		if (len == 0)
			return ret;
		do
		{
			ret += U(*x) * U(*y);
			x += incx;
			y += incy;
		}
		while(--len);
		return ret;
	}
}

T dotc(T)(size_t len, sizediff_t incx, const(T)* x, sizediff_t incy, const(T)* y)
	if (isComplex!T)
{
	alias R = realType!T;
	if (incx == 1 && incy == 1)
	{
		R ret_re = 0;
		R ret_im = 0;
		for(; len; len--)
		{
			ret_re += x.re * y.re + x.im * y.im;
			ret_im += x.re * y.im - x.im * y.re;
			x++;
			y++;
		}
		return ret_re + ret_im * 1fi;
	}
	else
	{
		R ret_re = 0;
		R ret_im = 0;
		if (len)
		do
		{
			ret_re += x.re * y.re + x.im * y.im;
			ret_im += x.re * y.im - x.im * y.re;
			x += incx;
			y += incy;
		}
		while(--len);
		return ret_re + ret_im * 1fi;
	}
}

T dotu(T)(size_t len, sizediff_t incx, const(T)* x, sizediff_t incy, const(T)* y)
	if (isComplex!T)
{
	alias R = realType!T;
	if (incx == 1 && incy == 1)
	{
		R ret_re = 0;
		R ret_im = 0;
		for(; len; len--)
		{
			ret_re += x.re * y.re - x.im * y.im;
			ret_im += x.re * y.im + x.im * y.re;
			x++;
			y++;
		}
		return ret_re + ret_im * 1fi;
	}
	else
	{
		R ret_re = 0;
		R ret_im = 0;
		if (len)
		do
		{
			ret_re += x.re * y.re - x.im * y.im;
			ret_im += x.re * y.im + x.im * y.re;
			x += incx;
			y += incy;
		}
		while(--len);
		return ret_re + ret_im * 1fi;
	}
}

void rot(T, R = realType!T)(size_t len, sizediff_t incx, T* x, sizediff_t incy, T* y, R c, R s)
{
	if (len == 0)
		return;
	if (incx == 1 && incy == 1)
	{
		do
		{
			auto a = *x;
			auto b = *y;
			*x = c * a + s * b;
			*y = c * b - s * a;
			x++;
			y++;
		}
		while(--len);
		return;
	}
	else
	{
		do
		{
			auto a = *x;
			auto b = *y;
			*x = c * a + s * b;
			*y = c * b - s * a;
			x += incx;
			y += incy;
		}
		while(--len);
	}
}

void rotm(T, R = realType!T)(size_t len, sizediff_t incx, T* x, sizediff_t incy, T* y, ref const R[5] sparam)
{
	if (len == 0)
		return;
	auto sflag = sparam[0];
	if (sflag == -2)
		return;
	if (incx == 1 && incy == 1)
	{
		if (sflag < 0)
		{
			const sh11 = sparam[1];
			const sh12 = sparam[3];
			const sh21 = sparam[2];
			const sh22 = sparam[4];
			do
			{
				const w = *x;
				const z = *y;
				*x = w * sh11 + z * sh12;
				*y = w * sh21 + z * sh22;
				x++;
				y++;
			}
			while(--len);
		}
		else
		if (sflag == 0)
		{
			const sh12 = sparam[3];
			const sh21 = sparam[2];
			do
			{
				const w = *x;
				const z = *y;
				*x = w + z * sh12;
				*y = w * sh21 + z;
				x++;
				y++;
			}
			while(--len);
		}
		else
		{
			const sh11 = sparam[1];
			const sh22 = sparam[4];
			do
			{
				const w = *x;
				const z = *y;
				*x = w * sh11 + z;
				*y = sh22 * z - w;
				x++;
				y++;
			}
			while(--len);
		}
	}
	else
	{
		if (sflag < 0)
		{
			const sh11 = sparam[1];
			const sh12 = sparam[3];
			const sh21 = sparam[2];
			const sh22 = sparam[4];
			do
			{
				const w = *x;
				const z = *y;
				*x = w * sh11 + z * sh12;
				*y = w * sh21 + z * sh22;
				x += incx;
				y += incy;
			}
			while(--len);
		}
		else
		if (sflag == 0)
		{
			const sh12 = sparam[3];
			const sh21 = sparam[2];
			do
			{
				const w = *x;
				const z = *y;
				*x = w + z * sh12;
				*y = w * sh21 + z;
				x += incx;
				y += incy;
			}
			while(--len);
		}
		else
		{
			const sh11 = sparam[1];
			const sh22 = sparam[4];
			do
			{
				const w = *x;
				const z = *y;
				*x = w * sh11 + z;
				*y = sh22 * z - w;
				x += incx;
				y += incy;
			}
			while(--len);
		}
	}
}


void rotg(T, R)(ref T ca, ref T cb, ref R c, ref T s)
	if (isComplex!T)
{
	auto aca = abs(ca);
	if (!aca)
	{
		c = 0;
		s = 1f + 0fi;
		ca = cb;
	}
	else
	{
		auto scale = aca + abs(cb);
		auto a = abs(ca / scale);
		auto b = abs(cb / scale);
		auto norm = scale * llvm_sqrt(a * a + b * b);
		auto alpha = ca / aca;
		c = abs(ca) / norm;
		s = alpha * (cb.re - cb.im * 1fi) / norm;
		ca = alpha * norm;
	}
}

void rotg(T)(ref T da, ref T db, ref T c, ref T s)
	if (!isComplex!T)
{
	auto roe = db;
	auto ada = llvm_fabs(da);
	auto adb = llvm_fabs(db);
	if (ada > adb)
		roe = da;
	auto scale = ada + adb;
	if (scale)
	{
		auto a = da / scale;
		auto b = db / scale;
		auto r = scale * llvm_sqrt(a * a + b * b);
		r = llvm_copysign(T(1), roe) * r;
		c = da / r;
		s = db / r;
		auto z = T(1);
		if (ada > adb)
			z = s;
		if (adb >= ada && c)
			z = 1 / c;
		da = r;
		db = z;
	}
	else
	{
		c = 1;
		s = 0;
		da = 0;
		db = 0;
	}
}

void rotmg(T)(ref T dd1, ref T dd2, ref T dx1, ref T dy1, ref T[5] dparam)
	if (!isComplex!T)
{
	enum T gam = 4096;
	enum T gamsq = 16777216;
	enum T rgamsq = 5.9604645e-8;

	T dflag = 0;
	T dh11 = 0;
	T dh12 = 0;
	T dh21 = 0;
	T dh22 = 0;
	T dp1 = 0;
	T dp2 = 0;
	T dq1 = 0;
	T dq2 = 0;
	T dtemp = 0;
	T du = 0;
 
	if (dd1 < 0)
	{
		dflag = -1;
		dh11 = 0;
		dh12 = 0;
		dh21 = 0;
		dh22 = 0;
		dd1 = 0;
		dd2 = 0;
		dx1 = 0;
	}
	else
	{
		dp2 = dd2*dy1;
		if (dp2 == 0)
		{
			dflag = -2;
			dparam[1 - 1] = dflag;
			return;
		}
		dp1 = dd1*dx1;
		dq2 = dp2*dy1;
		dq1 = dp1*dx1;
		if (llvm_fabs(dq1) > llvm_fabs(dq2))
		{
			dh21 = -dy1/dx1;
			dh12 = dp2/dp1;
			du = 1 - dh12*dh21;
			if (du > 0)
			{
				dflag = 0;
				dd1 = dd1/du;
				dd2 = dd2/du;
				dx1 = dx1*du;
			}
		}
		else
		{
			if (dq2 < 0)
			{
				dflag = -1;
				dh11 = 0;
				dh12 = 0;
				dh21 = 0;
				dh22 = 0;
				dd1 = 0;
				dd2 = 0;
				dx1 = 0;
			}
			else
			{
				dflag = 1;
				dh11 = dp1/dp2;
				dh22 = dx1/dy1;
				du = 1 + dh11*dh22;
				dtemp = dd2/du;
				dd2 = dd1/du;
				dd1 = dtemp;
				dx1 = dy1*du;
			}
		}

		if (dd1 != 0)
		{
			while ((dd1 <= rgamsq) || (dd1 >= gamsq))
			{
				if (dflag == 0)
				{
					dh11 = 1;
					dh22 = 1;
					dflag = -1;
				}
				else
				{
					dh21 = -1;
					dh12 = 1;
					dflag = -1;
				}
				if (dd1 <= rgamsq)
				{
					dd1 = dd1*(gam * gam);
					dx1 = dx1/gam;
					dh11 = dh11/gam;
					dh12 = dh12/gam;
				}
				else
				{
					dd1 = dd1/(gam * gam);
					dx1 = dx1*gam;
					dh11 = dh11*gam;
					dh12 = dh12*gam;
				}
			}
		}

		if (dd2 != 0)
		{
			while ( (llvm_fabs(dd2) <= rgamsq) || (llvm_fabs(dd2) >= gamsq) )
			{
				if (dflag == 0)
				{
					dh11 = 1;
					dh22 = 1;
					dflag = -1;
				}
				else
				{
					dh21 = -1;
					dh12 = 1;
					dflag = -1;
				}
				if (llvm_fabs(dd2) <= rgamsq)
				{
					dd2 = dd2*(gam * gam);
					dh21 = dh21/gam;
					dh22 = dh22/gam;
				}
				else
				{
					dd2 = dd2/(gam * gam);
					dh21 = dh21*gam;
					dh22 = dh22*gam;
				}
			}
		}
	}

	if (dflag < 0)
	{
		dparam[2 - 1] = dh11;
		dparam[3 - 1] = dh21;
		dparam[4 - 1] = dh12;
		dparam[5 - 1] = dh22;
	}
	else if (dflag == 0)
	{
		dparam[3 - 1] = dh21;
		dparam[4 - 1] = dh12;
	}
	else
	{
		dparam[2 - 1] = dh11;
		dparam[5 - 1] = dh22;
	}
	dparam[1 - 1] = dflag;
}

T hypot(T : float)(in T x, in T y) @safe pure nothrow @nogc
{
	auto a = double(x);
	auto b = double(y);
	return llvm_sqrt(a * a + b * b);
}

T hypot(T)(in T x, in T y) @safe pure nothrow @nogc
{
	pragma(inline, false);
	// Scale x and y to avoid underflow and overflow.
	// If 1 is huge and the other tiny, return the larger.
	// If both are huge, avoid overflow by scaling by 1/sqrt(T.max/2).
	// If both are tiny, avoid underflow by scaling by sqrt(T.min_normal*T.epsilon).
	alias T = typeof(return);

	enum T SQRTMIN = 0.5 * llvm_sqrt(T.min_normal); // This is a power of 2.
	enum T SQRTMAX = 1.0L / SQRTMIN; // 2^^((max_exp)/2) = nextUp(sqrt(T.max))

	static assert(2*(SQRTMAX/2)*(SQRTMAX/2) <= T.max);

	// Proves that sqrt(T.max) ~~  0.5/sqrt(T.min_normal)
	static assert(T.min_normal*T.max > 2 && T.min_normal*T.max <= 4);

	T u = llvm_fabs(x);
	T v = llvm_fabs(y);
	if (!(u >= v))  // check for NaN as well.
	{
		v = u;
		u = llvm_fabs(y);
		if (u == T.infinity) return u; // hypot(inf, nan) == inf
		if (v == T.infinity) return v; // hypot(nan, inf) == inf
	}

	// Now u >= v, or else 1 is NaN.
	if (v >= SQRTMAX * 0.5f)
	{
			// hypot(huge, huge) -- avoid overflow
		u *= SQRTMIN * 0.5f;
		v *= SQRTMIN * 0.5f;
		u *= u;
		v *= v;
		v += u;
		return llvm_sqrt(v) * SQRTMAX * 2.0f;
	}

	if (u <= SQRTMIN)
	{
		// hypot (tiny, tiny) -- avoid underflow
		// This is only necessary to avoid setting the underflow
		// flag.
		u *= SQRTMAX / T.epsilon;
		v *= SQRTMAX / T.epsilon;
		u *= u;
		v *= v;
		v += u;
		return llvm_sqrt(v) * SQRTMIN * T.epsilon;
	}

	if (u * T.epsilon > v)
	{
		// hypot (huge, tiny) = huge
		return u;
	}

	// both are in the normal range
	u *= u;
	v *= v;
	v += u;
	return llvm_sqrt(v);
}

//alias abs = llvm_fabs;

realType!T abs(T)(in T x)
	if (isComplex!T)
{
	return hypot(x.re, x.im);
}

