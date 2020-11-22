#include "duktape/duktape.h"
#include <iostream>
#include <string>

int main(void) {
    duk_context* ctx = duk_create_heap_default();
    std::cout << "Write JavaScript and press enter to evaluate it" << std::endl << std::flush;
    for (;;) {
        std::string input;
        std::cin >> input;
        duk_eval_string(ctx, input.c_str());
        const char* json = duk_json_encode(ctx, -1);
        std::cout << "Result: " << json << std::endl;
        duk_pop(ctx);
    }
    return 0;
}