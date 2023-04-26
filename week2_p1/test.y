%{
#include<stdio.h>
#include<stdlib.h>
#include"y.tab.h"
#include "ast.h"
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

/* Union for Token Values */
%union {
    int val_i;
    char* val_s;
    astNode *nptr;
    vector<astNode *> *svec_ptr;
}

/* Terminals */
%token <val_i> NUMBER
%token <val_s> NAME
%token READ PRINT IF ELSE WHILE RETURN LPAREN RPAREN LBRACE RBRACE SEMICOLON COMMA ASSIGN PLUS MINUS UMINUS TIMES DIVIDE LT GT LEQ GEQ EQ EXTERN VOID INTEGER

%left PLUS MINUS
%left TIMES DIVIDE
%nonassoc UMINUS

/*
%type<val_i> expression
%type<val_s> type_specifier identifier
*/

%start file

%%
/* The miniC Grammar */
/* Non-terminals for variable declarations */
file: program {$$ = createProg($1); printNode($$);} 
        | file program {$$ = createProg($2); printNode($$);} 
        ;

program: INTEGER NAME LPAREN type_specifier identifier RPAREN block_statement {$$ = createFunc($2, $5, $7);}
        | EXTERN VOID PRINT LPAREN INTEGER RPAREN SEMICOLON // astNode* ext1; /* extern function print */
        | EXTERN INTEGER read_stmt  // astNode* ext2; /* extern function read */
        ;

var_decl: type_specifier identifier SEMICOLON {$$ = createVar($2);}
        | type_specifier identifier ASSIGN expression SEMICOLON {$$ = createAsgn($2, $4);}
        ;

type_specifier: INTEGER //{ $$ = $1 }
              | VOID //{ $$ = $1 }
              ;

identifier: NAME {$$ = createVar($1);}
          ;

/* Non-terminal for assignment statements */
assignment: identifier ASSIGN expression SEMICOLON {$$ = createAsgn($1, $3);} 
            | identifier ASSIGN read_stmt {$$ = createAsgn($1, $3);} 
          ;

/* Non-terminal for return statements */
return_stmt: RETURN expression SEMICOLON {$$ = createRet($2);}
           ;

/* Non-terminals for if or if-else statements */
if_stmt: IF expression block_statement {$$ = createIf($2, $3, NULL);}
       | IF expression block_statement ELSE block_statement {$$ = createIf($2, $3, $5);}
       ;

/* Non-terminal for while loop statement */
while_stmt: WHILE expression block_statement {$$ = createWhile($2, $3);}
           ;

/* Non-terminal for print statement */
print_stmt: PRINT expression SEMICOLON // astNode* ext1; /* extern function print */
           ;

/* Non-terminal for read statement */
read_stmt: READ LPAREN RPAREN SEMICOLON // astNode* ext2; /* extern function read */
          ;

expression: NUMBER {$$ = createCnst($1);}
          | identifier {$$ = createVar($1);}
          | expression PLUS expression {$$ = createBExpr($1, $3, add);}
          | expression MINUS expression {$$ = createBExpr($1, $3, sub);}
          | expression TIMES expression {$$ = createBExpr($1, $3, mul);}
          | expression DIVIDE expression {$$ = createBExpr($1, $3, divide);}
          | expression LT expression {$$ = createRExpr($1, $3, lt);}
          | expression GT expression {$$ = createRExpr($1, $3, gt);}
          | expression LEQ expression {$$ = createRExpr($1, $3, le);}
          | expression GEQ expression {$$ = createRExpr($1, $3, ge);}
          | expression EQ expression {$$ = createRExpr($1, $3, eq);}
          | LPAREN expression RPAREN { $$ = $2 }
          | MINUS expression %prec UMINUS { $$ = createUExpr($2, uminus);}
          ;

block_statement: statement {$$ = createBlock($1); printNode($$);}
        | LBRACE statement_list RBRACE {$$ = createBlock($2); printNode($$);}
        ;

statement: var_decl // { $$ = $1 }
         | assignment // { $$ = $1 }
         | return_stmt // { $$ = $1 }
         | if_stmt // { $$ = $1 }
         | while_stmt // { $$ = $1 }
         | print_stmt // { $$ = $1 }
         | read_stmt // { $$ = $1 }
         ;

statement_list:
        statement {$$ = new vector<astNode*> (); $$->push_back($1);}
        | statement_list statement {$$ = $1; $$->push_back($2);}
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