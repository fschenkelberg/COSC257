%{
#include<stdio.h>
#include<stdlib.h>
#include"y.tab.h"
//#include"check_variable_usage.c"
extern int yylex();
extern int yylex_destroy();
extern FILE *yyin;
extern int yylineno;
extern char* yytext;
extern void yyerror(const char *);

/* Global variable to hold root node of AST */
//astNode* root = NULL;
%}

/* Terminals */
%token <val_i> NUMBER
%token <val_s> NAME
%token READ PRINT IF ELSE WHILE RETURN
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON COMMA
%token ASSIGN PLUS MINUS UMINUS TIMES DIVIDE LT GT LEQ GEQ EQ
%token EXTERN VOID INTEGER

%left PLUS MINUS
%left TIMES DIVIDE
%nonassoc UMINUS

/* Union for Token Values */
%union {
    int val_i;
    char* val_s;
}

/*
%type<val_i> expression
%type<val_s> type_specifier identifier
*/

%start file

%%
/* The miniC Grammar */
/* Non-terminals for variable declarations */
file: program //{ $$ = root }
        | file program
        ;

program: INTEGER NAME LPAREN type_specifier identifier RPAREN block_statement
        | EXTERN VOID PRINT LPAREN INTEGER RPAREN SEMICOLON
        | EXTERN INTEGER read_stmt
        ;

var_decl: type_specifier identifier SEMICOLON
        | type_specifier identifier ASSIGN expression SEMICOLON
        ;

type_specifier: INTEGER //{ $$ = $1 }
              | VOID //{ $$ = $1 }
              ;

identifier: NAME //{ $$ = $1 }
          ;

/* Non-terminal for assignment statements */
assignment: identifier ASSIGN expression SEMICOLON
            | identifier ASSIGN read_stmt
          ;

/* Non-terminal for return statements */
return_stmt: RETURN expression SEMICOLON
           | RETURN SEMICOLON
           ;

/* Non-terminals for if or if-else statements */
if_stmt: IF expression block_statement
       | IF expression block_statement ELSE block_statement
       ;

/* Non-terminal for while loop statement */
while_stmt: WHILE expression block_statement
           ;

/* Non-terminal for print statement */
print_stmt: PRINT expression SEMICOLON
           ;

/* Non-terminal for read statement */
read_stmt: READ LPAREN RPAREN SEMICOLON
          ;

expression: NUMBER //{ $$ = $1 }
          | identifier
          | expression PLUS expression //{ $$ = $1 + $3}
          | expression MINUS expression //{ $$ = $1 - $3}
          | expression TIMES expression //{ $$ = $1 * $3}
          | expression DIVIDE expression //{ $$ = $1 / $3}
          | expression LT expression //{ $$ = ($1 < $3) ? 1 : 0 }
          | expression GT expression //{ $$ = ($1 > $3) ? 1 : 0 }
          | expression LEQ expression //{ $$ = ($1 <= $3) ? 1 : 0 }
          | expression GEQ expression //{ $$ = ($1 >= $3) ? 1 : 0 }
          | expression EQ expression //{ $$ = ($1 == $3) ? 1 : 0 }
          | LPAREN expression RPAREN //{ $$ = $2 }
          | MINUS expression %prec UMINUS //{ $$ = -$2 }
          ;

block_statement: statement
        | LBRACE statement_list RBRACE
        ;

statement: var_decl
         | assignment
         | return_stmt
         | if_stmt
         | while_stmt
         | print_stmt
         | read_stmt
         ;

statement_list:
        statement
        | statement_list statement
        ;

%%

int main(int argc, char** argv) {
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    }

    yyparse();

    if (yyin != stdin) {
        fclose(yyin);
    }

    yylex_destroy();
    /*
    if (!check_variable_usage(root)) {
        printf("Semantic analysis failed.\n");
        return 1;
    }

    printf("Semantic analysis successful.\n");
    */
    return 0;
}


void yyerror(const char *error_msg){
	fprintf(stdout, "<-\n%s at line %d\n", error_msg, yylineno);
}
