%{
    // Prologue
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    int temp_count = 0;
    int label_count = 0;
    char* new_temp() {
        char* name = malloc(20);
        sprintf(name, "_temp%d", temp_count++);
        return name;
    }
    char* new_label() {
        char* label = malloc(20);
        sprintf(label, "_label%d", label_count++);
        return label;
    }
    void yyerror(const char *msg);
    extern int yylex();
    extern int yylineno;
    extern char* yytext;

%}

%union{
    char* str_val;
    int int_val;
}

%error-verbose
%locations

/* Token declarations */
%token <str_val> IDENTIFIER
%token <int_val> NUMBER
%token FUNCTION BEGINPARAMS ENDPARAMS BEGINLOCALS ENDLOCALS BEGINBODY ENDBODY
%token INTEGER ARRAY OF IF THEN ELSE ENDIF WHILE DO BEGINLOOP ENDLOOP
%token CONTINUE READ WRITE FOREACH IN RETURN
%token ASSIGN SEMICOLON COLON COMMA
%token L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET
%token PLUS MINUS MULT DIV MOD
%token EQ NEQ LT LTE GT GTE
%token AND OR NOT
%token TRUE FALSE
%token ENUM

%type <str_val> statement bool_expr relation_and_expr relation_expr expression multiplicative_expr term var vars
%type <int_val> comp
/* Operator precedence and associativity (lowest to highest) */
%right ASSIGN
%left OR
%left AND
%right NOT
%left EQ NEQ LT LTE GT GTE
%left PLUS MINUS
%left MULT DIV MOD
%right UMINUS
%left L_SQUARE_BRACKET
%left L_PAREN

/* Start symbol */
%start program

%%

program: functions;

functions: function
         | functions function;

function: FUNCTION IDENTIFIER SEMICOLON BEGINPARAMS declarations ENDPARAMS BEGINLOCALS declarations ENDLOCALS BEGINBODY statements ENDBODY

        ;

declarations: /* empty */

            | declarations declaration

            ;

declaration: identifiers COLON INTEGER SEMICOLON
           | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER SEMICOLON

           | identifiers COLON ENUM L_PAREN enum_list R_PAREN SEMICOLON

           ;

identifiers: IDENTIFIER
           | identifiers COMMA IDENTIFIER
           ;

enum_list: IDENTIFIER
         | enum_list COMMA IDENTIFIER
         ;

statements: /* empty */

          | statements statement
          ;

statement
    : var ASSIGN expression SEMICOLON {
        printf("= %s, %s\n", $1, $3);
    }
    | IF bool_expr THEN statements ENDIF opt_semi {
        char* end_label = new_label();
        printf("?:= %s, %s\n", $2, end_label);
        printf("%s:\n", end_label);
    }
    | IF bool_expr THEN statements ELSE statements ENDIF opt_semi {
        char* else_label = new_label();
        char* end_label = new_label();
        printf("?:= %s, %s\n", $2, else_label);
        // true branch (statements)
        // after true branch, unconditional jump to end_label
        printf(":= %s\n", end_label);
        printf("%s:\n", else_label);
        // else branch (statements)
        printf("%s:\n", end_label);
    }
    | WHILE bool_expr BEGINLOOP statements ENDLOOP opt_semi {
        char* start_label = new_label();
        char* end_label = new_label();
        printf("%s:\n", start_label);
        printf("?:= %s, %s\n", $2, end_label);
        // statements
        printf(":= %s\n", start_label);
        printf("%s:\n", end_label);
    }
    | DO BEGINLOOP statements ENDLOOP WHILE bool_expr SEMICOLON {
        char* start_label = new_label();
        printf("%s:\n", start_label);
        // statements
        printf("?:= %s, %s\n", $6, start_label);
    }
    | FOREACH IDENTIFIER IN IDENTIFIER BEGINLOOP statements ENDLOOP opt_semi {
        // No MIL for foreach for now
    }
    | READ vars SEMICOLON {
        // assume vars is a single var for now
        printf(".< %s\n", $2);
    }
    | WRITE vars SEMICOLON {
        printf("> %s\n", $2);
    }
    | CONTINUE SEMICOLON {
        printf("continue\n");
    }
    | RETURN expression SEMICOLON {
        printf("ret %s\n", $2);
    }
    ;
opt_semi: /* empty */
        | SEMICOLON
        ;

vars
    :var
    | var COMMA vars
    ;

bool_expr
    : relation_and_expr
    | bool_expr OR relation_and_expr {
        char* temp = new_temp();
        printf("or %s, %s, %s\n", temp, $1, $3);
        $$ = temp;
    }
    ;

relation_and_expr
    : relation_expr
    | relation_and_expr AND relation_expr {
        char* temp = new_temp();
        printf("and %s, %s, %s\n", temp, $1, $3);
        $$ = temp;
    }
    ;

relation_expr
    : expression comp expression {
        char* temp = new_temp();
        // $2 is the comp operator token
        char* op;
        switch ($2) {
            case EQ: op = "=="; break;
            case NEQ: op = "!="; break;
            case LT: op = "<"; break;
            case LTE: op = "<="; break;
            case GT: op = ">"; break;
            case GTE: op = ">="; break;
            default: op = "??"; break;
        }
        printf("%s %s, %s, %s\n", op, temp, $1, $3);
        $$ = temp;
    }
    | NOT expression comp expression {
        char* temp = new_temp();
        char* op;
        switch ($3) {
            case EQ: op = "=="; break;
            case NEQ: op = "!="; break;
            case LT: op = "<"; break;
            case LTE: op = "<="; break;
            case GT: op = ">"; break;
            case GTE: op = ">="; break;
            default: op = "??"; break;
        }
        printf("%s %s, %s, %s\n", op, temp, $2, $4);
        // negate result
        char* temp2 = new_temp();
        printf("! %s, %s\n", temp2, temp);
        $$ = temp2;
    }
    | NOT L_PAREN bool_expr R_PAREN {
        char* temp = new_temp();
        printf("! %s, %s\n", temp, $3);
        $$ = temp;
    }
    | L_PAREN bool_expr R_PAREN {
        $$ = $2;
    }
    | expression {
        $$ = $1;
    }
    | TRUE {
        $$ = strdup("1");
    }
    | FALSE {
        $$ = strdup("0");
    }
    ;

comp: EQ   { $$ = $1; }
    | NEQ  { $$ = $1; }
    | LT   { $$ = $1; }
    | LTE  { $$ = $1; }
    | GT   { $$ = $1; }
    | GTE  { $$ = $1; }
    ;

expression
    : multiplicative_expr {
        $$ = $1;
    }
    | expression PLUS multiplicative_expr {
        char* temp = new_temp();
        printf("+ %s, %s, %s\n", temp, $1, $3);
        $$ = temp;
    }
    | expression MINUS multiplicative_expr {
        char* temp = new_temp();
        printf("- %s, %s, %s\n", temp, $1, $3);
        $$ = temp;
    }
    ;

multiplicative_expr
    : term {
        $$ = $1;
    }
    | multiplicative_expr MULT term {
        char* temp = new_temp();
        printf("* %s, %s, %s\n", temp, $1, $3);
        $$ = temp;
    }
    | multiplicative_expr DIV term {
        char* temp = new_temp();
        printf("/ %s, %s, %s\n", temp, $1, $3);
        $$ = temp;
    }
    | multiplicative_expr MOD term {
        char* temp = new_temp();
        printf("%% %s, %s, %s\n", temp, $1, $3);
        $$ = temp;
    }
    ;

term
    : var {
        $$ = $1;
    }
    | NUMBER {
        char* temp = malloc(20);
        sprintf(temp, "%d", $1);
        $$ = temp;
    }
    | L_PAREN expression R_PAREN {
        $$ = $2;
    }
    | MINUS term %prec UMINUS {
        char* temp = new_temp();
        printf("uminus %s, %s\n", temp, $2);
        $$ = temp;
    }
    | IDENTIFIER L_PAREN expressions R_PAREN {
        // function call, not handled
        $$ = strdup($1);
    }
    ;

var
    : IDENTIFIER {
        $$ = strdup($1);
    }
    | IDENTIFIER L_SQUARE_BRACKET expression R_SQUARE_BRACKET {
        char* temp = new_temp();
        printf("=[] %s, %s, %s\n", temp, $1, $3);
        $$ = temp;
    }
    ;

expressions: /* empty */
           | expression
           | expressions COMMA expression

           ;

%%

int main(int argc, char **argv) {
    yyparse();
    return 0;
}

void yyerror(const char *msg) {
    printf("Syntax error at line %d: %s\n", yylineno, msg);
}