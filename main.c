
#include "defines.h"

using namespace std;
using namespace boost;

extern FILE* yyin; // this is already in the parser and we just need to point it to a file.
extern int yyparse();

module_t* module;

int main(int num_args, char** args) {

  FILE* f;
  string filename = "top.v";
  module = new module_t();

  f = fopen(filename, "r");
  if(f == NULL) {
    printf("couldn't open %s\n", filename);
    exit(1);
  }
  else {
    printf("parsing: %s\n", filename);
  }
  yyin = f;  // now flex reads from file
  yyparse();
  fclose(f);

}




