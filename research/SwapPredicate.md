Swap Predicate   
=====

## Overview
This document describes an architcture desgin of simple atomic swap predicate.

## Background

We attempted to design a deprecation logic that allows two different coin owners to swap their coins in a safe way given that both participants are online through out this swap process until their exits. 
  
This predicate could nest the [Collateral Predicate](https://hackmd.io/@yuriko/Sy0VQFneH#Collateral-predicate) to build [Lending Plapps](https://hackmd.io/@yuriko/Sy0VQFneH#Lending-Plapp) which was proposed by @syuhei176 before.


# Architecture
![]() - image will be inserted later

### **Swap between Alice ans Bob**
In the end, you want these following conditions. 
- [A->B]: Range A, which was previously owned by Alice, has to be transfered to Bob 
- [B->A]: Range B, which was previously owned by Bob, has to be transfered to Alice

### **Deprecation Logic** 
First, both ranges A and B exit as a conditional state A|B and B|A. This conditional state will be deprecated to confirm/cancel the swap process later.  

To assure that both of the swap participants can exchange their ranges as they agreed in a mutually benefitial way, 

1. Following deprecations of the conditioal state (A|B->B and B|A->A) is allowed only when  

- [A|B->B]: Bob has a confirmation signature from Alice, which claims that Alice agrees that the ownership of range A to be transfered Bob
- [B|A->A]: Alice has a confirmation signature from Bob, which claims that Bob agrees that the ownership of range B to be transfered to Alice

    Without them, the swap process will terminate and ownership of the coin will be simply transfered to the original owners. 

- ~~[A|B->B]~~: [A|B->A]
- ~~[B|A->A]~~: [B|A->B]

2. To 'startExit' their counterparty's coin, swap participants need a inclusion proof of its conditional state.  

3. If both of the conditional states' exits have been pending for n days of 'dispute period', then the ownership of the coin will be simply transfer back to the orginal owner. When one of the conditional state's exit is deprecated whereas the other one's deprecation has not been done, then extra dispute period will be executed on Layer 1 to confirm the ownership of the coin with conditional state.

### **Edge cases** 

#### Edge case 1
Suppose Alice is an honest user and the operator and her counterparty Bob are malliciously colluding. Alice owns a coin at block 1 and submits a state update to a conditional state A|B, but the operator puts a fraudulent exit in block 2 and then includes Alice's transaction in block 3. 

Alice can follow these steps to exit her coin without Bob's cooperation. 

1) Alice attemsps to exit from block1
2) Operator cancels Alice's exit by revelaing his invalid exit atempt transaction in block 3. (Otherwise, Alice's exit succeeds after n-1 more days)
3) Alcie can challenge the operator's exit using the inclusion proof of the conditional state. 

#### Edge case 2
Again, suppose Alice is an honest user here, and the operator and her counterparty Bob  are malliciously colluding.
Suppose the operator includes both Alice and Bob's coins' statUpdate to the conditional state A|B in block 1. Both Alice and Bob send confirmation signatures to each other,but the operator withholds Bob's confirmation signature in block 2. Therefore, only Bob can deprecate Alice's conditinal state exit with her confirmation signature.  

In this case, Alice can get her a coin from Bob with the following protocol; 

Applying rule 4, exited Bob's conditional state will be put on a trial with additional dispute period on Layer 1. Alice's coin's conditional state will be automatically deprecated with the inclusion proof of A|B in block 1 and Bob's confirmation signature in block 2.   





 
