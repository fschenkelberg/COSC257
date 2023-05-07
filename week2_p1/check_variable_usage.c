#include "ast/ast.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

// Define maximum number of variables
#define MAX_VARS 100

// Define symbol table structure
typedef struct {
    char* vars[MAX_VARS];
    int num_vars;
} SymbolTable;

// Define stack structure
typedef struct {
    SymbolTable* tables[MAX_VARS];
    int num_tables;
} SymbolTableStack;

// Initialize global stack variable
SymbolTableStack stack;

// Helper function to create a new symbol table and add it to the stack
void push_symbol_table() {
    SymbolTable* table = (SymbolTable*) malloc(sizeof(SymbolTable));
    table->num_vars = 0;
    stack.tables[stack.num_tables++] = table;
}

// Helper function to add a variable to the topmost symbol table in the stack
void add_to_symbol_table(char* var_name) {
    SymbolTable* table = stack.tables[stack.num_tables-1];
    table->vars[table->num_vars++] = var_name;
}

// Helper function to check if a variable is declared in any of the symbol tables in the stack
bool is_declared_in_symbol_table(char* var_name) {
    for (int i = stack.num_tables-1; i >= 0; i--) {
        SymbolTable* table = stack.tables[i];
        for (int j = 0; j < table->num_vars; j++) {
            if (strcmp(var_name, table->vars[j]) == 0) {
                return true;
            }
        }
    }
    return false;
}

// Recursive function to check variable usage
bool check_variable_usage(ASTNode* node) {
    if (node == NULL) {
        return true;
    }

    switch (node->type) {
        case AST_VAR_DECLARATION:
            add_to_symbol_table(node->variable_name);
            break;

        case AST_VARIABLE:
            if (!is_declared_in_symbol_table(node->variable_name)) {
                printf("Variable %s used before declaration.\n", node->variable_name);
                return false;
            }
            break;

        case AST_BLOCK_STATEMENT:
            push_symbol_table();
            for (int i = 0; i < node->num_statements; i++) {
                if (!check_variable_usage(node->statements[i])) {
                    return false;
                }
            }
            stack.num_tables--;
            break;

        case AST_FUNCTION:
            push_symbol_table();
            if (node->num_params > 0) {
                for (int i = 0; i < node->num_params; i++) {
                    add_to_symbol_table(node->param_names[i]);
                }
            }
            if (!check_variable_usage(node->body)) {
                return false;
            }
            stack.num_tables--;
            break;

        default:
            for (int i = 0; i < node->num_children; i++) {
                if (!check_variable_usage(node->children[i])) {
                    return false;
                }
            }
            break;
    }

    return true;
}
