pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

/**
 * @title OwnershipPredicate
 */
contract OwnershipPredicate {

  struct StateObject {
    address predicateAddress;
    bytes data;
  }

  struct StateUpdate {
    StateObject stateObject;
    uint256 start;
    uint256 end;
    uint256 plasmaBlockNumber;
    address plasmaContract;
  }

  struct Transaction {
    address plasmaContract;
    uint256 start;
    uint256 end;
    bytes1 methodId;
    bytes parameters;
    bytes witness;
  }

  function executeStateTransition(
    StateUpdate memory _stateUpdate,
    Transaction memory _transaction
  ) public returns (StateUpdate memory) {
    StateObject memory nextStateObject = StateObject({
      predicateAddress: address(this),
      data: _transaction.parameters
    });
    StateUpdate memory nextStateUpdate = StateUpdate({
      stateObject: nextStateObject, 
      start: _stateUpdate.start,
      end: _stateUpdate.end,
      plasmaBlockNumber: _stateUpdate.plasmaBlockNumber,
      plasmaContract: _stateUpdate.plasmaContract
    });
    return nextStateUpdate;
  }

}
