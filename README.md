## What's this?

binrange is a library to parse and emit over ranges of `ubyte`.

It's an alternative to `std.bitmanip.read` and `std.bitmanip.write`.
It also support RIFF headers.

## Licenses

See UNLICENSE.txt


## Usage

```d

import binrange;

void main()
{
    ubyte[] input = [ 0x00, 0x01, 0x02, 0x03 ];

    // read one uint encoded in little endian from a range
    assert(popLE!uint(input) == 0x03020100);

    // write one float encoded in big-endian into an output range
    import std.array;
    ubyte[] arr;
    auto app = appender(arr);
    writeBE!float(app, 1.2f);
}

```
