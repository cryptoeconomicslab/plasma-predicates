pragma solidity >0.5.6;
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
  }

  struct Witness {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  function bytesToAddress(bytes memory bys) private pure returns (address addr) {
    assembly {
      addr := mload(add(bys,20))
    }
  }

  function executeStateTransition(
    StateUpdate memory _stateUpdate,
    Transaction memory _transaction,
    Witness memory witness
  ) public returns (StateUpdate memory) {
    (StateObject memory newStateObject, uint64 originBlock, uint64 targetBlock) = abi.decode(_transaction.parameters, (StateObject, uint64, uint64));
    StateUpdate memory nextStateUpdate = StateUpdate({
      stateObject: newStateObject,
      start: _stateUpdate.start,
      end: _stateUpdate.end,
      plasmaBlockNumber: _stateUpdate.plasmaBlockNumber,
      plasmaContract: _stateUpdate.plasmaContract
    });
    assert(_stateUpdate.plasmaBlockNumber <= originBlock);
    // bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    // bytes32 txHash = keccak256(abi.encode(_transaction));
    // bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, txHash));
    // address signer = ecrecover(prefixedHash, witness.v, witness.r, witness.s);
    // assert(signer == bytesToAddress(_stateUpdate.stateObject.data));
    return nextStateUpdate;
  }

}
