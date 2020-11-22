#include "duktape/duktape.h"
#include <iostream>
#include <string>

const char* intro =
    "Write JavaScript and press enter to evaluate it. "
    "Errors will abort due to unimplemented longjmp. Try:\n"
    "  9-3\n"
    "  Date()\n"
    "  Math.random()\n"
    "  [1,2].join(',')\n"
    "  ({test: 10*10})\n"
    "  (function(){var a=3;return a*2})()\n";

int main(void) {
    duk_context* ctx = duk_create_heap_default();
    std::cout << intro;
    for (;;) {
        std::string input;
        std::getline(std::cin, input);
        duk_eval_string(ctx, input.c_str());
        const char* json = duk_json_encode(ctx, -1);
        std::cout << "Result: " << (json ? json : "undefined") << std::endl;
        duk_pop(ctx);
    }
    return 0;
}