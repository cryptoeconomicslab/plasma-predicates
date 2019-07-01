pragma solidity >0.5.6;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../library/DataTypes.sol";
import "openzeppelin-solidity/contracts/math/Math.sol";

// This contract is following pigi spec
// https://docs.plasma.group/en/latest/
contract LimboExitStandard {

  struct LimboStatus {
    bytes32 targetId;
    bool wasReturned;
  }
  
  mapping (bytes32 => LimboStatus) public limboTargets;

  event LimboTargeted(
    types.Checkpoint limboExitSource,
    types.StateUpdate limboExitTarget
  );
  event limboExitReturned(
    types.Checkpoint limboExitSource
  );

  function intersect(uint256 start1, uint256 end1, uint256 start2, uint256 end2) private pure returns (bool) {
    uint256 max_start = Math.max(start1, start2);
    uint256 max_end = Math.min(end1, end2);
    return max_start < max_end;
  }

  function isSubRange(uint256 start1, uint256 end1, uint256 start2, uint256 end2) private pure returns (bool) {
    return start2 <= start1 && end1 <= end2;
  }

  function hashOfState(
    types.StateObject memory _state
  ) public returns (bytes32) {
    return keccak256(abi.encode(_state));
  }

  function verifyTransaction(
    types.StateUpdate memory _preState,
    types.Transaction memory _transaction,
    types.Witness memory witness,
    types.StateUpdate memory _postState
  ) internal returns (bool) {
    revert("not inplemented");
    return false;
  }

  function onTargetedForLimboExit(
    types.Checkpoint memory _sourceExit,
    types.StateUpdate memory _limboTarget
  ) public {

  }

  function targetLimboExit(
    types.Checkpoint memory _sourceExit,
    types.Transaction memory _transaction,
    types.Witness memory _witness,
    types.StateUpdate memory _limboTarget
  ) public {
    // check valid transaction or not
    require(verifyTransaction(_sourceExit.stateUpdate, _transaction, _witness, _limboTarget), "can't verify");
    // check subrange
    require(isSubRange(_limboTarget.range.start, _limboTarget.range.end, _sourceExit.subrange.start, _sourceExit.subrange.end), "isn't sub range");
    emit LimboTargeted(_sourceExit, _limboTarget);
    limboTargets[keccak256(abi.encode(_sourceExit))] = LimboStatus({
      targetId: keccak256(abi.encode(_limboTarget)),
      wasReturned: false
    });
  }

  function proveExitDeprecation(
    types.Checkpoint memory _deprecatedExit,
    types.Transaction memory _transaction,
    types.Witness memory _witness,
    types.StateUpdate memory _postState
  ) public {
    // check _deprecatedExit isn't limbo exit
    require(limboTargets[keccak256(abi.encode(_deprecatedExit))].targetId == 0, "");
    // check valid transaction or not
    require(verifyTransaction(_deprecatedExit.stateUpdate, _transaction, _witness, _postState), "can't verify");
    // check intersect or not
    require(intersect(_postState.range.start, _postState.range.end, _deprecatedExit.subrange.start, _deprecatedExit.subrange.end), "doesn't intersect");
    // call deprecateExit
    address plasmaContractAddress = _deprecatedExit.stateUpdate.depositAddress;
    // call deprecateExit(_deprecatedExit)
  }

  function proveTargetDeprecation(
    types.Checkpoint memory _limboSource,
    types.StateUpdate memory _limboTarget,
    types.Transaction memory _transaction,
    types.Witness memory _witness,
    types.StateUpdate memory _postState
  ) public {
    bytes32 limboTargetId = keccak256(abi.encode(_limboTarget));
    require(limboTargets[keccak256(abi.encode(_limboSource))].targetId == limboTargetId, "_limboTarget should be limbo exit");
    require(verifyTransaction(_limboTarget, _transaction, _witness, _postState), "can't verify");
    address plasmaContractAddress = _limboSource.stateUpdate.depositAddress;
    // call deprecateExit(_limboSource)

  }

  function proveSourceDoubleSpend(
    types.Checkpoint memory _limboSource,
    types.StateUpdate memory _limboTarget,
    types.Transaction memory _conflictingTransaction,
    types.Witness memory _conflictingWitness,
    types.StateUpdate memory _conflictingPostState
  ) public {
    bytes32 limboTargetId = keccak256(abi.encode(_limboTarget));
    require(limboTargets[keccak256(abi.encode(_limboSource))].targetId == limboTargetId, "_limboTarget should be limbo exit");
    require(verifyTransaction(_limboTarget, _conflictingTransaction, _conflictingWitness, _conflictingPostState), "can't verify");
    require(hashOfState(_limboTarget.stateObject) != hashOfState(_conflictingPostState.stateObject), "not conflicted state");
    // call deprecateExit(_limboTarget)
    limboTargets[keccak256(abi.encode(_limboSource))].targetId = 0;
  }

  function canReturnLimboExit(
    types.Checkpoint memory _limboSource,
    types.StateUpdate memory _limboTarget,
    types.Witness memory _witness
  ) public returns (bool) {
    
  }

  function returnLimboExit(
    types.Checkpoint memory _limboSource,
    types.StateUpdate memory _limboTarget,
    types.Witness memory _witness
  ) public {
    require(canReturnLimboExit(_limboSource, _limboTarget, _witness), "can't return limbo exit");
    limboTargets[keccak256(abi.encode(_limboSource))].wasReturned = true;
  }

}
