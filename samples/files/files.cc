#include <stdio.h>
#include <stdlib.h>

int main(void) {
    FILE* fp = fopen("pkg:/manifest", "r");
    printf("fp: %p\n", fp);
    char buffer[4096] = {0};
    fread(buffer, 1, sizeof(buffer) - 1, fp);
    printf("%s\n", buffer);
    fclose(fp);
    return 0;
}