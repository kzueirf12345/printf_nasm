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

    // ERROR_HANDLE(printme("%c%c%c%c%c%c%c\n", '1', '2', '3','4','5','6','7','8'));
    ERROR_HANDLE(printme("%d %c %d\n", -__INT_MAX__-1, 'c', __INT_MAX__));

    return EXIT_SUCCESS;
}