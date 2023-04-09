%{
#include <stdio.h>
#include <math.h>
#include "y.tab.h"
%}

%option yylineno
number				(\-?)[0-9]+
letter				[a-zA-Z]
alphanum			[a-zA-Z0-9]
alphanum_us 		[a-zA-Z0-9_]
filename			{letter}{alphanum_us}*{alphanum}+
file_ext			([\.]{letter}+)*
comment				(\/\/.*)
comment_			(\/\*(.|\n)+\*\/)

%%
"auto"				{printf("%s", yytext); return SPECIFIER;}
"register"			{printf("%s", yytext); return SPECIFIER;}
"static"			{printf("%s", yytext); return SPECIFIER;}
"extern"			{printf("%s", yytext); return SPECIFIER;}
"signed"			{printf("%s", yytext); return MODIFIER;}
"unsigned"			{printf("%s", yytext); return MODIFIER;}
"short"				{printf("%s", yytext); return MODIFIER;}
"long"				{printf("%s", yytext); return MODIFIER;}
"int"				{printf("%s", yytext); return TYPE;}
"char"				{printf("%s", yytext); return TYPE;}
"float"				{printf("%s", yytext); return TYPE;}
"double"			{printf("%s", yytext); return TYPE;}
"void"				{printf("%s", yytext); return TYPE;}
"if"				{printf("%s", yytext); return CONDITION;}
"else"				{printf("%s", yytext); return CONDITION;}
"switch"			{printf("%s", yytext); return CONDITION;}
"case"				{printf("%s", yytext); return CONDITION;}
"default"			{printf("%s", yytext); return CONDITION;}
"while"				{printf("%s", yytext); return CONDITION;}
"do"				{printf("%s", yytext); return CONDITION;}
"for"				{printf("%s", yytext); return CONDITION;}
"break"				{printf("%s", yytext); return CONDITION;}
"continue"			{printf("%s", yytext); return CONDITION;}
"goto"				{printf("%s", yytext); return CONDITION;}
"return"			{printf("%s", yytext); return RETURN;}
{comment}			{printf("%s", yytext); return COMMENT;}
{comment_}			{printf("%s", yytext); return COMMENT;}
{number}			{printf("%s", yytext); return NUMBER;}
{letter}{alphanum}*	{printf("%s", yytext); return FNAME;}
{filename}			{printf("%s", yytext); return FNAME;}
{file_ext}			{printf("%s", yytext); return EXT;}
";"					{printf("%s", yytext); return END;}
"+"					{printf("%s", yytext); return OPERATOR;}
"-"					{printf("%s", yytext); return OPERATOR;}
"*"					{printf("%s", yytext); return OPERATOR;}
"/"					{printf("%s", yytext); return OPERATOR;}
"%"					{printf("%s", yytext); return OPERATOR;}
"="					{printf("%s", yytext); return OPERATOR;}
"+="				{printf("%s", yytext); return OPERATOR;}
"-="				{printf("%s", yytext); return OPERATOR;}
"*="				{printf("%s", yytext); return OPERATOR;}
"/="				{printf("%s", yytext); return OPERATOR;}
"%="				{printf("%s", yytext); return OPERATOR;}
"<<="				{printf("%s", yytext); return OPERATOR;}
">>="				{printf("%s", yytext); return OPERATOR;}
"&="				{printf("%s", yytext); return OPERATOR;}
"^="				{printf("%s", yytext); return OPERATOR;}
"|="				{printf("%s", yytext); return OPERATOR;}
"++"				{printf("%s", yytext); return OPERATOR;}
"--"				{printf("%s", yytext); return OPERATOR;}
"=="				{printf("%s", yytext); return OPERATOR;}
"!="				{printf("%s", yytext); return OPERATOR;}
"<"					{printf("%s", yytext); return OPERATOR;}
">"					{printf("%s", yytext); return OPERATOR;}
"<="				{printf("%s", yytext); return OPERATOR;}
">="				{printf("%s", yytext); return OPERATOR;}
"!"					{printf("%s", yytext); return OPERATOR;}
"&&"				{printf("%s", yytext); return OPERATOR;}
"||"				{printf("%s", yytext); return OPERATOR;}
"&"					{printf("%s", yytext); return OPERATOR;}
"|"					{printf("%s", yytext); return OPERATOR;}
"^"					{printf("%s", yytext); return OPERATOR;}
"~"					{printf("%s", yytext); return OPERATOR;}
"<<"				{printf("%s", yytext); return OPERATOR;}
">>"				{printf("%s", yytext); return OPERATOR;}
"?"					{printf("%s", yytext); return OPERATOR;}
":"					{printf("%s", yytext); return OPERATOR;}
","					{printf("%s", yytext); return OPERATOR;}
"#"					{printf("%s", yytext); return OPERATOR;}
"."					{printf("%s", yytext); return OPERATOR;}
"->"				{printf("%s", yytext); return OPERATOR;}
"\\"				{printf("%s", yytext); return OPERATOR;}
"\xhh"				{printf("%s", yytext); return OPERATOR;}
"$"					{printf("%s", yytext); return OPERATOR;}
"\""				{printf("%s", yytext); return QUOTE;}
"\'"				{printf("%s", yytext); return QUOTE;}
"("					{printf("%s", yytext); return LPAREN;}
")"					{printf("%s", yytext); return RPAREN;}
"{"					{printf("%s", yytext); return LBRACK;}
"}"					{printf("%s", yytext); return RBRACK;}
[\t]+				{printf("%s", yytext); return WSP;}
[\n]+				{printf("%s", yytext); return WSP;}
[\r]+				{printf("%s", yytext); return WSP;}
%%

int yywrap(){
	return 1;
}
