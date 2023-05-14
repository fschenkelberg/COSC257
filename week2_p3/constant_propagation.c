#include <llvm-c/Core.h>

// Perform constant propagation on function
void constantPropagation(LLVMValueRef func) {
    // Initialize IN and OUT sets of all basic blocks
    LLVMValueRef* worklist = (LLVMValueRef*)malloc(sizeof(LLVMValueRef) * LLVMCountBasicBlocks(func));
    LLVMValueRef* inSets = (LLVMValueRef*)malloc(sizeof(LLVMValueRef) * LLVMCountBasicBlocks(func));
    LLVMValueRef* outSets = (LLVMValueRef*)malloc(sizeof(LLVMValueRef) * LLVMCountBasicBlocks(func));
    int numBlocks = 0;
    LLVMValueRef bb = LLVMGetFirstBasicBlock(func);
    while (bb) {
        worklist[numBlocks++] = bb;
        inSets[numBlocks-1] = LLVMConstArray(LLVMInt32Type(), NULL, 0);
        outSets[numBlocks-1] = LLVMConstArray(LLVMInt32Type(), NULL, 0);
        bb = LLVMGetNextBasicBlock(bb);
    }
    // Dataflow analysis
    while (numBlocks > 0) {
        // Remove basic block from worklist
        LLVMValueRef currentBB = worklist[--numBlocks];
        // Compute GEN, KILL, IN, and OUT sets for the basic block
        LLVMValueRef genSet = computeGenSet(currentBB);
        LLVMValueRef killSet = computeKillSet(currentBB);
        LLVMValueRef inSet = computeInSet(currentBB, outSets, LLVMGetNumPredecessors(currentBB));
        LLVMValueRef outSet = computeOutSet(currentBB, genSet, inSet, killSet);
        // Check if the OUT set changed
        if (!LLVMIsConstantArrayEqual(outSet, outSets[numBlocks])) {
            // Propagate constants through instructions in basic block
            LLVMValueRef inst = LLVMGetFirstInstruction(currentBB);
            while (inst) {
                LLVMValueRef opcode = LLVMGetInstructionOpcode(inst);
                if (opcode == LLVMStore) {
                    LLVMValueRef storeValue = LLVMGetOperand(inst, 0);
                    LLVMValueRef storePointer = LLVMGetOperand(inst, 1);
                    if (LLVMIsConstant(storeValue)) {
                        LLVMReplaceAllUsesWith(storePointer, storeValue);
                    }
                } else {
                    int numOperands = LLVMGetNumOperands(inst);
                    for (int i = 0; i < numOperands; i++) {
                        LLVMValueRef operand = LLVMGetOperand(inst, i);
                        if (LLVMIsAInstruction(operand) && LLVMIsConstantArrayElement(outSet, operand)) {
                            LLVMReplaceAllUsesWith(inst, operand);
                            break;
                        }
                    }
                }
                inst = LLVMGetNextInstruction(inst);
            }
            // Update the OUT set
            // Add Successors to Worklist
            outSets[numBlocks] = outSet;
            LLVMValueRef succ = LLVMGetFirstSuccessor(currentBB);
            while (succ) {
                worklist[numBlocks++] = succ;
                succ = LLVMGetNextSuccessor(currentBB, succ);
            }
        }
    }
    free(worklist);
    free(inSets);
    free(outSets);
}

// Get all store instructions in basic block
LLVMValueRef* getStoreInstructions(LLVMValueRef bb, int* numStores) {
    LLVMValueRef* stores = (LLVMValueRef*)malloc(sizeof(LLVMValueRef) * LLVMCountBasicBlockInstructions(bb));
    LLVMValueRef inst = LLVMGetFirstInstruction(bb);
    int count = 0;
    while (inst) {
        if (LLVMGetInstructionOpcode(inst) == LLVMStore) {
            stores[count++] = inst;
        }
        inst = LLVMGetNextInstruction(inst);
    }
    *numStores = count;
    return stores;
}

// Compute the GEN set for basic block
LLVMValueRef computeGenSet(LLVMValueRef bb) {
    LLVMValueRef genSet = LLVMConstArray(LLVMInt32Type(), NULL, 0);
    LLVMValueRef* stores;
    int numStores;
    stores = getStoreInstructions(bb, &numStores);
    for (int i = 0; i < numStores; i++) {
        genSet = LLVMConstArrayInsert(genSet, stores[i], 0);
    }
    free(stores);
    return genSet;
}

// Compute the KILL set for basic block
LLVMValueRef computeKillSet(LLVMValueRef bb) {
    LLVMValueRef killSet = LLVMConstArray(LLVMInt32Type(), NULL, 0);
    LLVMValueRef* stores;
    int numStores;
    stores = getStoreInstructions(bb, &numStores);
    for (int i = 0; i < numStores; i++) {
        LLVMValueRef storeValue = LLVMGetOperand(stores[i], 0);
        LLVMValueRef storePointer = LLVMGetOperand(stores[i], 1);
        for (int j = 0; j < numStores; j++) {
            if (i != j && LLVMGetOperand(stores[j], 1) == storePointer) {
                killSet = LLVMConstArrayInsert(killSet, stores[j], 0);
            }
        }
    }
    free(stores);
    return killSet;
}

// Compute the IN set for basic block
LLVMValueRef computeInSet(LLVMValueRef bb, LLVMValueRef* outSets, int numPredecessors) {
    LLVMValueRef inSet = LLVMConstArray(LLVMInt32Type(), NULL, 0);
    for (int i = 0; i < numPredecessors; i++) {
        inSet = LLVMConstArrayMerge(inSet, outSets[i]);
    }
    return inSet;
}

// Compute the OUT set for basic block
LLVMValueRef computeOutSet(LLVMValueRef bb, LLVMValueRef genSet, LLVMValueRef inSet, LLVMValueRef killSet) {
    LLVMValueRef newOutSet = LLVMConstArrayInsert(inSet, genSet, 0);
    newOutSet = LLVMConstArrayRemoveMatchingElements(newOutSet, killSet);
    newOutSet = LLVMConstArrayMerge(newOutSet, genSet);
    return newOut;
}
