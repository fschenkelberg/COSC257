#include "ast/ast.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>

bool check_variable_usage(ASTNode *node) {
    if (node == NULL) {
        return true;
    }

    switch (node->type) {
        case AST_VAR_DECLARATION:
            add_to_symbol_table(node->variable_name);
            break;

        case AST_VARIABLE:
            if (!is_declared_in_symbol_table(node->variable_name)) {
                return false;
            }
            break;

        default:
            for (int i = 0; i < MAX_CHILDREN; i++) {
                if (!check_variable_usage(node->children[i])) {
                    return false;
                }
            }
            break;
    }
    return true;
}
