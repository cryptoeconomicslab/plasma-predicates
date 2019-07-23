Swap Predicate   
=====

## Overview
This document describes an architcture desgin of simple atomic swap predicate.

## Background

@syuhei176, @tkmcttm, and I attempted to design a deprecation logic that allows two different coin owners to swap their coins in a safe way given that both participants are online through out this swap process until their exits. 

We got an idea of this deprecation logic from `atomic swap predicate` suggested by @karl [here](https://plasma.build/t/a-question-about-verify-deprecation/41/3). Thanks for giving us inspiration.  

Also credits to @benchain, who shared his insight on a potential attack reagarding atomic swap [here](https://plasma.build/t/fast-finality-predicate/79/4) before, it helped us to elaborate on the operator's withholding attack, explained later in the [Edge case 2]() section. 
  
As for use cases, this predicate could nest the [Collateral Predicate](https://hackmd.io/@yuriko/Sy0VQFneH#Collateral-predicate) to build [Lending Plapps](https://hackmd.io/@yuriko/Sy0VQFneH#Lending-Plapp) which was proposed by @syuhei176 before.


# Architecture
![]() - image will be inserted later

### **Swap between Alice ans Bob**
In the end, you want these following conditions. 
- [A->B]: Range A, which was previously owned by Alice, has to be transfered to Bob 
- [B->A]: Range B, which was previously owned by Bob, has to be transfered to Alice

### **Deprecation Logic** 
Definition: a conditional state X|Y symbolizes to be having two scenarios of state transitions later depending on the situations, either:

- both sides of the swap were included, so Y is the new owner; or
- only one side of the swap was included (the swap was unsuccessful), so X is still the owner. 

First, both coin A and B exit as a conditional state A|B and B|A, which will be deprecated later either to confirm or cancel the swap process.  

To assure that both of the swap participants can exchange their ranges as they agreed in a mutually benefitial way, 

1. The following conditioal state cannot be deprecated  by their counterparties unless   

- [A|B->B]: Bob has a **confirmation signature** from Alice, which claims that Alice agrees that the ownership of range A to be transfered Bob, and **inclusion proof** of `B|A` (corresponding StateUpdate).
- [B|A->A]: Alice has a **confirmation signature** from Bob, which claims that Bob agrees that the ownership of range B to be transfered to Alice, and **inclusion proof** of `A|B` (corresponding StateUpdate).

    **Each party sends a confirmation signature to the counterparty after checking that the conditional state of the counter party's coin is included in a block. 

    Without them, the swap process will terminate and ownership of the coin will be simply transfered to the original owners. 

- ~~[A|B->B]~~: [A|B->A]
- ~~[B|A->A]~~: [B|A->B]

2. To 'startExit'counterparty's coin, swap participants need a inclusion proof of its conditional state.  
Say Alice checked B|A was included, so she sent confirmation sig A to Bob. While waiting for Bob's confirmation signature, Alice can always guranteed an option to exit B|A in case Bob deprecates A|B without sending confirmation sig B to Alice. 

3. If both of the conditional states' exits have been pending for fixed n days of 'dispute period', then the ownership of the coin will be simply transfer back to the orginal owner. 

4. If one of the conditional state's exit is deprecated while the other one's deprecation has not been done, then extra dispute period will be executed on Layer 1 to confirm the swap.

### **Attack Scenarios** 

#### Attack Scenario 1
Suppose Alice is an honest user and the operator is maliciously colluding with her counterparty Bob. Alice and Bob own their coins at block 1 and submits a state update to a conditional state A|B and B|A in block 2. Then the operator frandulently attempt to exit coin B, which was supposed to be transfered to Alice, in block 3. 

Alice can protect her assets in either of the following ways. 

1)Op's exit happens before the confirmation: Alice can simply cancel her swap choosing not to send her confirmation signature to Bob 
2)Op's exit happens after the confirmation: Alcie can challenge the operator's fraudulent exit using the inclusion proof of coin B's conditional state B|A. 
 

#### Attack Scenario 2
Again, suppose Alice is an honest user here, and the operator is maliciously colluding with her counterparty Bob.
The operator includes both Alice and Bob's coins' statUpdate to the conditional state A|B and B|A in block 1. Both Alice and Bob send confirmation signatures to each other, but the operator withholds Bob's confirmation signature in block 2. Therefore, only Bob can deprecate Alice's conditinal state exit with her confirmation signature.  

In this case, Alice can exit coin A with the following protocol; 

Applying rule 4, exited B|A will be put on a trial with additional dispute period on Layer 1. Coin A's conditional state will be automatically deprecated with the inclusion proof of A|B in block 1 and Bob's confirmation signature in block 2.   
