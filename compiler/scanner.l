%option noyywrap

%{
#include "parser.tab.h"
#include <string.h>
#include <stdlib.h>

// 1. Variable global para contar lineas
int num_linea = 1; 
%}

digit       [0-9]
id          [a-zA-Z_][a-zA-Z0-9_]*
string      \"[^\"]*\"

%%

"//".* { /* Ignorar comentarios de una linea */ }

"#include"  { return INCLUDE; }
"#define"   { return DEFINE; }

"int"       { return INT; }
"func"      { return FUNC; }
"return"    { return RETURN; }
"if"        { return IF; } 

{string}    {
                yylval.str = strdup(yytext);
                return STRING_LITERAL;
            }

{digit}+    {
                yylval.str = strdup(yytext);
                return NUMBER;
            }

{id}        {
                yylval.str = strdup(yytext);
                return ID;
            }

"("         { return PARIZQ; }
")"         { return PARDER; }
"{"         { return LLAVEIZQ; }
"}"         { return LLAVEDER; }
";"         { return PUNTOYCOMA; }
","         { return COMA; }
"="         { return IGUAL; }
"<"         { return MENOR; }
">"         { return MAYOR; }
"."         { return PUNTO; }

"+"         { return MAS; }
"-"         { return MENOS; }
"*"         { return MULT; }
"/"         { return DIV; }

\n          { num_linea++; }
[ \t\r]+    ; 

.           { return yytext[0]; }

%%