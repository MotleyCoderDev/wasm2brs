#include <iostream>
#include <unistd.h>
#include <roku.h>

int main(void) {
    std::cout << "Hello world" << std::endl;
    sleep(1000);
    std::cout << "How are you?" << std::endl;
    return 0;
}