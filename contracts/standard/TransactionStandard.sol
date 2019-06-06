pragma solidity >0.5.6;
pragma experimental ABIEncoderV2;


import "openzeppelin-solidity/contracts/math/Math.sol";
import "../library/PlasmaModel.sol";

contract TransactionStandard {
  function intersect(uint256 start1, uint256 end1, uint256 start2, uint256 end2) private pure returns (bool) {
    uint256 max_start = Math.max(start1, start2);
    uint256 max_end = Math.min(end1, end2);
    return max_start < max_end;
  }

  function verifyTransaction(
    PlasmaModel.StateUpdate memory _preState,
    PlasmaModel.Transaction memory _transaction,
    PlasmaModel.Witness memory witness,
    PlasmaModel.StateUpdate memory _postState
  ) internal returns (bool) {
    return false;
  }

  function proveExitDeprecation(
    PlasmaModel.Checkpoint memory _deprecatedExit,
    PlasmaModel.Transaction memory _transaction,
    PlasmaModel.Witness memory _witness,
    PlasmaModel.StateUpdate memory _postState
  ) public {
    // check valid transaction or not
    require(verifyTransaction(_deprecatedExit.stateUpdate, _transaction, _witness, _postState), "can't verify");
    // check intersect or not
    require(intersect(_postState.start, _postState.end, _deprecatedExit.start, _deprecatedExit.end), "doesn't intersect");
    // call deprecateExit
    address plasmaContractAddress = _deprecatedExit.stateUpdate.plasmaContract;
    // deprecateExit(_deprecatedExit)
  }
}
