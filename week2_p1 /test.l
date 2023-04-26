%{
#include<stdio.h>
#include <math.h>
#include<stdlib.h>
#include"y.tab.h"
extern void yyerror(const char *);
%}

%option yylineno
number				(\-?)[0-9]+
letter				[a-zA-Z]
alphanum			[a-zA-Z0-9]
alphanum_us 		[a-zA-Z0-9_]
filename			{letter}{alphanum_us}*{alphanum}+

%%
"("         {printf("%s", yytext); return LPAREN; }
")"         {printf("%s", yytext); return RPAREN; }
"{"         {printf("%s", yytext); return LBRACE; }
"}"         {printf("%s", yytext); return RBRACE; }
";"         {printf("%s", yytext); return SEMICOLON; }
","         {printf("%s", yytext); return COMMA; }
"="         {printf("%s", yytext); return ASSIGN; }
"+"         {printf("%s", yytext); return PLUS; }
"-"         {printf("%s", yytext); return MINUS; }
"-"         {printf("%s", yytext); return UMINUS; }
"*"         {printf("%s", yytext); return TIMES; }
"/"         {printf("%s", yytext); return DIVIDE; }
"<"         {printf("%s", yytext); return LT; }
">"         {printf("%s", yytext); return GT; }
"<="        {printf("%s", yytext); return LEQ; }
">="        {printf("%s", yytext); return GEQ; }
"=="        {printf("%s", yytext); return EQ; }
"read"      {printf("%s", yytext); return READ; }
"print"     {printf("%s", yytext); return PRINT; }
"if"        {printf("%s", yytext); return IF; }
"else"      {printf("%s", yytext); return ELSE; }
"while"     {printf("%s", yytext); return WHILE; }
"return"    {printf("%s", yytext); return RETURN; }

"int"       {printf("%s", yytext); return INTEGER; }
"extern"    {printf("%s", yytext); return EXTERN; }
"void"      {printf("%s", yytext); return VOID; }

{letter}{alphanum}*	{printf("%s", yytext); return NAME;}
{filename}			{printf("%s", yytext); return NAME;}
{number}			{printf("%s", yytext); return NUMBER;}

[\t ]+      { /* ignore whitespace */ }
.           { printf("Invalid character: %s\n", yytext); }
%%

int yywrap(){
	return 1;
}
