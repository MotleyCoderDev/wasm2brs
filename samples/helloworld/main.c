__attribute__((__import_module__(""), __import_name__("print"))) extern void print(int value);

__attribute__((used)) extern void foo(void) {
    print(55);
}

void _start(void) {
    print(12345);
}
