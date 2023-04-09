%token SPECIFIER MODIFIER TYPE CONDITION FUNCTION COMMENT FNAME EXT OPERATOR TAB END NUMBER QUOTE RETURN
%token LPAREN RPAREN LBRACK RBRACK WSP

%{
#include <stdio.h>
void yyerror(const char *);
extern int yylex();
extern int yylex_destroy();
extern FILE *yyin;
extern int yylineno;
extern char* yytext;
%}

%start RULELIST
%%
/* The miniC Grammar */
RULELIST:
	WSPS
	| RULES WSPS
	| RULELIST RULES WSPS
	;

RULES:
	COMMENT
	| STATEMENTS
	| CONDITIONS
	| RETURNS
	;

// EXAMPLE: func(int a){}
// print(loc1)
FUNCTIONS:
	TYPES FNAME LPAREN DECLARATION RPAREN FUNCTIONSS
	;

FUNCTIONSS:
	/* empty */
	| LBRACK /* empty */ RBRACK
	| LBRACK RULELIST RBRACK
	;

// EXAMPLE: if (loc1 > loc2) {}
// else {}
// while (i < loc1){}
CONDITIONS:
	CONDITION CONDITIONSS LBRACK /* empty */ RBRACK
	| CONDITION CONDITIONSS LBRACK RULELIST RBRACK
	;

CONDITIONSS:
	/* empty */
	| WSPS LPAREN WSPS FNAME WSPS OPERATORS WSPS RPAREN WSPS
	;

WSPS:
	/* empty */
	| WSP
	;

// RETURN
RETURNS:
	RETURN LPAREN RETURNSS
	;

RETURNSS:
	ASSIGNMENT RPAREN END
	| NUMBER RPAREN END
	;

// EXAMPLE: extern void int loc1 = a + 10;
STATEMENTS:
	SPECIFIERS MODIFIERS STATEMENTSS
	;

STATEMENTSS:
	DECLARATION END
	| FUNCTIONS
	| FUNCTIONS END
	;

DECLARATION:
	/* empty */
	| TYPES ASSIGNMENT
	;

ASSIGNMENT:
	FNAME
	| FNAME OPERATORS
	;

/* Zero or More */
SPECIFIERS:
	/* empty */
	| SPECIFIERS SPECIFIER
	;

MODIFIERS:
	/* empty */
	| MODIFIERS MODIFIER
	;

/* One or More */
OPERATORS:
	OPERATOR NUMBER
	| OPERATOR FNAME
	| OPERATOR QUOTE FNAME QUOTE
	| OPERATORS OPERATOR NUMBER
	| OPERATORS OPERATOR FNAME
	| OPERATORS OPERATOR QUOTE FNAME QUOTE
	;

/* Zero or One */
TYPES:
	/* empty */
	| TYPE
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
