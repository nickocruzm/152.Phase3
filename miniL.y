%{
    // Prologue
    #include <stdio.h>
    #include <stdlib.h>

    // int temp_count = 0;
    // int label_count = 0;
    // char* new_temp() {
    //     char* name = (char*) malloc(20);
    //     sprintf(name, "__temp__%d", temp_count++);
    //     return name;
    // }
    // char* new_label() {
    //     char* label = (char*) malloc(20);
    //     sprintf(label, "__label__%d", label_count++);
    //     return label;
    // }
    void yyerror(const char *msg);
    extern int num_lines;
    extern int num_column;
    FILE *yyin;
%}

%error-verbose
%union{
    char* id_val;
    int num_val;
}


// %locations

%token FUNCTION BEGINPARAMS ENDPARAMS BEGINLOCALS ENDLOCALS BEGINBODY ENDBODY
%token INTEGER ENUM ARRAY OF IF THEN ENDIF ELSE WHILE FOR DO BEGINLOOP ENDLOOP CONTINUE
%token READ WRITE RETURN
%token ASSIGN SEMICOLON COLON COMMA
%token L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET
%token PLUS MINUS MULT DIV MOD
%token <num_val> EQ NEQ LT LTE GT GTE
%token AND OR NOT
%token TRUE FALSE
%token <id_val> IDENT
%token <num_val> NUMBER
%type <num_val> comp
%type <id_val> vars
%type <id_val> statement bool_expr relation_and_expr relation_expr expression 
multiplicative_expr var term expressions
%type <id_val> term
%type <id_val> var


// /* Operator precedence and associativity (lowest to highest) */
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
// %start program

%%

prog_start: functions;

functions: /*empty*/
        | function functions;

// functions: function
//          | functions function;

function: FUNCTION ident SEMICOLON BEGINPARAMS declarations 
ENDPARAMS BEGINLOCALS declarations ENDLOCALS BEGINBODY statements ENDBODY;

declarations: /* empty */
            | declaration SEMICOLON declarations
            ;

declaration: identifiers COLON INTEGER SEMICOLON
           | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER SEMICOLON

           | identifiers COLON ENUM L_PAREN enum_list R_PAREN SEMICOLON

           ;

identifiers: ident 
           | ident COMMA identifiers
           ;

enum_list: ident
         | enum_list COMMA ident
         ;

statements: statement SEMICOLON
          | statement SEMICOLON statements
          ;

statement: var ASSIGN expression
    {
        printf("= %s, %s\n", $1, $3);
    }
    | IF bool_expr THEN statements ENDIF
    {
        char* true_label = new_label();
        char* end_label = new_label();
        printf("?:= %s, %s\n", $2, true_label);
        // false branch skips to end
        printf(":= %s\n", end_label);
        printf("%s:\n", true_label);
        // true branch statements will go here
        printf("%s:\n", end_label);
    }
    | IF bool_expr THEN statements ELSE statements ENDIF
    {
        char* else_label = new_label();
        char* end_label = new_label();
        printf("?:= %s, %s\n", $2, else_label);
        // true branch (statements)
        printf(":= %s\n", end_label);
        printf("%s:\n", else_label);
        // else branch (statements)
        printf("%s:\n", end_label);
    }
    | WHILE bool_expr BEGINLOOP statements ENDLOOP
    {
        char* start_label = new_label();
        char* end_label = new_label();
        printf("%s:\n", start_label);
        printf("?:= %s, %s\n", $2, end_label);
        // statements
        printf(":= %s\n", start_label);
        printf("%s:\n", end_label);
    }
    | DO BEGINLOOP statements ENDLOOP WHILE bool_expr
    {
        char* start_label = new_label();
        printf("%s:\n", start_label);
        // statements
        printf("?:= %s, %s\n", $6, start_label);
    }

    | READ vars{
        // assume vars is a single var for now
        printf(".< %s\n", $2);
    }
    | WRITE vars{
        printf("> %s\n", $2);
    }
    | CONTINUE{
        printf("continue\n");
    }
    | RETURN expression{
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
        char* temp = (char*) malloc(20);
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
    | ident L_PAREN expressions R_PAREN {
        char* temp = new_temp();
        // emit param for each expression in $3
        // $3 is a comma-separated list of expressions, but we have printed params already in expressions rule
        printf("call %s, %s\n", $1, temp);
        $$ = temp;
    }
    ;

var
    : ident {
        $$ = strdup($1);
    }
    | ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET {
        char* temp = new_temp();
        printf("=[] %s, %s, %s\n", temp, $1, $3);
        $$ = temp;
    }
    ;

expressions
    : /* empty */ {
        // empty argument list, no params
        $$ = NULL;
    }
    | expression {
        printf("param %s\n", $1);
        $$ = $1;
    }
    | expressions COMMA expression {
        // $1 may be NULL or last expression, but we only need to print param for $3
        printf("param %s\n", $3);
        $$ = $3;
    }
    ;


%%

int main(int argc, char **argv) {
    if(argc > 1){
        yyin = fopen(argv[1], "r");
        if(yyin == NULL){
            printf("syntax %s filename\n", argv[0]
        }
    }
    yyparse();
    return 0;
}

void yyerror(const char *msg){
    printf("Error: Line %d, position %d: %s \n", num_lines, num_column, msg);
}
ident
    : IDENT
    ;