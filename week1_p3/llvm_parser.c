/*
Original code rights belong to Professore Kommineni.

The function walkBBInstructions was modified to instead
apply functions to optimize code.

Note: The functions eliminateDeadCode, foldBinOp, and eliminateSubexpr
were added for this purpose.

The LLVM functions used for these optimization are: 
    LLVMReplaceAllUsesWith
	LLVMInstructionEraseFromParent
    LLVMConstAdd 
    LLVMConstSub
    LLVMConstMul
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <llvm-c/ExecutionEngine.h>
#include <llvm-c/Target.h>
#include <llvm-c/Transforms/Scalar.h>
#include <llvm-c/Core.h>
#include <llvm-c/IRReader.h>
#include <llvm-c/Types.h>

#define prt(x) if(x) { printf("%s\n", x); }

LLVMModuleRef createLLVMModel(char * filename){
	char *err = 0;

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

LLVMValueRef foldBinOp(LLVMValueRef inst){
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

void eliminateDeadCode(LLVMValueRef inst){
    if (LLVMGetNumUses(inst) == 0) {
        LLVMInstructionEraseFromParent(inst);
    }
}

void eliminateSubexpr(LLVMValueRef inst){
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

void walkBBInstructions(LLVMBasicBlockRef bb){
    for (LLVMValueRef instruction = LLVMGetFirstInstruction(bb); instruction;
        instruction = LLVMGetNextInstruction(instruction)) {
        eliminateDeadCode(instruction);
        LLVMValueRef foldedInst = foldBinOp(instruction);
        eliminateSubexpr(foldedInst);
    }
}

void walkBasicblocks(LLVMValueRef function){
	for (LLVMBasicBlockRef basicBlock = LLVMGetFirstBasicBlock(function);
 			 basicBlock;
  			 basicBlock = LLVMGetNextBasicBlock(basicBlock)) {
		
		printf("In basic block\n");
		walkBBInstructions(basicBlock);
	}
}

void walkFunctions(LLVMModuleRef module){
	for (LLVMValueRef function =  LLVMGetFirstFunction(module); 
			function; 
			function = LLVMGetNextFunction(function)) {

		const char* funcName = LLVMGetValueName(function);	

		printf("Function Name: %s\n", funcName);

		walkBasicblocks(function);
 	}
}

void walkGlobalValues(LLVMModuleRef module){
	for (LLVMValueRef gVal =  LLVMGetFirstGlobal(module);
                        gVal;
                        gVal = LLVMGetNextGlobal(gVal)) {

                const char* gName = LLVMGetValueName(gVal);
                printf("Global variable name: %s\n", gName);
        }
}

int main(int argc, char** argv)
{
	LLVMModuleRef m;

	if (argc == 2){
		m = createLLVMModel(argv[1]);
	} else {
		m = NULL;
		return 1;
	}

	if (m != NULL){
		walkFunctions(m);
	} else {
	    printf("m is NULL\n");
	}
	
	return 0;
}
