%{
#include <stdlib.h>
#include <stdio.h>
#include "ast.h"
#include <string.h>
#include <unordered_set>
extern int yylex();
extern int yylex_destroy();
extern int yywrap();
void yyerror(const char *);
extern FILE *yyin;
extern int yylineno;

#define TABLE_SIZE 100

typedef struct Node {
    char *key; // Variable
    struct Node *next; // Next node
} Node;

Node *table[TABLE_SIZE]; // Hash table array

// Hash function: returns a hash value for the given key (variable name)
unsigned int hashfunc(char *key) {
    unsigned int hashval = 0;
    for (int i = 0; key[i] != '\0'; i++) {
        hashval = key[i] + 31 * hashval;
    }
    return hashval % TABLE_SIZE;
}

// Lookup function: returns 1 if the given key (variable name) is found in the hash table, 0 otherwise
int lookup(char *key) {
    unsigned int hashval = hashfunc(key);
    Node *p = table[hashval];
    while (p != NULL) {
        if (strcmp(p->key, key) == 0) {
            return 1;
        }
        p = p->next;
    }
    return 0;
}

// Insert function: inserts the given key (variable name) into the hash table
void insert(char *key) {
    unsigned int hashval = hashfunc(key);
    Node *p = table[hashval];
    while (p != NULL) {
        if (strcmp(p->key, key) == 0) {
            // Key already exists in table
            return;
        }
        p = p->next;
    }
    // Key not found in table, create a new node and insert it at the beginning of the list
    Node *new_node = (Node*) malloc(sizeof(Node));
    new_node->key = key;
    new_node->next = table[hashval];
    table[hashval] = new_node;
}
%}

/* Union for Token Values */
%union{
	int val_i;
	char *val_s;
	astNode *nptr;
}

/* Terminals */
%token <val_i> NUMBER
%token <val_s> NAME

%type <nptr> expression term

%start expression

/* The Mini-C Grammar */
%%
expression:
	term '+' term {
		$$ = createBExpr($1, $3, add);
	}
	| term '-' term {
		$$ = createBExpr($1, $3, sub);
	}
	| term '*' term {
		$$ = createBExpr($1, $3, mul);
	}
	| term '/' term {
		$$ = createBExpr($1, $3, divide);
	}
	| term {
		$$ = $1;
	}
	;

term:
	NUMBER {
		$$ = createCnst($1);
	}
	| NAME {
		// Push variables to hash table
		insert($1);
		$$ = createVar($1);
	}
	| '-' term {
		$$ = createUExpr($2, uminus);
	}
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

	/* Loop through the hash table and check if each inserted value is declared before use */
    for (int i = 0; i < TABLE_SIZE; i++) {
        if (table[i] != NULL) {
            /* Key found, check if declared before use */
            if (lookup(table[i]->key)) {
                printf("%s declared before use\n", table[i]->key);
            } else {
                printf("Attempted use before declaration for value %s\n", table[i]->key);
            }
        }
    }

	return 0;
}

void yyerror(const char *error_msg){
	fprintf(stdout, "<-\n%s at line %d\n", error_msg, yylineno);
}
