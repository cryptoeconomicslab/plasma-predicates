DSL for plasma predicate
=====


Define a domain-specific language of predicates so that we can convey discussions more efficiently. It provides a scheme to decompose and assemble fraud proof verification logics.
Derived from https://github.com/cryptoeconomicslab/plasma-predicates/issues/31

Credits to PG who built a great foundation of the predicate.

# Problems to solve

It's not efficient to describe new predicates from scratch every time you create them. Researchers need a very profound background to understand the behavior of deprecation logic in the discussion. (for example, at plasma.build) Hence, I thought we should define notations for predicates so that everyone can smoothly be on the same page and share a new predicate design without any misinterpretation.
Secondly, it's generally important to look for a more primitive way of predicate designs. In this theory, we can break down a complex predicate into multiple simple predicates. That way, we will be able to generalize complex predicates more easily.

# How does it work in detail

## Dispute scheme and deprecation logic

* The dispute scheme is to approve the validity of a state.
* The deprecation logic is to approve who can deprecate a state in what timing.

```python
dispute(deprecation_logic(state))
```

* predicate is one of the dispute schemes.
* "deprecation logic" AND "deprecation logic" is logical conjunction.
* "deprecation logic" OR "deprecation logic" is logical disjunction.
* "dispute scheme" AND "dispute scheme" means "run two exits parallelly and get the logical conjunction of two results."
* "dispute scheme" OR "dispute scheme" means "run two exits parallelly and get the logical disjunction of the two results."

## Theorem

```python 
dispute(deprecationA(state) and deprecationB(state)) = dispute(deprecationA(state)) or dispute(deprecationB(state))
dispute(deprecationA(state) or deprecationB(state)) = dispute(deprecationA(state)) and dispute(deprecationB(state))
```

## Examples

### Fee predicate

This formula deformation stands for that "the transfer with fee predicate" can be split into fee predicate and ownership predicate.
`proveFee` checks that correct fee is assigned, and `proveTransfer` checks signature of previous owner.
To be precise, proveFee should check `transaction`, so it should be `proveFee(state, transaction)`, and also `proveTransfer(state)` should be `proveTransfer(state, transaction, witness)`.

```
predicate(proveFee(state) and proveTransfer(state))
 = predicate(proveFee(state)) or predicate(proveTransfer(state))
```

```
1. predicate(proveFee(state) and proveTransfer(state))
```	

1. means one predicate consists of two different deprecation logics, proveFee and proveDeprecation.

```
2. predicate(proveFee(state)) or predicate(proveTransfern(state))
```

2. means that two exits run simultaneously and the whole state should be able to exit when at least one of the two exits succeeds.


|name|a|b|c|d|
| --- | --- | --- | --- | --- |
| predicate(proveFee(state)) | T| T| F| F |
| predicate(proveTransfer(state)) | T| F| T| F|
| exitable | T| T| T| F|

### Simple swap predicate

Simple swap requires 3 predicates.

```
predicate(proveDeprecation(state) and proveInclusion(state.correspondent) and confirmation(state.correspondent))
	= predicate(proveDeprecation(state)) or predicate(proveInclusion(state.correspondent) and confirmation(state.correspondent))
	= predicate(proveDeprecation(state)) or predicate(proveInclusion(state.correspondent)) or predicate(confirmation(state.correspondent))
```

### Dex predicate

Dex predicate requires 3 predicates.

```
predicate(proveDeprecation(state)) or (predicate(finalizeExit(state.correspondent)) and predicate(proveDeprecation(state.correspondent)))
```

## Further research needed

### How can we denote combination of different dispute schemes?

For example, payment channel on predicate.

```
predicate(proveClose(openState)) and channel(deprecation(openState))
```

### How can we denote an extra dispute?

For example, a simple swap predicate we designed requires an extra dispute period. How can we denote it?

### Predicate development framework?

I think we can build development framework for predicate by combination of multiple predicates.


