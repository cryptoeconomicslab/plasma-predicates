Swap Predicate   
=====

# Overview
This document describes an architcture desgin of simple atomic swap predicate, which also covers its several edge cases(WIP)

## Background(iranai kamo, if needed you can edit this section later)

Previously, we were not sure how to prevent one of the recepient's invalid exit in this conditional swap. 

## Abstract

We attempted to design a predicate logic to safely swap coins. 
Major breakthrough to mention from this design is  
- By having a step of dprecation to confirm the swap in the end, invalid exit from one of the swap participants  will be challengable for the new owner of the coin after the swap.  

## Usecase 

This predicate could be nested in the [collateral predicate](https://hackmd.io/@yuriko/Sy0VQFneH#Collateral-predicate) to build [Lending Plapps](https://hackmd.io/@yuriko/Sy0VQFneH#Lending-Plapp).
It might be needless to say, but the benefit of allowing this kind of swaps on Plsma is to reduce the gas cost and time to confirmation for users with a high fund security. 

# Architecture
![](https://i.imgur.com/rVLTCc2.jpg)

### Swap between A<->B
In the end, you want 

- [A->B]: The ownership of Range A, which was previously owned by Alice, have to be transfered to Bob 
- [B->A]: The ownership of Range B, which was previously owned by Bob, has to be transfered to Alice

However, these transactions below should not be completed without 

- [A|B->B]: Sig(B)1 + inclusion proof of this deprecation represented by the arrow with Sig(B)1
- [B|A->A]: Sig(A)1 + inclusion proof of this deprecation represented by the arrow with Sig(A)1

Without them, the ownership of the coin will be simply retuned to the original owners. 

- ~~[A|B->B]~~: [A|B->A]
- ~~[B|A->A]~~: [B|A->B]

To prevent invalid exits from the swap participants after the swap (represented by an "exit" arrow from B), both Alice and Bob have to sign a transaction to confirm this swap.
- [A|B->B] : Sig(A)2 
- [B|A->A] : Sig(B)2 


This way, even if there is an invalid exit attempt by the swap participants colluding with each other, Carol can challenge Bob's invalid exit submitting Sig(A)2 and its inclusion proof, claiming that the ownership of coin B has already been transfered to Carol. 
