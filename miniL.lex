%{
    //prologue
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "miniL-parser.hpp"

    int line = 1;
    int column = 1;

    void change_line(){
    line++;
    column = 1;
    }

    void change_column(int length){
    column += length;
    }

%}

%option noyywrap
%option yylineno

%%

"function"      { change_column(yyleng); return FUNCTION; }
"beginparams"   { change_column(yyleng); return BEGINPARAMS; }
"endparams"     { change_column(yyleng); return ENDPARAMS; }
"beginlocals"   { change_column(yyleng); return BEGINLOCALS; }
"endlocals"     { change_column(yyleng); return ENDLOCALS; }
"beginbody"     { change_column(yyleng); return BEGINBODY; }
"endbody"       { change_column(yyleng); return ENDBODY; }
"integer"       { change_column(yyleng); return INTEGER; }
"array"         { change_column(yyleng); return ARRAY; }
"of"            { change_column(yyleng); return OF; }
"if"            { change_column(yyleng); return IF; }
"then"          { change_column(yyleng); return THEN; }
"endif"         { change_column(yyleng); return ENDIF; }
"else"          { change_column(yyleng); return ELSE; }
"while"         { change_column(yyleng); return WHILE; }
"do"            { change_column(yyleng); return DO; }
"beginloop"     { change_column(yyleng); return BEGINLOOP; }
"endloop"       { change_column(yyleng); return ENDLOOP; }
"continue"      { change_column(yyleng); return CONTINUE; }
"read"          { change_column(yyleng); return READ; }
"write"         { change_column(yyleng); return WRITE; }
"foreach"       { change_column(yyleng); return FOREACH; }
"in"            { change_column(yyleng); return IN; }
"and"           { change_column(yyleng); return AND; }
"or"            { change_column(yyleng); return OR; }
"not"           { change_column(yyleng); return NOT; }
"true"          { change_column(yyleng); return TRUE; }
"false"         { change_column(yyleng); return FALSE; }
"return"        { change_column(yyleng); return RETURN; }
":="            { change_column(yyleng); return ASSIGN; }
"=="            { change_column(yyleng); return EQ; }
"<>"            { change_column(yyleng); return NEQ; }
"<="            { change_column(yyleng); return LTE; }
">="            { change_column(yyleng); return GTE; }
"<"             { change_column(yyleng); return LT; }
">"             { change_column(yyleng); return GT; }
"-"             { change_column(yyleng); return MINUS; }
"+"             { change_column(yyleng); return PLUS; }
"*"             { change_column(yyleng); return MULT; }
"/"             { change_column(yyleng); return DIV; }
"%"             { change_column(yyleng); return MOD; }
";"             { change_column(yyleng); return SEMICOLON; }
":"             { change_column(yyleng); return COLON; }
","             { change_column(yyleng); return COMMA; }
"("             { change_column(yyleng); return L_PAREN; }
")"             { change_column(yyleng); return R_PAREN; }
"["             { change_column(yyleng); return L_SQUARE_BRACKET; }
"]"             { change_column(yyleng); return R_SQUARE_BRACKET; }
"enum"          { change_column(yyleng); return ENUM; }

[0-9]+          { 
    change_column(yyleng); 
    yylval.int_val = atoi(yytext); 
    return NUMBER; 
}

[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9] { 
    change_column(yyleng); 
    yylval.str_val = strdup(yytext); 
    return IDENTIFIER; 
}

[a-zA-Z]        { 
    change_column(yyleng); 
    yylval.str_val = strdup(yytext); 
    return IDENTIFIER; 
}

[0-9][a-zA-Z0-9_]* { 
    printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", 
           yylineno, column, yytext); 
    exit(1); 
}

_[a-zA-Z0-9_]*  { 
    printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", 
           yylineno, column, yytext); 
    exit(1); 
}

[a-zA-Z][a-zA-Z0-9_]*_ { 
    printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", 
           yylineno, column, yytext); 
    exit(1); 
}

"##".*          { change_column(yyleng); /* ignore comments */ }
[ \t]+          { change_column(yyleng); /* ignore whitespace */ }
\n              { change_line(); }

.               { 
    printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", 
           yylineno, column, yytext); 
    exit(1); 
}

%%
