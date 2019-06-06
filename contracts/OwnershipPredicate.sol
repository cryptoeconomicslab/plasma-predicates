pragma solidity >0.5.6;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/Math.sol";

/**
 * @title OwnershipPredicate
 */
contract OwnershipPredicate {
  using Math for uint256;

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

  struct Checkpoint {
    StateUpdate stateUpdate;
    uint256 start;
    uint256 end;
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

  function intersect(uint256 start1, uint256 end1, uint256 start2, uint256 end2) private pure returns (bool) {
    uint256 max_start = Math.max(start1, start2);
    uint256 max_end = Math.min(end1, end2);
    return max_start < max_end;
  }

  function bytesToAddress(bytes memory bys) private pure returns (address addr) {
    assembly {
      addr := mload(add(bys,20))
    }
  }

  function proveExitDeprecation(
    Checkpoint memory _deprecatedExit,
    Transaction memory _transaction,
    Witness memory _witness,
    StateUpdate memory _postState
  ) public {
    // check valid transaction or not
    require(verifyTransaction(_deprecatedExit.stateUpdate, _transaction, _witness, _postState), "can't verify");
    // check intersect or not
    require(intersect(_postState.start, _postState.end, _deprecatedExit.start, _deprecatedExit.end), "doesn't intersect");
    // call deprecateExit
    address plasmaContractAddress = _deprecatedExit.stateUpdate.plasmaContract;
    // deprecateExit(_deprecatedExit)
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
