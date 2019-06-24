## Overview

This document proposes priority of limbo exit.

## What problem can be solved

We can avoid the last transaction is abused in withholding case. What happens if limbo-exit has priority to avoid `proveSourceDoubleSpend`? Users can cancel the previous transaction and can sign new state even in withholding case.

http://spec.plasma.group/en/latest/src/02-contracts/limbo-exit-predicate.html
> Bob cannot guarantee until the exit period has passed that Alice will not sign a conflicting message and deprecate the exit. 

The thing not mentioned PG's document. If Alice signs a conflicting message, which message is high priority than others.

In other words, Alice can do double-signing, so Bob should wait until the exit period.
If this double-signing is under an agreement between Alice and Bob, later signed message should prior than the earlier one.

## How does it work in detail

### Use priority field

* Alice should make a message to permit limbo-exit
* This message should include a priority field
* Thus Alice and Bob make correct limbo-exit under agreement


## What topic to research next

