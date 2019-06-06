pragma solidity >0.5.6;
pragma experimental ABIEncoderV2;

import "./library/PlasmaModel.sol";
import "./standard/TransactionStandard.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

/**
 * @title OwnershipPredicate
 */
contract OwnershipPredicate is TransactionStandard {

  function bytesToAddress(bytes memory bys) private pure returns (address addr) {
    assembly {
      addr := mload(add(bys,20))
    }
  }

  function verifyTransaction(
    PlasmaModel.StateUpdate memory _preState,
    PlasmaModel.Transaction memory _transaction,
    PlasmaModel.Witness memory witness,
    PlasmaModel.StateUpdate memory _postState
  ) internal returns (bool) {
    (PlasmaModel.StateObject memory newStateObject, uint64 originBlock, uint64 maxBlock) = abi.decode(_transaction.parameters, (PlasmaModel.StateObject, uint64, uint64));
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
  
  function onFinalizeExit(
    address owner,
    address ERC20Contract,
    uint256 amount
  ) internal {
    ERC20(ERC20Contract).transfer(owner, amount);    
  }

  function finalizeExit(
    PlasmaModel.Checkpoint memory _exit
  ) public {
    PlasmaModel.StateUpdate memory stateUpdate = _exit.stateUpdate;
    address owner = abi.decode(stateUpdate.stateObject.data, (address));
    // How to get token address from range?
    address tokenAddress = address(0);
    onFinalizeExit(owner, tokenAddress, stateUpdate.end - stateUpdate.start);
  }

  function ecverify(
    bytes32 messageHash,
    PlasmaModel.Witness memory witness
  ) public returns (address) {
    bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    return ecrecover(prefixedHash, witness.v, witness.r, witness.s);
  }

}
