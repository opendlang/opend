// EXTRA_SOURCES: imports/inline2a.d
// PERMUTE_ARGS:
// REQUIRED_ARGS: -O -ludicrous -inline

import imports.inline2a;

class Foo
{
        this ()
        {
                Primes.lookup(2);
        }
}


int main()
{
        Primes.lookup(2);
        return 0;
}
