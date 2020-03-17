#include <stdio.h>
#include <fcntl.h>
#include <dirent.h>
/* #include <wasi/libc.h> */


int add() {
  char filename[] = "/sandbox/example1.txt";
  printf("attempting to open %s \n", filename);
  FILE *fptr = fopen(filename, "w+");
  if (fptr == NULL) {
    printf("cannot open file %s \n", filename);
    return 1;
  }
  printf("file %s opened \n", filename);
  fprintf(fptr, "This is testing for fprintf...\n");
  fputs("This is testing for fputs...\n", fptr);
  fclose(fptr);
  printf("file %s closed \n", filename);
  return 0;
}

int main (int argc, char *argv[] ) {}
