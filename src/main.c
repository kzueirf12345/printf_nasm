#include <stdio.h>
#include <stdlib.h>

#define ERROR_HANDLE(call_func, ...)                                                                \
    do {                                                                                            \
        const int error_handler = call_func;                                                        \
        if (error_handler)                                                                          \
        {                                                                                           \
            fprintf(stderr, "Can't " #call_func ". Error: %d\n", error_handler);                    \
            __VA_ARGS__                                                                             \
            return error_handler;                                                                   \
        }                                                                                           \
    } while(0)

extern int printme(const char* const format, ...);

int main()
{
    printf("This program print hello world with asm func:\n");

    // ERROR_HANDLE(printme("0x%x\n", 0x64));

    ERROR_HANDLE(printme("0b%b;\n%c; %d; 0b%b; 0o%o; 0x%x;\n", 
                          -__LONG_MAX__+100, 'c', __LONG_MAX__, 3, 16, 0xBADDEDD1l));

    return EXIT_SUCCESS;
}