%{
	#include <stdio.h>
	#include "ast.h"

	#include <string>
	#include <unordered_set>
	using namespace std;

	extern int yylex();
	extern int yylex_destroy();
	extern int yywrap();
	void yyerror(const char *);
	extern FILE *yyin;

	// Define the symbol table as a global variable
	unordered_set<string> symbol_table;

	// Helper function to check if a variable is declared
	void check_declaration(string var_name) {
		if (symbol_table.find(var_name) == symbol_table.end()) {
			fprintf(stderr, "Error: variable %s is used before declaration\n", var_name.c_str());
			exit(1);
		}
	}

	// Function to perform semantic analysis
	void perform_semantic_analysis(astNode* root) {
		// Traverse the AST and populate the symbol table
		for (auto child : root->children) {
			if (child->type == var_node) {
				symbol_table.insert(child->var.name);
			} else if (child->type == func_node) {
				symbol_table.insert(child->func.name);
			}
		}

		// Check if every variable is declared before use
		for (auto child : root->children) {
			if (child->type == asgn_node) {
				check_declaration(child->asgn.lhs->var.name);
			} else if (child->type == bin_expr_node) {
				check_declaration(child->bin_expr.lhs->var.name);
				check_declaration(child->bin_expr.rhs->var.name);
			} else if (child->type == ret_node) {
				check_declaration(child->ret.expr->var.name);
			} else if (child->type == call_node) {
				if (child->call.param != nullptr) {
					check_declaration(child->call.param->var.name);
				}
			} else if (child->type == decl_node) {
				if (symbol_table.find(child->decl.name) != symbol_table.end()) {
					fprintf(stderr, "Error: variable %s is already declared\n", child->decl.name);
					exit(1);
				} else {
					symbol_table.insert(child->decl.name);
				}
			}
		}
	}
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
%token READ PRINT IF ELSE WHILE RETURN LT GT LEQ GEQ EQ VOID INTEGER

/* Non-Terminals */
%type <nptr> expression term
%type <nptr> declaration_list

%start expression

/* The Mini-C Grammar */
%%
declaration_list:
  declaration_list NAME ';' {symbol_table.insert($2);}
  | NAME ';' {symbol_table.insert($1);}
  | expression {
	$$ = createAsgn(tnptr, $1);
  }
  ;

expression:
	term '+' term {
		// Check if variables are declared before use
		check_declaration($1->var.name);
		check_declaration($3->var.name);
		$$ = createBExpr($1, $3, add);
	}
	| term '-' term {
		// Check if variables are declared before use
		check_declaration($1->var.name);
		check_declaration($3->var.name);
		$$ = createBExpr($1, $3, sub);
	}
	| term '*' term {
		// Check if variables are declared before use
		check_declaration($1->var.name);
		check_declaration($3->var.name);
		$$ = createBExpr($1, $3, mul);
	}
	| term '/' term {
		// Check if variables are declared before use
		check_declaration($1->var.name);
		check_declaration($3->var.name);
		$$ = createBExpr($1, $3, divide);
	}

	| term {
		// Check if variable is declared before use
		check_declaration($1->var.name);
		$$ = $1;
	}
	;

term:
	NUMBER {
		$$ = createCnst($1);
	}
	| NAME {
		// Check if variable is declared before use
		check_declaration($1);
		$$ = createVar($1);
	}
	| '-' term {
		$$ = createUExpr($2, uminus);
	}
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

	perform_semantic_analysis(root);
	
	return 0;
}

void yyerror(const char *){
	fprintf(stderr, "Syntax error\n");
}
