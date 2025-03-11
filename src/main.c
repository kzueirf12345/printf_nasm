#include <stdio.h>
#include <stdlib.h>

extern int printme(const char* const format);

int main()
{
    printf("This program print hello world with asm func:\n");
    
    if (printme("Hello, world!\n"))
    {
        fprintf(stderr, "Can't printme\n");
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}