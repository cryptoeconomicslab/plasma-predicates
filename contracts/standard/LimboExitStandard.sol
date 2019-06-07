pragma solidity >0.5.6;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/Math.sol";
import "../library/PlasmaModel.sol";

// This contract is following pigi spec
// https://docs.plasma.group/en/latest/
contract LimboExitStandard {

  struct LimboStatus {
    bytes32 targetId;
    bool wasReturned;
  }
  
  mapping (bytes32 => LimboStatus) public limboTargets;

  event LimboTargeted(
    PlasmaModel.Checkpoint limboExitSource,
    PlasmaModel.StateUpdate limboExitTarget
  );
  event limboExitReturned(
    PlasmaModel.Checkpoint limboExitSource
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
    PlasmaModel.StateObject memory _state
  ) public returns (bytes32) {
    return keccak256(abi.encode(_state));
  }

  function verifyTransaction(
    PlasmaModel.StateUpdate memory _preState,
    PlasmaModel.Transaction memory _transaction,
    PlasmaModel.Witness memory witness,
    PlasmaModel.StateUpdate memory _postState
  ) internal returns (bool) {
    return false;
  }

  function onTargetedForLimboExit(
    PlasmaModel.Checkpoint memory _sourceExit,
    PlasmaModel.StateUpdate memory _limboTarget
  ) public {

  }

  function targetLimboExit(
    PlasmaModel.Checkpoint memory _sourceExit,
    PlasmaModel.Transaction memory _transaction,
    PlasmaModel.Witness memory _witness,
    PlasmaModel.StateUpdate memory _limboTarget
  ) public {
    // check valid transaction or not
    require(verifyTransaction(_sourceExit.stateUpdate, _transaction, _witness, _limboTarget), "can't verify");
    // check subrange
    require(isSubRange(_limboTarget.start, _limboTarget.end, _sourceExit.start, _sourceExit.end), "isn't sub range");
    emit LimboTargeted(_sourceExit, _limboTarget);
    limboTargets[keccak256(abi.encode(_sourceExit))] = LimboStatus({
      targetId: keccak256(abi.encode(_limboTarget)),
      wasReturned: false
    });
  }

  function proveExitDeprecation(
    PlasmaModel.Checkpoint memory _deprecatedExit,
    PlasmaModel.Transaction memory _transaction,
    PlasmaModel.Witness memory _witness,
    PlasmaModel.StateUpdate memory _postState
  ) public {
    // check _deprecatedExit isn't limbo exit
    require(limboTargets[keccak256(abi.encode(_deprecatedExit))].targetId == 0, "");
    // check valid transaction or not
    require(verifyTransaction(_deprecatedExit.stateUpdate, _transaction, _witness, _postState), "can't verify");
    // check intersect or not
    require(intersect(_postState.start, _postState.end, _deprecatedExit.start, _deprecatedExit.end), "doesn't intersect");
    // call deprecateExit
    address plasmaContractAddress = _deprecatedExit.stateUpdate.plasmaContract;
    // call deprecateExit(_deprecatedExit)
  }

  function proveTargetDeprecation(
    PlasmaModel.Checkpoint memory _limboSource,
    PlasmaModel.StateUpdate memory _limboTarget,
    PlasmaModel.Transaction memory _transaction,
    PlasmaModel.Witness memory _witness,
    PlasmaModel.StateUpdate memory _postState
  ) public {
    bytes32 limboTargetId = keccak256(abi.encode(_limboTarget));
    require(limboTargets[keccak256(abi.encode(_limboSource))].targetId == limboTargetId, "_limboTarget should be limbo exit");
    require(verifyTransaction(_limboTarget, _transaction, _witness, _postState), "can't verify");
    address plasmaContractAddress = _limboSource.stateUpdate.plasmaContract;
    // call deprecateExit(_limboSource)

  }

  function proveSourceDoubleSpend(
    PlasmaModel.Checkpoint memory _limboSource,
    PlasmaModel.StateUpdate memory _limboTarget,
    PlasmaModel.Transaction memory _conflictingTransaction,
    PlasmaModel.Witness memory _conflictingWitness,
    PlasmaModel.StateUpdate memory _conflictingPostState
  ) public {
    bytes32 limboTargetId = keccak256(abi.encode(_limboTarget));
    require(limboTargets[keccak256(abi.encode(_limboSource))].targetId == limboTargetId, "_limboTarget should be limbo exit");
    require(verifyTransaction(_limboTarget, _conflictingTransaction, _conflictingWitness, _conflictingPostState), "can't verify");
    require(hashOfState(_limboTarget.stateObject) != hashOfState(_conflictingPostState.stateObject), "not conflicted state");
    // call deprecateExit(_limboTarget)
  }

  function canReturnLimboExit(
    PlasmaModel.Checkpoint memory _limboSource,
    PlasmaModel.StateUpdate memory _limboTarget,
    PlasmaModel.Witness memory _witness
  ) public returns (bool) {
    
  }

  function returnLimboExit(
    PlasmaModel.Checkpoint memory _limboSource,
    PlasmaModel.StateUpdate memory _limboTarget,
    PlasmaModel.Witness memory _witness
  ) public {
    require(canReturnLimboExit(_limboSource, _limboTarget, _witness), "can't return limbo exit");
    limboTargets[keccak256(abi.encode(_limboSource))].wasReturned = true;
  }

}
