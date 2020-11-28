#include <stdio.h>
#include <stdlib.h>

int main(void) {
    printf("env: %s\n", getenv("TEST"));
    FILE* fp = fopen("pkg:/manifest", "r");
    printf("fp: %p\n", fp);
    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    printf("file size: %d\n", (int)size);

    printf("skipping first character\n");
    fseek(fp, 1, SEEK_CUR);

    char buffer[4096] = {0};
    fread(buffer, 1, sizeof(buffer) - 1, fp);
    printf("%s\n", buffer);
    fclose(fp);
    return 0;
}