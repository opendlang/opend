/**

Copyright (c) 2023, Dominic Szablewski - https://phoboslab.org
SPDX-License-Identifier: MIT

QOA - The "Quite OK Audio" format for fast, lossy audio compression


-- Data Format

A QOA file has an 8 byte file header, followed by a number of frames. Each frame 
consists of an 8 byte frame header, the current 16 byte en-/decoder state per
channel and 256 slices per channel. Each slice is 8 bytes wide and encodes 20 
samples of audio data.

Note that the last frame of a file may contain less than 256 slices per channel.
The last slice (per channel) in the last frame may contain less 20 samples, but
the slice will still be 8 bytes wide, with the unused samples zeroed out.

The samplerate and number of channels is only stated in the frame headers, but
not in the file header. A decoder may peek into the first frame of the file to 
find these values.

In a valid QOA file all frames have the same number of channels and the same
samplerate. These restrictions may be relaxed for streaming. This remains to 
be decided.

All values in a QOA file are BIG ENDIAN. Luckily, EVERYTHING in a QOA file,
including the headers, is 64 bit aligned, so it's possible to read files with 
just a read_u64() that does the byte swapping if necessary.

In pseudocode, the file layout is as follows:

struct {
	struct {
		char     magic[4];         // magic bytes 'qoaf'
		uint32_t samples;          // number of samples per channel in this file
	} file_header;                 // = 64 bits

	struct {
		struct {
			uint8_t  num_channels; // number of channels
			uint24_t samplerate;   // samplerate in hz
			uint16_t fsamples;     // sample count per channel in this frame
			uint16_t fsize;        // frame size (including the frame header)
		} frame_header;            // = 64 bits

		struct {
			int16_t history[4];    // = 64 bits
			int16_t weights[4];    // = 64 bits
		} lms_state[num_channels]; 

		qoa_slice_t slices[256][num_channels]; // = 64 bits each
	} frames[samples * channels / qoa_max_framesize()];
} qoa_file;

Wheras the 64bit qoa_slice_t is defined as follows:

.- QOA_SLICE -- 64 bits, 20 samples --------------------------/  /------------.
|        Byte[0]         |        Byte[1]         |  Byte[2]  \  \  Byte[7]   |
| 7  6  5  4  3  2  1  0 | 7  6  5  4  3  2  1  0 | 7  6  5   /  /    2  1  0 |
|------------+--------+--------+--------+---------+---------+-\  \--+---------|
|  sf_index  |  r00   |   r01  |   r02  |  r03    |   r04   | /  /  |   r19   |
`-------------------------------------------------------------\  \------------`

`sf_index` defines the scalefactor to use for this slice as an index into the
qoa_scalefactor_tab[16]

`r00`--`r19` are the residuals for the individual samples, divided by the
scalefactor and quantized by the qoa_quant_tab[].

In the decoder, a prediction of the next sample is computed by multiplying the 
state (the last four output samples) with the predictor. The residual from the 
slice is then dequantized using the qoa_dequant_tab[] and added to the 
prediction. The result is clamped to int16 to form the final output sample.

*/
/*
MIT License

Copyright (c) 2022-2023 Dominic Szablewski
Copyright (c) 2023 Guillaume Piolat

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
module audioformats.qoa;

import audioformats.io;
import core.stdc.stdlib: malloc, free;
alias QOA_MALLOC = malloc;
alias QOA_FREE = free;

nothrow @nogc private:

enum int QOA_MIN_FILESIZE = 16;
enum int QOA_MAX_CHANNELS = 8;
enum int QOA_SLICE_LEN  = 20;
enum int QOA_SLICES_PER_FRAME = 256;
enum int QOA_FRAME_LEN = QOA_SLICES_PER_FRAME * QOA_SLICE_LEN;
enum int QOA_LMS_LEN = 4;
enum uint QOA_MAGIC = 0x716f6166; /* 'qoaf' in BE*/

uint QOA_FRAME_SIZE(uint channels, uint slices) pure
{
	return 8 + QOA_LMS_LEN * 4 * channels + 8 * slices * channels;
}

struct qoa_lms_t
{
	int[QOA_LMS_LEN] history;
	int[QOA_LMS_LEN] weights;
}

public struct qoa_desc
{
	uint channels;
	uint samplerate;
	uint samples;
	qoa_lms_t[QOA_MAX_CHANNELS] lms;
}

alias qoa_uint64_t = ulong;

/* The quant_tab provides an index into the dequant_tab for residuals in the
range of -8 .. 8. It maps this range to just 3bits and becomes less accurate at 
the higher end. Note that the residual zero is identical to the lowest positive 
value. This is mostly fine, since the qoa_div() function always rounds away 
from zero. */
static immutable int[17] qoa_quant_tab =
[
	7, 7, 7, 5, 5, 3, 3, 1, /* -8..-1 */
	0,                      /*  0     */
	0, 2, 2, 4, 4, 6, 6, 6  /*  1.. 8 */
];


/* We have 16 different scalefactors. Like the quantized residuals these become
less accurate at the higher end. In theory, the highest scalefactor that we
would need to encode the highest 16bit residual is (2**16)/8 = 8192. However we
rely on the LMS filter to predict samples accurately enough that a maximum 
residual of one quarter of the 16 bit range is sufficient. I.e. with the 
scalefactor 2048 times the quant range of 8 we can encode residuals up to 2**14.

The scalefactor values are computed as:
scalefactor_tab[s] <- round(pow(s + 1, 2.75)) */

static immutable int[16] qoa_scalefactor_tab =
[
	1, 7, 21, 45, 84, 138, 211, 304, 421, 562, 731, 928, 1157, 1419, 1715, 2048
];


/* The reciprocal_tab maps each of the 16 scalefactors to their rounded 
reciprocals 1/scalefactor. This allows us to calculate the scaled residuals in 
the encoder with just one multiplication instead of an expensive division. We 
do this in .16 fixed point with integers, instead of floats.

The reciprocal_tab is computed as:
reciprocal_tab[s] <- ((1<<16) + scalefactor_tab[s] - 1) / scalefactor_tab[s] */

static immutable int[16] qoa_reciprocal_tab = 
[
	65536, 9363, 3121, 1457, 781, 475, 311, 216, 156, 117, 90, 71, 57, 47, 39, 32
];


/* The dequant_tab maps each of the scalefactors and quantized residuals to 
their unscaled & dequantized version.

Since qoa_div rounds away from the zero, the smallest entries are mapped to 3/4
instead of 1. The dequant_tab assumes the following dequantized values for each 
of the quant_tab indices and is computed as:
float dqt[8] = {0.75, -0.75, 2.5, -2.5, 4.5, -4.5, 7, -7};
dequant_tab[s][q] <- round(scalefactor_tab[s] * dqt[q]) */

static immutable int[8][16] qoa_dequant_tab = 
[
	[   1,    -1,    3,    -3,    5,    -5,     7,     -7],
	[   5,    -5,   18,   -18,   32,   -32,    49,    -49],
	[  16,   -16,   53,   -53,   95,   -95,   147,   -147],
	[  34,   -34,  113,  -113,  203,  -203,   315,   -315],
	[  63,   -63,  210,  -210,  378,  -378,   588,   -588],
	[ 104,  -104,  345,  -345,  621,  -621,   966,   -966],
	[ 158,  -158,  528,  -528,  950,  -950,  1477,  -1477],
	[ 228,  -228,  760,  -760, 1368, -1368,  2128,  -2128],
	[ 316,  -316, 1053, -1053, 1895, -1895,  2947,  -2947],
	[ 422,  -422, 1405, -1405, 2529, -2529,  3934,  -3934],
	[ 548,  -548, 1828, -1828, 3290, -3290,  5117,  -5117],
	[ 696,  -696, 2320, -2320, 4176, -4176,  6496,  -6496],
	[ 868,  -868, 2893, -2893, 5207, -5207,  8099,  -8099],
	[1064, -1064, 3548, -3548, 6386, -6386,  9933,  -9933],
	[1286, -1286, 4288, -4288, 7718, -7718, 12005, -12005],
	[1536, -1536, 5120, -5120, 9216, -9216, 14336, -14336],
];


/* The Least Mean Squares Filter is the heart of QOA. It predicts the next
sample based on the previous 4 reconstructed samples. It does so by continuously
adjusting 4 weights based on the residual of the previous prediction.

The next sample is predicted as the sum of (weight[i] * history[i]).

The adjustment of the weights is done with a "Sign-Sign-LMS" that adds or
subtracts the residual to each weight, based on the corresponding sample from 
the history. This, surprisingly, is sufficient to get worthwhile predictions.

This is all done with fixed point integers. Hence the right-shifts when updating
the weights and calculating the prediction. */

int qoa_lms_predict(qoa_lms_t *lms) pure
{
	int prediction = 0;
	for (int i = 0; i < QOA_LMS_LEN; i++) 
	{
		prediction += lms.weights[i] * lms.history[i];
	}
	return prediction >> 13;
}

void qoa_lms_update(qoa_lms_t *lms, int sample, int residual) pure
{
	int delta = residual >> 4;
	for (int i = 0; i < QOA_LMS_LEN; i++) 
	{
		lms.weights[i] += lms.history[i] < 0 ? -delta : delta;
	}

	for (int i = 0; i < QOA_LMS_LEN-1; i++) 
	{
		lms.history[i] = lms.history[i+1];
	}
	lms.history[QOA_LMS_LEN-1] = sample;
}


/* qoa_div() implements a rounding division, but avoids rounding to zero for 
small numbers. E.g. 0.1 will be rounded to 1. Note that 0 itself still 
returns as 0, which is handled in the qoa_quant_tab[].
qoa_div() takes an index into the .16 fixed point qoa_reciprocal_tab as an
argument, so it can do the division with a cheaper integer multiplication. */

int qoa_div(int v, int scalefactor) pure
{
	int reciprocal = qoa_reciprocal_tab[scalefactor];
	int n = (v * reciprocal + (1 << 15)) >> 16;
	n = n + ((v > 0) - (v < 0)) - ((n > 0) - (n < 0)); /* round away from 0 */
	return n;
}

int qoa_clamp(int v, int min, int max) pure
{
	if (v < min) { return min; }
	if (v > max) { return max; }
	return v;
}

int qoa_clamp_s16(int v) pure
{
	if (cast(uint)(v + 32768) > 65535) 
	{
		if (v < -32768) { return -32768; }
		if (v >  32767) { return  32767; }
	}
	return v;
}


void qoa_write_u64(qoa_uint64_t v, ubyte* bytes, uint *p) pure
{
	bytes += *p;
	*p += 8;
	bytes[0] = (v >> 56) & 0xff;
	bytes[1] = (v >> 48) & 0xff;
	bytes[2] = (v >> 40) & 0xff;
	bytes[3] = (v >> 32) & 0xff;
	bytes[4] = (v >> 24) & 0xff;
	bytes[5] = (v >> 16) & 0xff;
	bytes[6] = (v >>  8) & 0xff;
	bytes[7] = (v >>  0) & 0xff;
}


/* -----------------------------------------------------------------------------
	Encoder */

uint qoa_encode_header(qoa_desc *qoa, ubyte* bytes) pure
{
	uint p = 0;
	qoa_write_u64((cast(qoa_uint64_t)QOA_MAGIC << 32) | qoa.samples, bytes, &p);
	return p;
}

uint qoa_encode_frame(const short *sample_data, qoa_desc *qoa, uint frame_len, ubyte* bytes) pure
{
	uint channels = qoa.channels;

	uint p = 0;
	uint slices = (frame_len + QOA_SLICE_LEN - 1) / QOA_SLICE_LEN;
	uint frame_size = QOA_FRAME_SIZE(channels, slices);

	/* Write the frame header */
	qoa_write_u64((
		cast(qoa_uint64_t)qoa.channels   << 56 |
		cast(qoa_uint64_t)qoa.samplerate << 32 |
		cast(qoa_uint64_t)frame_len       << 16 |
		cast(qoa_uint64_t)frame_size
	), bytes, &p);

	/* Write the current LMS state */
	for (int c = 0; c < channels; c++) {
		qoa_uint64_t weights = 0;
		qoa_uint64_t history = 0;
		for (int i = 0; i < QOA_LMS_LEN; i++) {
			history = (history << 16) | (qoa.lms[c].history[i] & 0xffff);
			weights = (weights << 16) | (qoa.lms[c].weights[i] & 0xffff);
		}
		qoa_write_u64(history, bytes, &p);
		qoa_write_u64(weights, bytes, &p);
	}

	/* We encode all samples with the channels interleaved on a slice level.
	E.g. for stereo: (ch-0, slice 0), (ch 1, slice 0), (ch 0, slice 1), ...*/
	for (int sample_index = 0; sample_index < frame_len; sample_index += QOA_SLICE_LEN) {

		for (int c = 0; c < channels; c++) {
			int slice_len = qoa_clamp(QOA_SLICE_LEN, 0, frame_len - sample_index);
			int slice_start = sample_index * channels + c;
			int slice_end = (sample_index + slice_len) * channels + c;			

			/* Brute for search for the best scalefactor. Just go through all
			16 scalefactors, encode all samples for the current slice and 
			meassure the total squared error. */
			qoa_uint64_t best_error = -1;
			qoa_uint64_t best_slice;
			qoa_lms_t best_lms;

			for (int scalefactor = 0; scalefactor < 16; scalefactor++) {

				/* We have to reset the LMS state to the last known good one
				before trying each scalefactor, as each pass updates the LMS
				state when encoding. */
				qoa_lms_t lms = qoa.lms[c];
				qoa_uint64_t slice = scalefactor;
				qoa_uint64_t current_error = 0;

				for (int si = slice_start; si < slice_end; si += channels) {
					int sample = sample_data[si];
					int predicted = qoa_lms_predict(&lms);

					int residual = sample - predicted;
					int scaled = qoa_div(residual, scalefactor);
					int clamped = qoa_clamp(scaled, -8, 8);
					int quantized = qoa_quant_tab[clamped + 8];
					int dequantized = qoa_dequant_tab[scalefactor][quantized];
					int reconstructed = qoa_clamp_s16(predicted + dequantized);

					long error = (sample - reconstructed);
					current_error += error * error;
					if (current_error > best_error) {
						break;
					}

					qoa_lms_update(&lms, reconstructed, dequantized);
					slice = (slice << 3) | quantized;
				}

				if (current_error < best_error) {
					best_error = current_error;
					best_slice = slice;
					best_lms = lms;
				}
			}

			qoa.lms[c] = best_lms;
			
			/* If this slice was shorter than QOA_SLICE_LEN, we have to left-
			shift all encoded data, to ensure the rightmost bits are the empty
			ones. This should only happen in the last frame of a file as all
			slices are completely filled otherwise. */
			best_slice <<= (QOA_SLICE_LEN - slice_len) * 3;
			qoa_write_u64(best_slice, bytes, &p);
		}
	}
	
	return p;
}

void *qoa_encode(const short *sample_data, qoa_desc *qoa, uint *out_len) 
{
	if (
		qoa.samples == 0 || 
		qoa.samplerate == 0 || qoa.samplerate > 0xffffff ||
		qoa.channels == 0 || qoa.channels > QOA_MAX_CHANNELS
	) {
		return null;
	}

	/* Calculate the encoded size and allocate */
	uint num_frames = (qoa.samples + QOA_FRAME_LEN-1) / QOA_FRAME_LEN;
	uint num_slices = (qoa.samples + QOA_SLICE_LEN-1) / QOA_SLICE_LEN;
	uint encoded_size = 8 +                    /* 8 byte file header */
		num_frames * 8 +                               /* 8 byte frame headers */
		num_frames * QOA_LMS_LEN * 4 * qoa.channels + /* 4 * 4 bytes lms state per channel */
		num_slices * 8 * qoa.channels;                /* 8 byte slices */

	ubyte* bytes = cast(ubyte*) QOA_MALLOC(encoded_size);

	for (int c = 0; c < qoa.channels; c++) 
    {
		/* Set the initial LMS weights to {0, 0, -1, 2}. This helps with the 
		prediction of the first few ms of a file. */
		qoa.lms[c].weights[0] = 0;
		qoa.lms[c].weights[1] = 0;
		qoa.lms[c].weights[2] = -(1<<13);
		qoa.lms[c].weights[3] =  (1<<14);

		/* Explicitly set the history samples to 0, as we might have some
		garbage in there. */
		for (int i = 0; i < QOA_LMS_LEN; i++) {
			qoa.lms[c].history[i] = 0;
		}
	}


	/* Encode the header and go through all frames */
	uint p = qoa_encode_header(qoa, bytes);
	
	int frame_len = QOA_FRAME_LEN;
	for (int sample_index = 0; sample_index < qoa.samples; sample_index += frame_len) 
    {
		frame_len = qoa_clamp(QOA_FRAME_LEN, 0, qoa.samples - sample_index);		
		const short *frame_samples = sample_data + sample_index * qoa.channels;
		uint frame_size = qoa_encode_frame(frame_samples, qoa, frame_len, bytes + p);
		p += frame_size;
	}

	*out_len = p;
	return bytes;
}



/* -----------------------------------------------------------------------------
	Decoder */

uint qoa_max_frame_size(qoa_desc *qoa) 
{
	return QOA_FRAME_SIZE(qoa.channels, QOA_SLICES_PER_FRAME);
}

// Note: was changed, qoa_desc is allocated on heap
uint qoa_decode_header(IOCallbacks* io, void* userData, qoa_desc** qoadesc) 
{
	uint p = 0;
	if (io.remainingBytesToRead(userData) < QOA_MIN_FILESIZE) 
    {
		return 0;
	}

	bool err;

	/* Read the file header, verify the magic number ('qoaf') and read the 
	total number of samples. */
	qoa_uint64_t file_header = io.read_ulong_BE(userData, &err);
	if (err)
		return 0;

	if ((file_header >> 32) != QOA_MAGIC) {
		return 0;
	}

    qoa_desc* desc = cast(qoa_desc*) QOA_MALLOC(qoa_desc.sizeof);
	*qoadesc = desc;

	desc.samples = file_header & 0xffffffff;
	if (!(desc.samples))
		return 0;

	/* Peek into the first frame header to get the number of channels and
	the samplerate. */
	qoa_uint64_t frame_header = io.read_ulong_BE(userData, &err);
	if (err)
		return 0;
	desc.channels   = (frame_header >> 56) & 0x0000ff;
	desc.samplerate = (frame_header >> 32) & 0xffffff;

	if (desc.channels == 0 || desc.samples == 0 || desc.samplerate == 0) {
		return 0;
	}

	return 8;
}

uint qoa_decode_frame(IOCallbacks* io, void* userData, qoa_desc *qoa, short *sample_data, uint *frame_len) 
{
	uint p = 0;
	*frame_len = 0;

	if (io.remainingBytesToRead(userData) < 8 + QOA_LMS_LEN * 4 * qoa.channels)
		return 0;

	/* Read and verify the frame header */
	bool err;
	qoa_uint64_t frame_header = io.read_ulong_BE(userData, &err);
	if (err)
		return 0;
	int channels   = (frame_header >> 56) & 0x0000ff;
	int samplerate = (frame_header >> 32) & 0xffffff;
	int samples    = (frame_header >> 16) & 0x00ffff;
	int frame_size = (frame_header      ) & 0x00ffff;

	int data_size = frame_size - 8 - QOA_LMS_LEN * 4 * channels;
	int num_slices = data_size / 8;
	int max_total_samples = num_slices * QOA_SLICE_LEN;

	if (io.remainingBytesToRead(userData) < frame_size - 8)
		return 0;
	if (
		channels != qoa.channels || 
		samplerate != qoa.samplerate ||
		samples * channels > max_total_samples
	) 
    {
		return 0;
	}

	/* Read the LMS state: 4 x 2 bytes history, 4 x 2 bytes weights per channel */
	for (int c = 0; c < channels; c++) 
    {
		qoa_uint64_t history = io.read_ulong_BE(userData, &err);
		if (err) 
            return 0;
		qoa_uint64_t weights = io.read_ulong_BE(userData, &err);
		if (err) 
            return 0;
		for (int i = 0; i < QOA_LMS_LEN; i++) {
			qoa.lms[c].history[i] = (cast(short)(history >> 48));
			history <<= 16;
			qoa.lms[c].weights[i] = (cast(short)(weights >> 48));
			weights <<= 16;
		}
	}

	/* Decode all slices for all channels in this frame */
	for (int sample_index = 0; sample_index < samples; sample_index += QOA_SLICE_LEN) 
    {
		for (int c = 0; c < channels; c++) 
        {
			qoa_uint64_t slice = io.read_ulong_BE(userData, &err);
			if (err) 
                return 0;

			int scalefactor = (slice >> 60) & 0xf;
			int slice_start = sample_index * channels + c;
			int slice_end = qoa_clamp(sample_index + QOA_SLICE_LEN, 0, samples) * channels + c;

			for (int si = slice_start; si < slice_end; si += channels) {
				int predicted = qoa_lms_predict(&qoa.lms[c]);
				int quantized = (slice >> 57) & 0x7;
				int dequantized = qoa_dequant_tab[scalefactor][quantized];
				int reconstructed = qoa_clamp_s16(predicted + dequantized);
				
				sample_data[si] = cast(short)reconstructed;
				slice <<= 3;

				qoa_lms_update(&qoa.lms[c], reconstructed, dequantized);
			}
		}
	}

	*frame_len = samples;
	return p;
}

// Streaming decoder for QOA.
public struct QOADecoder
{
nothrow @nogc:
	IOCallbacks* io;
	void* userData;
	short* buffer = null;
	qoa_desc* desc;

	int numChannels;
	int totalFrames;
	float samplerate;

	int bufStart; // start of buffer
	int bufStop; // end of buffer (bufStop - bufStart) is the number of frames in buffer

	int currentPositionFrame = -1;

	bool seekPosition(int positionFrame)
    {
		if (currentPositionFrame == positionFrame)
			return true;

		// A QOA file has an 8 byte file header, followed by a number of frames. Each frame 
        // consists of an 8 byte frame header, the current 16 byte en-/decoder state per
        // channel and 256 slices per channel. Each slice is 8 bytes wide and encodes 20 
        // samples of audio data.

		// Forget current decoding buffer content.
		bufStop = 0;
        bufStart = 0;

		uint sliceIndex = positionFrame / QOA_SLICE_LEN;
		uint frameIndex = sliceIndex / QOA_SLICES_PER_FRAME;

		int remain = positionFrame - frameIndex*QOA_SLICES_PER_FRAME*QOA_SLICE_LEN;
		assert(remain >= 0);

		uint byteSizeOfFullFrame = QOA_FRAME_SIZE(numChannels, QOA_SLICES_PER_FRAME);
		uint frameOffset = 8 + byteSizeOfFullFrame * frameIndex;

		// goto this frame
        if (!io.seek(frameOffset, false, userData))
			return false;

		if (remain > 0)
        {
			// Read complete slice, refill buffer.
			uint frameLen;
            qoa_decode_frame(io, userData, desc, buffer, &frameLen);
			bufStart = 0;
            bufStop = frameLen;

			// Then read some sample to advance.
			bool err;
			int res = readSamples!float(null, remain, &err);
			if (res != remain || err)
				return false; // Note: in this case currentPositionFrame is left invalid...
        }	

		currentPositionFrame = positionFrame;
		return true;
    }

	int tellPosition()
    {
		return currentPositionFrame;
    }

	// return true if this is a QOA. Taint io.
	bool initialize(IOCallbacks* io, void* userData)
    {
		this.io = io;
		this.userData = userData;

		if (qoa_decode_header(io, userData, &desc) != 8)
			return false;

		this.numChannels = desc.channels;
		this.totalFrames = desc.samples;
		this.samplerate = desc.samplerate;

		if (!io.seek(8, false, userData))
			return false;
		currentPositionFrame = 0;

		// We need a single QOA_FRAME_LEN buffer for decoding.
		buffer = cast(short*) QOA_MALLOC(short.sizeof * QOA_FRAME_LEN * numChannels);

		bufStart = 0; // Nothing in buffer
		bufStop = 0;

		return true; // Note: we've read 16 bytes, so we seek to byte 8 (begin of first frame).
    }

	~this()
    {
		QOA_FREE(buffer);
		buffer = null;

		QOA_FREE(desc);
		desc = null;
    }

	int readSamples(T)(T* outData, int frames, bool* err)
    {
		int offsetFrames = 0;
		while (frames > 0)
        {
			// If no more data in buffer, read a frame
			if (bufStop - bufStart == 0)
            {
				uint frameLen;
                qoa_decode_frame(io, userData, desc, buffer, &frameLen);

				if (frameLen == 0)
					return offsetFrames;

				bufStart = 0;
				bufStop = frameLen;
            }

			// How many samples we have in buffers? Take them.
			int inStore = bufStop - bufStart;
			if (inStore > frames)
                inStore = frames;

			if (outData !is null)
            {
				enum float F = 1.0f / short.max;

				for (int n = 0; n < inStore; ++n)
				{
					for (int ch = 0; ch < numChannels; ++ch)
					{
						int index = n*numChannels+ch;
						outData[offsetFrames*numChannels + index] = buffer[bufStart*numChannels + index] * F;
					}
				}
            }

			bufStart += inStore;
			offsetFrames += inStore;
			currentPositionFrame += inStore;
			frames -= inStore;
			assert(bufStart <= bufStop);
        }
		return offsetFrames;
    }
}
