## Overview

Clarify users can move to another plasma with one StateUpdate.

## What problem can be solved

Many users can move their assets with lower cost with both operator's help and without operator's help cases.

## How does it work in detail

### Preconditinos

Now there are root Deposit contract, Commitment contract and a predicate which is Deposit contract. Some users sign the predicate in a certain block.
What happens when user exit from only root Deposit contract?

### Active mass-move

Users could exit their assets to the predicate, and if the predicate references another commitment contract the mass move succeed. This is the active mass-move. In this case, I assume the transfer of Plasma chain's rights in exchange paid.

Credits [iibbee__](https://twitter.com/iibbee__), @satellitex, @shogochiai for the idea of the transfer of Plasma chain.

### Passive mass-move

Can users complete mass move when the withholding happens at first Commitment contract? If users who didn't sign a new transaction just before withholding happens can exit to a new Deposit contract by limbo exit. But other users should exit with their last transaction. This is passive and democratic mass-move.


## What topic to research next

What happens if limbo-exit has priority to avoid `proveSourceDoubleSpend`?
Users can cancel previous transaction, and sign mass-move state even in withholding case.
This feature can be implemented in limbo-exit predicate standard layer.

http://spec.plasma.group/en/latest/src/02-contracts/limbo-exit-predicate.html
> Bob cannot guarantee until the exit period has passed that Alice will not sign a conflicting message and deprecate the exit. 

The thing not mentioned PG's document. If Alice signs a conflicting message, which message is high priority than others.
