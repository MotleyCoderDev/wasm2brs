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

void print_top_and_pop(duk_context* ctx) {
    duk_idx_t top = duk_get_top(ctx);
    
    // Try first to turn it into JSON if it's an Object, and if that fails then use String(...)
    duk_dup_top(ctx);
    const char* result = nullptr;
    if (duk_get_type(ctx, -1) == DUK_TYPE_OBJECT) {
        result = duk_json_encode(ctx, -1);
        if (result == nullptr) {
            duk_pop(ctx);
        }
    }
    if (result == nullptr) {
        duk_get_global_string(ctx, "String");
        duk_swap_top(ctx, -2);
        duk_call(ctx, 1);
        result = duk_to_string(ctx, -1);
    }
    std::cout << "Result: " << (result ? result : "undefined") << std::endl;
    duk_pop_n(ctx, duk_get_top(ctx) - top + 1);
}

int main(void) {
    duk_context* ctx = duk_create_heap_default();
    std::cout << intro;
    for (;;) {
        std::string input;
        std::getline(std::cin, input);
        duk_eval_string(ctx, input.c_str());
        print_top_and_pop(ctx);
    }
    return 0;
}