%{
/*

Author: Felicia Schenkelberg

Version: 9.0

Description: 

This parser serves the purpose of analyzing a MiniC
script, ensuring program correctness, verifying that
every variable is declared before use, generating
LLVM IR from the Abstract Syntax Tree (AST), and
optimizing the LLVM IR through constant propagation
and dead code elimination. Ultimately, it produces
assembly code from the optimized LLVM IR.

Code Refernces:
"Engineering a compiler" Keith D. Cooper & Linda Torczon
"Compilers: Principles, Techniques, and Tools" Alfred V. Aho, Ravi Sethi, and Jeffrey D. Ullman
"Crafting a Compiler with C" Charles N. Fisher & Rhichard J. LeBlanc, Jr.
"Lex & Yacc" John R. Levine, Tony Mason, & Doug Brown

 */

#include "ast.h"
#include <llvm-c/Analysis.h>
#include <llvm-c/Core.h>
#include <llvm-c/ExecutionEngine.h>
#include <llvm-c/IRReader.h>
#include <llvm-c/Support/FileSystem.h>
#include <llvm-c/Target.h>
#include <llvm-c/TargetMachine.h>
#include <llvm-c/TargetOptions.h>
#include <llvm-c/Transforms/Scalar.h>
#include <llvm-c/Types.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unordered_set>

#define INITIAL_TABLE_SIZE 10
#define LOAD_FACTOR_THRESHOLD 0.7
#define prt(x) if(x) { printf("%s\n", x); }

extern FILE *yyin;

extern int yylex_destroy();
extern int yylex();
extern int yylineno;
extern int yywrap();

void yyerror(const char *);

// Structure for symbol table entry
typedef struct SymbolEntry {
    char* key;
    astNode* value;
    struct SymbolEntry* next;
} SymbolEntry;

// Structure for symbol table
typedef struct SymbolTable {
    SymbolEntry** table;
    unsigned int size;
    unsigned int count;
} SymbolTable;

// Hash function
unsigned int myHash(const char* key, unsigned int tableSize) {
    unsigned int hashval = 0;
    for (int i = 0; i < strlen(key); i++) {
        hashval = (hashval << 5) + key[i];
    }
    return hashval % tableSize;
}

// Create a new symbol table entry
SymbolEntry* createEntry(const char* key, astNode* value) {
    SymbolEntry* entry = (SymbolEntry*)malloc(sizeof(SymbolEntry));
    entry->key = strdup(key);
    entry->value = value;
    entry->next = NULL;
    return entry;
}

// Create a new symbol table
SymbolTable* createSymbolTable(unsigned int size) {
    SymbolTable* symbolTable = (SymbolTable*)malloc(sizeof(SymbolTable));
    symbolTable->table = (SymbolEntry**)calloc(size, sizeof(SymbolEntry*));
    symbolTable->size = size;
    symbolTable->count = 0;
    return symbolTable;
}

// Insert a new key-value pair into the symbol table
void insert(SymbolTable* symbolTable, const char* key, astNode* value) {
    unsigned int index = myHash(key, symbolTable->size);
    SymbolEntry* entry = createEntry(key, value);

    // If the bucket is empty, insert at the beginning
    if (symbolTable->table[index] == NULL) {
        symbolTable->table[index] = entry;
    } else {
        // If the bucket is not empty, append to the end
        SymbolEntry* current = symbolTable->table[index];
        while (current->next != NULL) {
            current = current->next;
        }
        current->next = entry;
    }

    symbolTable->count++;

    // Resize the table if load factor exceeds the threshold
    if ((double)symbolTable->count / symbolTable->size > LOAD_FACTOR_THRESHOLD) {
        unsigned int newSize = symbolTable->size * 2;
        SymbolEntry** newTable = (SymbolEntry**)calloc(newSize, sizeof(SymbolEntry*));

        // Rehash all the entries
        for (unsigned int i = 0; i < symbolTable->size; i++) {
            SymbolEntry* current = symbolTable->table[i];
            while (current != NULL) {
                SymbolEntry* next = current->next;
                unsigned int newIndex = myHash(current->key, newSize);
                current->next = newTable[newIndex];
                newTable[newIndex] = current;
                current = next;
            }
        }

        // Free the old table
        free(symbolTable->table);

        // Update the symbol table with the new table and size
        symbolTable->table = newTable;
        symbolTable->size = newSize;
    }
}

// Search for a key in the symbol table and return its value
astNode* lookup(SymbolTable* symbolTable, const char* key) {
    unsigned int index = myHash(key, symbolTable->size);
    SymbolEntry* current = symbolTable->table[index];
    while (current != NULL) {
        if (strcmp(current->key, key) == 0) {
            return current->value;
        }
        current = current->next;
    }
    return NULL;  // Not found
}

// Free the memory used by the symbol table and its entries
void freeSymbolTable(SymbolTable* symbolTable) {
    for (unsigned int i = 0; i < symbolTable->size; i++) {
        SymbolEntry* current = symbolTable->table[i];
        while (current != NULL) {
            SymbolEntry* next = current->next;
            free(current->key);
            free(current);
            current = next;
        }
    }
    free(symbolTable->table);
    free(symbolTable);
}

/* Constant propagation and dead code elimination on LLVM IR */
LLVMModuleRef createLLVMModel(char* filename) {
    char* err = 0;

    LLVMMemoryBufferRef ll_f = 0;
    LLVMModuleRef m = 0;

    LLVMCreateMemoryBufferWithContentsOfFile(filename, &ll_f, &err);

    if (err != NULL) {
        prt(err);
        return NULL;
    }

    LLVMParseIRInContext(LLVMGetGlobalContext(), ll_f, &m, &err);

    if (err != NULL) {
        prt(err);
    }

    return m;
}

LLVMValueRef foldBinOp(LLVMValueRef inst) {
    LLVMValueRef op0 = LLVMGetOperand(inst, 0);
    LLVMValueRef op1 = LLVMGetOperand(inst, 1);
    LLVMOpcode opcode = LLVMGetInstructionOpcode(inst);
    if (LLVMIsAConstant(op0) && LLVMIsAConstant(op1)) {
        LLVMValueRef constant;
        if (opcode == LLVMAdd) {
            constant = LLVMConstAdd(op0, op1);
        } else if (opcode == LLVMSub) {
            constant = LLVMConstSub(op0, op1);
        } else if (opcode == LLVMMul) {
            constant = LLVMConstMul(op0, op1);
        }
        LLVMReplaceAllUsesWith(inst, constant);
        LLVMInstructionEraseFromParent(inst);
        return constant;
    }
    return inst;
}

void eliminateDeadCode(LLVMValueRef inst) {
    if (LLVMGetNumUses(inst) == 0) {
        LLVMInstructionEraseFromParent(inst);
    }
}

void eliminateSubexpr(LLVMValueRef inst) {
    if (LLVMIsAInstruction(inst) && LLVMGetNumOperands(inst) == 2) {
        LLVMValueRef op0 = LLVMGetOperand(inst, 0);
        LLVMValueRef op1 = LLVMGetOperand(inst, 1);
        if (LLVMIsAInstruction(op0) && LLVMIsAInstruction(op1) &&
            LLVMGetInstructionOpcode(op0) == LLVMGetInstructionOpcode(op1) &&
            LLVMTypeOf(op0) == LLVMTypeOf(op1)) {
            LLVMValueRef subexpr = LLVMGetOperand(op0, 0);
            LLVMValueRef temp = LLVMGetOperand(op1, 0);
            LLVMReplaceAllUsesWith(op1, subexpr);
            LLVMSetOperand(op1, 0, subexpr);
            LLVMInstructionEraseFromParent(op0);
            eliminateDeadCode(temp);
        }
    }
}

void constantPropagation(LLVMValueRef func) {
    for (LLVMBasicBlockRef basicBlock = LLVMGetFirstBasicBlock(func); basicBlock; basicBlock = LLVMGetNextBasicBlock(basicBlock)) {
        for (LLVMValueRef instruction = LLVMGetFirstInstruction(basicBlock); instruction; instruction = LLVMGetNextInstruction(instruction)) {
            eliminateDeadCode(instruction);
            LLVMValueRef foldedInst = foldBinOp(instruction);
            eliminateSubexpr(foldedInst);
        }
    }
}

/* Generated and Optimized LLVM IR Code */
void generateLLVMIRAndOptimize(int argc, char *argv[]) {
    // LLVM IR Generation
    LLVMInitializeCore(LLVMGetGlobalPassRegistry());
    LLVMInitializeNativeTarget();
    LLVMInitializeNativeAsmPrinter();
    LLVMInitializeNativeAsmParser();

    // Create LLVM IR module
    LLVMModuleRef module = LLVMModuleCreateWithName("my_module");

    // Create a function prototype
    LLVMTypeRef funcArgs[] = { LLVMInt32Type(), LLVMInt32Type() };
    LLVMTypeRef funcType = LLVMFunctionType(LLVMInt32Type(), funcArgs, 2, 0);
    LLVMValueRef mainFunc = LLVMAddFunction(module, "main", funcType);
    LLVMBasicBlockRef entryBlock = LLVMAppendBasicBlock(mainFunc, "entry");

    // Set the builder to the entry block
    LLVMBuilderRef builder = LLVMCreateBuilder();
    LLVMPositionBuilderAtEnd(builder, entryBlock);

    // Generate LLVM IR code
    LLVMValueRef a = LLVMBuildAlloca(builder, LLVMInt32Type(), "a");
    LLVMValueRef constant = LLVMConstInt(LLVMInt32Type(), 42, 0);
    LLVMBuildStore(builder, constant, a);
    LLVMValueRef value = LLVMBuildLoad(builder, a, "value");
    LLVMBuildRet(builder, value);

    // Verify the module
    char *error = NULL;
    LLVMVerifyModule(module, LLVMPrintMessageAction, &error);
    if (error) {
        fprintf(stderr, "LLVMVerifyModule: %s\n", error);
        LLVMDisposeMessage(error);
        return;
    }

    // Dump the generated LLVM IR code
    LLVMDumpModule(module);

    // Clean up resources
    LLVMDisposeBuilder(builder);
    LLVMDisposeModule(module);

    // Optimization
    LLVMModuleRef m;

    if (argc == 2) {
        m = createLLVMModel(argv[1]);
    } else {
        m = NULL;
        return;
    }

    if (m != NULL) {
        LLVMValueRef mainFunc = LLVMGetNamedFunction(m, "main");
        if (mainFunc != NULL) {
            constantPropagation(mainFunc);
        }
    } else {
        printf("m is NULL\n");
    }

    // Generate assembly code
    LLVMInitializeX86TargetInfo();
    LLVMInitializeX86Target();
    LLVMInitializeX86TargetMC();
    LLVMInitializeX86AsmParser();
    LLVMInitializeX86AsmPrinter();

    // Create LLVM IR module
    module = LLVMModuleCreateWithName("my_module");

    // Create a function prototype
    funcType = LLVMFunctionType(LLVMInt32Type(), NULL, 0, 0);
    mainFunc = LLVMAddFunction(module, "main", funcType);
    entryBlock = LLVMAppendBasicBlock(mainFunc, "entry");

    // Set the builder to the entry block
    builder = LLVMCreateBuilder();
    LLVMPositionBuilderAtEnd(builder, entryBlock);

    // Generate LLVM IR code
    constant = LLVMConstInt(LLVMInt32Type(), 42, 0);
    LLVMBuildRet(builder, constant);

    // Create target machine
    LLVMTargetRef target = LLVMGetFirstTarget();
    LLVMCodeGenOptLevel optLevel = LLVMCodeGenLevelDefault;
    LLVMRelocMode relocMode = LLVMRelocDefault;
    LLVMCodeModel codeModel = LLVMCodeModelDefault;
    LLVMTargetMachineRef targetMachine = LLVMCreateTargetMachine(target, LLVMGetDefaultTargetTriple(), "", "", optLevel, relocMode, codeModel);

    // Create a target data layout
    char *dataLayout = LLVMCreateTargetDataLayout(targetMachine);
    LLVMSetModuleDataLayout(module, dataLayout);

    // Create a target machine's subtarget
    LLVMTargetMachineSetAsmVerbosity(targetMachine, 1);
    LLVMTargetMachineEmitToFile(targetMachine, module, "output.s", LLVMAssemblyFile, NULL);

    // Clean up resources
    LLVMDisposeBuilder(builder);
    LLVMDisposeModule(module);
    LLVMDisposeTargetMachine(targetMachine);
    LLVMDisposeTargetData(dataLayout);
    LLVMShutdown();
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

%{
    SymbolTable* symbolTable;
%}

%%
/* The Mini-C Grammar */
program:
        statement end
        | program statement end

end:
        /* empty */
        | ';'

statement:
        expression
        | assign_stmt
        | return_stmt
        | if_stmt
        | while_stmt
        | print_stmt
        | read_stmt
        block_stmt
        ;

/* Non-terminal for return statements */
return_stmt: "return" expression 
           | "return" 
           ;

/* Non-terminals for if or if-else statements */
if_stmt: "if" '(' expression ')' statement
       | "if" '(' expression ')' statement "else" statement
       ;

/* Non-terminal for while loop statement */
while_stmt: "while" '(' expression ')' statement
           ;

/* Non-terminal for print statement */
print_stmt: "print" '(' expression ')' 
           ;

/* Non-terminal for read statement */
read_stmt: "read" '(' ')' 
          ;

/* Non-terminal for assignment statements */
assign_stmt:
    NAME '=' expression {
        // Push variables to hash table
        insert(symbolTable, $1, $3);
    }
    ;

block_stmt:
        '{' statement '}'

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
    | term '<' term {
        $$ = createRExpr($1, $3, lt);
    }
    | term '>' term {
        $$ = createRExpr($1, $3, gt);
    }
    | term "<=" term {
        $$ = createRExpr($1, $3, le);
    }
    | term ">=" term {
        $$ = createRExpr($1, $3, ge);
    }
    | term "==" term {
        $$ = createRExpr($1, $3, eq);
    }
    | term "!=" term {
        $$ = createRExpr($1, $3, neq);
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
        $$ = createVar($1);
    }
    | '-' term {
        $$ = createUExpr($2, uminus);
    }
    ;
%%

int main(int argc, char** argv) {
    symbolTable = createSymbolTable(INITIAL_TABLE_SIZE); // Initialize symbol table

    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    }

    yyparse();

    if (yyin != stdin) {
        fclose(yyin);
    }

    yylex_destroy();

    // Check if each inserted value is declared before use
    for (unsigned int i = 0; i < symbolTable->size; i++) {
        SymbolEntry* current = symbolTable->table[i];
        while (current != NULL) {
            printf("Checking key: %s\n", current->key);
            // Perform your checks here
            if (lookup(symbolTable, current->key) == NULL) {
                printf("Value %s is used without declaration!\n", current->key);
            }
            current = current->next;
        }
    }

    // Free the memory used by the symbol table
    freeSymbolTable(symbolTable);

    //generateLLVMIRAndOptimize();

    return 0;
}

void yyerror(const char* error_msg) {
    fprintf(stdout, "<-\n%s at line %d\n", error_msg, yylineno);
}
