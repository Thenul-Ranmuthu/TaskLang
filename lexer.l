%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int line_num = 1;
%}

DIGIT       [0-9]
LETTER      [a-zA-Z]
IDENTIFIER  [a-zA-Z][a-zA-Z0-9_]*
TIME        [0-9]{2}:[0-9]{2}
STRING      \"[^\"]*\"

%%

"TASK"          { return TASK; }
"RUN"           { return RUN; }
"EVERY"         { return EVERY; }
"DAY"           { return DAY; }
"WEEK"          { return WEEK; }
"ON"            { return ON; }
"AT"            { return AT; }
"AFTER"         { return AFTER; }
"IF"            { return IF; }
"success"       { return SUCCESS; }
"failure"       { return FAILURE; }
"MONDAY"        { return MONDAY; }
"TUESDAY"       { return TUESDAY; }
"WEDNESDAY"     { return WEDNESDAY; }
"THURSDAY"      { return THURSDAY; }
"FRIDAY"        { return FRIDAY; }
"SATURDAY"      { return SATURDAY; }
"SUNDAY"        { return SUNDAY; }
"DEPENDS"       { return DEPENDS; }
"BEFORE"        { return BEFORE; }

{TIME}          {
                    yylval.str = strdup(yytext);
                    return TIME;
                }

{STRING}        {
                    yylval.str = strdup(yytext);
                    return STRING;
                }

{IDENTIFIER}    {
                    yylval.str = strdup(yytext);
                    return IDENTIFIER;
                }

"{"             { return '{'; }
"}"             { return '}'; }

[ \t\r]+        { /* skip whitespace */ }
\n              { line_num++; }

"#"[^\n]*       { /* skip single-line comments */ }

.               {
                    fprintf(stderr,
                        "[Lexical Error] Line %d: Unknown character '%s'\n",
                        line_num, yytext);
                }

%%

int yywrap(void) {
    return 1;
}
