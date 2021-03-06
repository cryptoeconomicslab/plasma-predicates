pragma solidity >0.5.6;
pragma experimental ABIEncoderV2;

import "./standard/LimboExitStandard.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

/**
 * @title MultisendsPredicate
 * @dev
 *     StateObject.data
 *       owner
 *     Transaction.parameters
 *       preStateObject, newStateObject, counterStateUpdateHash
 */
contract MultisendsPredicate is LimboExitStandard {

  mapping (bytes32 => bool) public counterStateUpdates;

  function bytesToAddress(bytes memory bys) private pure returns (address addr) {
    assembly {
      addr := mload(add(bys,20))
    }
  }
  
  function finalizeCounterExit(
    types.Checkpoint memory _exit
   ) public {
    types.StateUpdate memory stateUpdate = _exit.stateUpdate;
    counterStateUpdates[keccak256(abi.encode(stateUpdate))] = true;
    // call plasmaChain.finalizeExit()
  }

  function verifyTransaction(
    types.StateUpdate memory _preState,
    types.Transaction memory _transaction,
    types.Witness memory witness,
    types.StateUpdate memory _postState
  ) internal returns (bool) {
    (types.StateObject memory preStateObject, types.StateObject memory newStateObject, bytes32 counterStateUpdateHash) = abi.decode(_transaction.body, (types.StateObject, types.StateObject, bytes32));
    if (counterStateUpdates[counterStateUpdateHash]) {
      // call finalize Exit
      require(
        keccak256(abi.encode(_postState.stateObject)) == keccak256(abi.encode(newStateObject)),
        "invalid state object");
    } else {
      require(
        keccak256(abi.encode(_postState.stateObject)) == keccak256(abi.encode(preStateObject)),
        "invalid state object");
    }
    require(_postState.range.start == _transaction.range.start, "invalid start");
    require(_postState.range.end == _transaction.range.end, "invalid end");
    // require(_preState.plasmaBlockNumber <= originBlock, "pre state block number is too new");
    // require(_postState.plasmaBlockNumber <= maxBlock, "post state block number is too new");
    bytes32 txHash = keccak256(abi.encode(_transaction));
    address signer = ecverify(txHash, witness);
    // return abi.decode(_stateUpdate.stateObject.data, (address));
    // require(signer == abi.decode(_stateUpdate.stateObject.data, (address)));
    return true;
  }

  function canReturnLimboExit(
    types.Checkpoint memory _limboSource,
    types.StateUpdate memory _limboTarget,
    types.Witness memory _witness
  ) public returns (bool) {
    bytes32 limboTx = keccak256(abi.encodePacked(abi.encode(_limboSource), abi.encode(_limboTarget)));
    address signer = ecverify(limboTx, _witness);
    address owner = abi.decode(_limboTarget.stateObject.data, (address));
    // require(signer == owner, "require owner's permission");
  }

  function onFinalizeExit(
    address owner,
    address ERC20Contract,
    uint256 amount
  ) internal {
    ERC20(ERC20Contract).transfer(owner, amount);    
  }

  function finalizeExit(
    types.Checkpoint memory _exit
  ) public {
    types.StateUpdate memory stateUpdate = _exit.stateUpdate;
    address owner = abi.decode(stateUpdate.stateObject.data, (address));
    // How to get token address from range?
    address tokenAddress = address(0);
    onFinalizeExit(owner, tokenAddress, stateUpdate.range.end - stateUpdate.range.start);
  }

  function ecverify(
    bytes32 messageHash,
    types.Witness memory witness
  ) public returns (address) {
    bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    return ecrecover(prefixedHash, witness.v, witness.r, witness.s);
  }

}
