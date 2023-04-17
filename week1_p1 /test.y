%{
#include<stdio.h>
#include<stdlib.h>
#include"y.tab.h"
extern int yylex();
extern int yylex_destroy();
extern FILE *yyin;
extern int yylineno;
extern char* yytext;
extern void yyerror(const char *);
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

%%
/* The miniC Grammar */
/* Non-terminals for variable declarations */
var_decl: type_specifier identifier SEMICOLON
        | type_specifier identifier ASSIGN expression SEMICOLON
        ;

type_specifier: INTEGER
              | VOID
              ;

identifier: NAME
          ;

/* Non-terminal for assignment statements */
assignment: identifier ASSIGN expression SEMICOLON
          ;

/* Non-terminal for return statements */
return_stmt: RETURN expression SEMICOLON
           | RETURN SEMICOLON
           ;

/* Non-terminals for if or if-else statements */
if_stmt: IF LPAREN expression RPAREN statement
       | IF LPAREN expression RPAREN statement ELSE statement
       ;

/* Non-terminal for while loop statement */
while_stmt: WHILE LPAREN expression RPAREN statement
           ;

/* Non-terminal for print statement */
print_stmt: PRINT LPAREN expression RPAREN SEMICOLON
           ;

/* Non-terminal for read statement */
read_stmt: READ LPAREN RPAREN SEMICOLON
          ;

expression: NUMBER
          | NAME
          | expression PLUS expression
          | expression MINUS expression
          | expression TIMES expression
          | expression DIVIDE expression
          | expression LT expression
          | expression GT expression
          | expression LEQ expression
          | expression GEQ expression
          | expression EQ expression
          | LPAREN expression RPAREN
          | MINUS expression %prec UMINUS
          ;

statement: var_decl
         | assignment
         | return_stmt
         | if_stmt
         | while_stmt
         | print_stmt
         | read_stmt
         ;

%%

int main(int argc, char** argv){
	if (argc == 2){
		yyin = fopen(argv[1], "r");
	}

	yyparse();

	if (yyin != stdin)
		fclose(yyin);

	yylex_destroy();
	
	return 0;
}

void yyerror(const char *error_msg){
	fprintf(stdout, "<-\n%s at line %d\n", error_msg, yylineno);
}
