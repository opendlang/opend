module cubelut;

import std.stdio;
import std.string;
import std.conv;
import core.stdc.stdio;
import inteli.emmintrin;

/// A 3D LUT can be applied to floating-point images.
struct LUT
{
    string title;
    float[4][] table;
    int size;

    void readFromCubeFile(string path) // provide .cube file
    {
        auto file = File(path, "r");

        int point = 0;
        int numPoints = 0;
        size = 0; // unknown

        // index to write
        int ix = 0;
        int iy = 0;
        int iz = 0;

        string line;
        while ((line = file.readln()) !is null)
        {
            // chomp end of line
            if (line.length > 0 && line[$-1] == '\n')
                line = line[0..$-1];
            if (line.length > 0 && line[$-1] == '\r')
                line = line[0..$-1];

            if (line.length == 0)
                continue;
            else if (line[0] == '#')
            {
                // comment
                continue;
            }
            else if (line.startsWith("DOMAIN_MIN"))
            {
                // ignore
            }
            else if (line.startsWith("DOMAIN_MAX"))
            {
                // ignore
            }
            else if (line.startsWith("LUT_1D_SIZE"))
            {
                // ignored, often does nothing
            }
            else if (line.startsWith("LUT_1D_INPUT_RANGE"))
            {
                // ignored, often does nothing                
            }
            else if (line.startsWith("TITLE"))
            {
                title = line[6..$];
            }
            else if (line.startsWith("LUT_3D_SIZE"))
            {
                // init LUT size
                size = to!int(line[12..$]);
                table.length = size * size * size;
                table[] = [0.0f, 0.0f, 0.0f, 0.0f];
                numPoints = size * size * size;
            }
            else
            {
                if (point < numPoints)
                {
                    // Read rgb triplet with sncanf

                    string lineZT = line ~ '\0';
                    float r = 0, g = 0, b = 0, a = 0;

                    if (3 == sscanf(line.ptr, "%f %f %f".ptr, &r, &g, &b))
                    {
                        table[point] = [r, g, b, a];
                        point++;
                    }
                    else
                        assert(false);
                    // else input error, TODO fail                    
                }
            }
        }
        file.close();

    }

    __m128 sampleAt(int r, int g, int b)
    {
        if (r >= size) r = size - 1;
        if (g >= size) g = size - 1;
        if (b >= size) b = size - 1;
        return _mm_loadu_ps(cast(float*) &table[r + g * size + b * size * size]);
    }

    void processScanline(float[4]* pixels, int width)
    {
        for (int x = 0; x < width; ++x)
        {
            float[4] pixel = pixels[x]; // TODO: clamp somewhere

            float fr = pixel[0] * (size - 1);
            float fg = pixel[1] * (size - 1);
            float fb = pixel[2] * (size - 1);
            if (fr < 0) fr = 0;
            if (fg < 0) fg = 0;
            if (fb < 0) fb = 0;
            if (fr > size - 1.001f) fr = size - 1.001f;
            if (fg > size - 1.001f) fg = size - 1.001f;
            if (fb > size - 1.001f) fb = size - 1.001f;

            // TODO linear sampling with 8 integer samples

            int ir = cast(int)(fr);
            int ig = cast(int)(fg);
            int ib = cast(int)(fb);
            assert(ir >= 0);
            assert(ig >= 0);
            assert(ib >= 0);
            

            __m128 A = sampleAt(ir,   ig,   ib);
            __m128 B = sampleAt(ir+1, ig,   ib);
            __m128 C = sampleAt(ir  , ig+1, ib);
            __m128 D = sampleAt(ir+1, ig+1, ib);

            __m128 E = sampleAt(ir,   ig,   ib+1);
            __m128 F = sampleAt(ir+1, ig,   ib+1);
            __m128 G = sampleAt(ir  , ig+1, ib+1);
            __m128 H = sampleAt(ir+1, ig+1, ib+1); 

            __m128 ones = _mm_set1_ps(1.0f);
            __m128 fmr = _mm_set1_ps(fr - ir);
            __m128 fmg = _mm_set1_ps(fg - ig);
            __m128 fmb = _mm_set1_ps(fb - ib);

            A = E * fmb + A * (ones - fmb); 
            B = F * fmb + B * (ones - fmb); 
            C = G * fmb + C * (ones - fmb); 
            D = H * fmb + D * (ones - fmb); 

            A = C * fmg + A * (ones - fmg);
            B = D * fmg + B * (ones - fmg);

            A = A * fmr + B * (ones - fmr);

            // clip again
            alias mapped = A;

            pixel[0] = mapped[0];
            pixel[1] = mapped[1];
            pixel[2] = mapped[2]; // do not touch original alpha

            if (pixel[0] < 0) pixel[0] = 0;
            if (pixel[1] < 0) pixel[1] = 0;
            if (pixel[2] < 0) pixel[2] = 0;
            if (pixel[0] > 1) pixel[0] = 1;
            if (pixel[1] > 1) pixel[1] = 1;
            if (pixel[2] > 1) pixel[2] = 1;

            pixels[x] = pixel;
        }
    }
}