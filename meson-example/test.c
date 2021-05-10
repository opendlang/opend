#include <stdio.h>
#include <string.h>

double deserializeC(const char* json, size_t len);


int main()
{
    char* text = "{\"a\":1, \"b\":2.0}";
    printf("a + b = %f\n", deserializeC(text, strlen(text)));
    return 0;
}
