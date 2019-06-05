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

  function verifyTransaction(
    StateUpdate memory _preState,
    Transaction memory _transaction,
    Witness memory witness,
    StateUpdate memory _postState
  ) public returns (bool) {
    (StateObject memory newStateObject, uint64 originBlock, uint64 maxBlock) = abi.decode(_transaction.parameters, (StateObject, uint64, uint64));
    require(keccak256(abi.encode(_postState.stateObject)) == keccak256(abi.encode(newStateObject)), "invalid state object");
    require(_postState.start == _transaction.start, "invalid start");
    require(_postState.end == _transaction.end, "invalid end");
    require(_preState.plasmaBlockNumber <= originBlock, "pre state block number is too new");
    require(_postState.plasmaBlockNumber <= maxBlock, "post state block number is too new");
    bytes32 txHash = keccak256(abi.encode(_transaction));
    address signer = ecverify(txHash, witness);
    // return abi.decode(_stateUpdate.stateObject.data, (address));
    //require(signer == abi.decode(_stateUpdate.stateObject.data, (address)));
    return true;
  }

  function ecverify(
    bytes32 messageHash,
    Witness memory witness
  ) public returns (address) {
    bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    return ecrecover(prefixedHash, witness.v, witness.r, witness.s);
  }

}
