#include <iostream>
#include <roku.h>

int main(void) {
    std::cout << "Input text:" << std::endl;
    std::string input;
    std::getline(std::cin, input);
    roku_sleep(1000);
    std::cout << "Echo: " << input;
    return 0;
}