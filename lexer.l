
%{
#include <cstdio>
#include <cstdlib>
#include <string> 
#include "defines.h"
#include "module.h"

using namespace std;
using namespace boost;

#include "parser.tab.h"


void yyerror(char*);
int yyparse(void);
%}

%%
"#".*                  ;  // throw out comments
[ \t\n]+               ;  // do nothing on whitespace
[0-9][0-9]*(.[0-9]+)?  {yylval.double_val = atof(yytext); return NUMBER;}

"module"               return MODULE;
"endmodule"            return ENDMODULE;

"input"                return INPUT;
"output"               return OUTPUT;

"="                    return ASSIGN;
"<="                   return NONBLOCKINGASSIGN;
"|"                    return ORBAR;
"+"                    return PLUS;
";"                    return SEMICOLON;
":"                    return COLON;
"("                    return LPAREN;
")"                    return RPAREN;
"{"                    return LBRACKET;
"}"                    return RBRACKET;
"["                    return LSQUAREBRACKET;
"]"                    return RSQUAREBRACKET;

"@"                    return ATSIGN;
"always"               return SEND;
"*"                    return STAR;
"begin"                return BEGIN_BLOCK;
"end"                  return END_BLOCK;
","                    return COMMA;

[a-zA-Z][a-zA-Z0-9]*   {yylval.str_val = new string(yytext); return VARIABLE;}


%%

void yyerror(char* str) {
  printf("Parse Error: \n%s\n",str);
}

int yywrap(void) { }

