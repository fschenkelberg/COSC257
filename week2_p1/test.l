%{
	#include <stdio.h>
	#include <string.h>
	#include "y.tab.h"
	#include "ast.h"
%}

letter				[a-zA-Z]
digit				[0-9]
alphanum_us			[a-zA-Z0-9_]

%%
"int"		{printf("%s", yytext); return INTEGER;}
"void"		{printf("%s", yytext); return VOID;}
"read"		{printf("%s", yytext); return READ;}
"print"		{printf("%s", yytext); return PRINT;}
"return"	{printf("%s", yytext); return RETURN;}
"if"		{printf("%s", yytext); return IF;}
"else"		{printf("%s", yytext); return ELSE;}
"while"		{printf("%s", yytext); return WHILE;}
"extern"	{printf("%s", yytext); return WHILE;}

{letter}{alphanum_us}*	{ yylval.val_s = strdup(yytext); return NAME;}
[1-9]{digit}+			{ yylval.val_i = atoi(yytext); return NUMBER;}


"+" | "-" | "*" | "/" | "=" | ";" | "(" | ")" | "{" | "}"	{printf("%s", yytext); return yytext[0];}

">"			{printf("%s", yytext); return GT;}
"<"			{printf("%s", yytext); return LT;}
"=="		{printf("%s", yytext); return EQ;}
">="		{printf("%s", yytext); return GEQ;}
"<="		{printf("%s", yytext); return LEQ;}


.|[ \t\n]
%%

int yywrap(){
	return 1;
}
