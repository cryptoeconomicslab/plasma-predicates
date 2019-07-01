pragma solidity >0.5.6;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/Math.sol";
import {DataTypes as types} from "../library/DataTypes.sol";

// This contract is following pigi spec
// https://docs.plasma.group/en/latest/
contract TransactionStandard {
  function intersect(uint256 start1, uint256 end1, uint256 start2, uint256 end2) private pure returns (bool) {
    uint256 max_start = Math.max(start1, start2);
    uint256 max_end = Math.min(end1, end2);
    return max_start < max_end;
  }

  function verifyTransaction(
    types.StateUpdate memory _preState,
    types.Transaction memory _transaction,
    types.Witness memory witness,
    types.StateUpdate memory _postState
  ) internal returns (bool) {
    return false;
  }

  function proveExitDeprecation(
    types.Checkpoint memory _deprecatedExit,
    types.Transaction memory _transaction,
    types.Witness memory _witness,
    types.StateUpdate memory _postState
  ) public {
    // check valid transaction or not
    require(verifyTransaction(_deprecatedExit.stateUpdate, _transaction, _witness, _postState), "can't verify");
    // check intersect or not
    require(intersect(_postState.range.start, _postState.range.end, _deprecatedExit.subrange.start, _deprecatedExit.subrange.end), "doesn't intersect");
    // call deprecateExit
    address plasmaContractAddress = _deprecatedExit.stateUpdate.depositAddress;
    // deprecateExit(_deprecatedExit)
  }
}
