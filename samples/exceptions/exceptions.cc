#include <stdio.h>

int main() {
    try {
        printf("Throwing an exception...\n");
        throw "Exception thrown!";
    } catch (...) {
        printf("Caught exception in catch!\n");
    }

    return 0;
}
