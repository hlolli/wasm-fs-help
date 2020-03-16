#include <stdio.h>
#include <dirent.h>

int test1() {
  char filename[] = "/sandbox/example1.txt";
  FILE *fptr = fopen(filename, "w");

  if (fptr == NULL) {
    printf("cannot open file %s \n", filename);
    return 1;
  }

  fprintf(fptr, "%s", "foo bar baz");
  fclose(fptr);
  return 0;
}
