%{
	#include <stdio.h>
	#include <math.h>
	#include "ast.h"
	#include "y.tab.h"
	#include <string.h>
	#include<stdlib.h>
	extern void yyerror(const char *);
%}

%option yylineno

number				[1-9](([0-9]+)?)|0
letter				[a-zA-Z]
alphanum			[a-zA-Z0-9]
alphanum_us 		[a-zA-Z0-9_]
filename			{letter}{alphanum_us}*{alphanum}+

%%
{letter}{alphanum}*	{printf("%s", yytext); yylval.val_s = strdup(yytext); return NAME;}
{filename}			{printf("%s", yytext); yylval.val_s = strdup(yytext); return NAME;}
{number}				{printf("%s", yytext); yylval.val_i = atoi(yytext); return NUMBER;}

"+"|"-"|"*"|"/"|"="		{printf("%s", yytext); return yytext[0];}
";"|"("|")"|"{"|"}"		{printf("%s", yytext); return yytext[0];}

[\t ]+      { /* ignore whitespace */ }
.           { printf("Invalid character: %s\n", yytext); }
%%

int yywrap(){
	return 1;
}
