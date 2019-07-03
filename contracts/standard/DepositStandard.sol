/**
 * Original code is https://github.com/plasma-group/pigi/blob/master/packages/contracts/contracts/Deposit.sol
 * Created by Plasma Group https://github.com/plasma-group/pigi/blob/master/LICENSE.txt
 * Modified by Cryptoeconomics Lab on Jul 03 2019
 */
pragma solidity >0.5.6;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/Math.sol";
import {DataTypes as types} from "../library/DataTypes.sol";
import "../CommitmentChain.sol";

// This contract is following pigi spec
// https://docs.plasma.group/en/latest/
contract DepositStandard {
    /*
     * Structs
     */
    struct CheckpointStatus {
        uint256 challengeableUntil;
        uint256 outstandingChallenges;
    }

    struct Challenge {
        types.Checkpoint challengedCheckpoint;
        types.Checkpoint challengingCheckpoint;
    }

    // Events
    event CheckpointStarted(
        types.Checkpoint checkpoint,
        uint256 challengeableUntil
    );

    event CheckpointFinalized(
        bytes32 checkpoint
    );

    event LogCheckpoint(
        types.Checkpoint checkpoint
    );

    event ExitStarted(
        bytes32 exit,
        uint256 redeemableAfter
    );

    event ExitFinalized(
        bytes32 exit
    );

    uint256 public totalDeposited;
    mapping (uint256 => types.Range) public depositedRanges;
    mapping (bytes32 => CheckpointStatus) public checkpoints;
    mapping (bytes32 => uint256) public exitRedeemableAfter;
    mapping (bytes32 => bool) public challenges;
    mapping (bytes32 => bool) public challengeInclusions;
    /*
     * Public Constants
     */
    CommitmentChain public commitmentChain;
    uint256 public constant CHALLENGE_PERIOD = 10;
    uint256 public constant EXIT_PERIOD = 20;

    constructor(address _commitmentChain) public {
        commitmentChain = CommitmentChain(_commitmentChain);
    }

    /**
     * Original code is https://github.com/plasma-group/pigi/blob/3fa77c71c0a198a8e410b75740e1a0406f9b723a/packages/contracts/contracts/Deposit.sol#L110.
     */
    function extendDepositedRanges(uint256 _amount) public {
        uint256 oldStart = depositedRanges[totalDeposited].start;
        uint256 oldEnd = depositedRanges[totalDeposited].end;
        // Set the newStart for the last range
        uint256 newStart;
        if (oldStart == 0 && oldEnd == 0) {
            // Case 1: We are creating a new range (this is the case when the rightmost range has been removed)
            newStart = totalDeposited;
        } else {
            // Case 2: We are extending the old range (deleting the old range and making a new one with the total length)
            delete depositedRanges[oldEnd];
            newStart = oldStart;
        }
        // Set the newEnd to the totalDeposited plus how much was deposited
        uint256 newEnd = totalDeposited + _amount;
        // Finally create and store the range!
        depositedRanges[newEnd] = types.Range(newStart, newEnd);
        // Increment total deposited now that we've extended our depositedRanges
        totalDeposited += _amount;
    }

    /**
     * @dev Precondition: range is subrange of depositedRanges[depositedRangeId]
     */
    function removeDepositedRange(types.Range memory range, uint256 depositedRangeId) public {
        types.Range memory encompasingRange = depositedRanges[depositedRangeId];

        // Split the LEFT side

        // check if we we have a new deposited region to the left
        if (range.start != encompasingRange.start) {
            // new deposited range from the unexited old start until the newly exited start
            types.Range memory leftSplitRange = types.Range(encompasingRange.start, range.start);
            // Store the new deposited range
            depositedRanges[leftSplitRange.end] = leftSplitRange;
        }

        // Split the RIGHT side (there 3 possible splits)

        // 1) ##### -> $$$## -- check if we have leftovers to the right which are deposited
        if (range.end != encompasingRange.end) {
            // new deposited range from the newly exited end until the old unexited end
            types.Range memory rightSplitRange = types.Range(range.end, encompasingRange.end);
            // Store the new deposited range
            depositedRanges[rightSplitRange.end] = rightSplitRange;
            // We're done!
            return;
        }
        // 3) ##### -> $$$$$ -- without right-side leftovers & not the rightmost deposit, we can simply delete the value
        delete depositedRanges[encompasingRange.end];
    }
    
    function calculateMerkleRoot(
        types.Checkpoint[] memory _checkpoints
    ) public returns (bytes32) {
        return keccak256(abi.encode(0));
    }

    function calculateMerkleRootWithProof(
        types.Checkpoint memory _checkpoint,
        bytes memory _checkpointInclusionProof
    ) public returns (bytes32) {
        return keccak256(abi.encode(0));
    }

    function calculateNewMerkleRoot(
        bytes memory _checkpointInclusionProof
    ) public returns (bytes32) {
        return keccak256(abi.encode(0));
    }

    /**
     * Batch checkpoints
     */
    function startCheckpoints(
        types.Checkpoint[] memory _checkpoints
    ) public {
        bytes32 checkpointRoot = calculateMerkleRoot(_checkpoints);
        require(!checkpointExists(checkpointRoot), "Checkpoint must not already exist");
        checkpoints[checkpointRoot] = CheckpointStatus(block.number + CHALLENGE_PERIOD, 0);
    }

    function challengeInclusion(
        types.Checkpoint memory _checkpoint,
        bytes memory _checkpointInclusionProof
    ) public {
        bytes32 checkpointId = getCheckpointId(_checkpoint);
        bytes32 checkpointRoot = calculateMerkleRootWithProof(_checkpoint, _checkpointInclusionProof);
        require(checkpointExists(checkpointRoot), "Checkpoint must exist");
        challengeInclusions[checkpointId] = true;
        checkpoints[checkpointRoot].outstandingChallenges += 1;
    }

    function respondChallengeInclusion(
        types.Checkpoint memory _checkpoint,
        bytes memory _inclusionProof,
        bytes memory _checkpointInclusionProof,
        uint256 _depositedRangeId
    ) public {
        bytes32 checkpointId = getCheckpointId(_checkpoint);
        bytes32 checkpointRoot = calculateMerkleRootWithProof(_checkpoint, _checkpointInclusionProof);
        require(challengeInclusions[checkpointId], "challenge must exist");
        require(commitmentChain.verifyInclusion(_checkpoint.stateUpdate, _inclusionProof), "Checkpoint must be included");
        require(isSubrange(_checkpoint.subrange, _checkpoint.stateUpdate.range), "Checkpoint must be on a subrange of the StateUpdate");
        require(isSubrange(_checkpoint.subrange, depositedRanges[_depositedRangeId]), "Checkpoint subrange must be on a depositedRange");
        checkpoints[checkpointRoot].outstandingChallenges -= 1;
    }

    function startCheckpoint(
        types.Checkpoint memory _checkpoint,
        bytes memory _inclusionProof,
        uint256 _depositedRangeId
    ) public {
        bytes32 checkpointId = getCheckpointId(_checkpoint);
        require(commitmentChain.verifyInclusion(_checkpoint.stateUpdate, _inclusionProof), "Checkpoint must be included");
        require(isSubrange(_checkpoint.subrange, _checkpoint.stateUpdate.range), "Checkpoint must be on a subrange of the StateUpdate");
        require(isSubrange(_checkpoint.subrange, depositedRanges[_depositedRangeId]), "Checkpoint subrange must be on a depositedRange");
        require(!checkpointExists(checkpointId), "Checkpoint must not already exist");
        // Create a new checkpoint
        checkpoints[checkpointId] = CheckpointStatus(block.number + CHALLENGE_PERIOD, 0);
        emit CheckpointStarted(_checkpoint, checkpoints[checkpointId].challengeableUntil);
    }

    function startExit(
        types.Checkpoint memory _checkpoint,
        bytes memory _checkpointInclusionProof
    ) public {
        bytes32 checkpointId = calculateMerkleRootWithProof(_checkpoint, _checkpointInclusionProof);
        // Verify this exit may be started
        require(checkpointExists(checkpointId), "Checkpoint must exist in order to begin exit");
        require(exitRedeemableAfter[checkpointId] == 0, "There must not exist an exit on this checkpoint already");
        require(_checkpoint.stateUpdate.stateObject.predicateAddress == msg.sender, "Exit must be started by its predicate");
        exitRedeemableAfter[checkpointId] = block.number + EXIT_PERIOD;
        emit ExitStarted(checkpointId, exitRedeemableAfter[checkpointId]);
    }

    function deprecateExit(
        types.Checkpoint memory _exit,
        bytes memory _checkpointInclusionProof
    ) public {
        bytes32 checkpointId = calculateMerkleRootWithProof(_exit, _checkpointInclusionProof);
        require(_exit.stateUpdate.stateObject.predicateAddress == msg.sender, "Exit must be deprecated by its predicate");
        bytes32 newCheckpointId = calculateNewMerkleRoot(_checkpointInclusionProof);
        checkpoints[newCheckpointId] = checkpoints[checkpointId];
        exitRedeemableAfter[newCheckpointId] = exitRedeemableAfter[checkpointId];
        delete exitRedeemableAfter[checkpointId];
    }

    function deleteOutdatedExit(
        types.Checkpoint memory _exit,
        types.Checkpoint memory _newerCheckpoint
    ) public {
        bytes32 outdatedExitId = getCheckpointId(_exit);
        bytes32 newerCheckpointId = getCheckpointId(_newerCheckpoint);
        require(intersects(_exit.subrange, _newerCheckpoint.subrange), "Exit and newer checkpoint must overlap");
        require(_exit.stateUpdate.plasmaBlockNumber < _newerCheckpoint.stateUpdate.plasmaBlockNumber, "Exit must be before a checkpoint");
        require(checkpointFinalized(newerCheckpointId), "Newer checkpoint must be finalized to delete an earlier exit");
        delete exitRedeemableAfter[outdatedExitId];
    }

    function challengeCheckpoint(
        Challenge memory _challenge,
        bytes memory _checkpointInclusionProof
    ) public {
        bytes32 challengedCheckpointId = calculateMerkleRootWithProof(_challenge.challengedCheckpoint, _checkpointInclusionProof);
        bytes32 challengingCheckpointId = getCheckpointId(_challenge.challengingCheckpoint);
        bytes32 challengeId = getChallengeId(_challenge);
        // Verify that the challenge may be added
        require(exitExists(challengingCheckpointId), "Challenging exit must exist");
        require(checkpointExists(challengedCheckpointId), "Challenged checkpoint must exist");
        require(intersects(_challenge.challengedCheckpoint.subrange, _challenge.challengingCheckpoint.subrange), "Challenge ranges must intersect");
        require(_challenge.challengingCheckpoint.stateUpdate.plasmaBlockNumber < _challenge.challengedCheckpoint.stateUpdate.plasmaBlockNumber, "Challenging cp after challenged cp");
        require(!challenges[challengeId], "Challenge must not already exist");
        require(checkpoints[challengedCheckpointId].challengeableUntil > block.number, "Checkpoint must still be challengable");
        // Add the challenge
        checkpoints[challengedCheckpointId].outstandingChallenges += 1;
        challenges[challengeId] = true;
    }

    function removeChallenge(Challenge memory _challenge) public {
        bytes32 challengedCheckpointId = getCheckpointId(_challenge.challengedCheckpoint);
        bytes32 challengingCheckpointId = getCheckpointId(_challenge.challengingCheckpoint);
        bytes32 challengeId = getChallengeId(_challenge);
        // Verify that the challenge may be added
        require(challenges[challengeId], "Challenge must exist");
        require(!exitExists(challengingCheckpointId), "Challenging exit must no longer exist");
        // Remove the challenge
        challenges[challengeId] = false;
        checkpoints[challengedCheckpointId].outstandingChallenges -= 1;
    }

    /* 
     * Helpers
     */ 
    function getCheckpointId(types.Checkpoint memory _checkpoint) internal pure returns (bytes32) {
        return keccak256(abi.encode(_checkpoint.stateUpdate, _checkpoint.subrange));
    }

    function getChallengeId(Challenge memory _challenge) private pure returns (bytes32) {
        return keccak256(abi.encode(_challenge));
    }

    function getLatestPlasmaBlockNumber() private returns (uint256) {
        return 0;
    }

    function isSubrange(types.Range memory _subRange, types.Range memory _surroundingRange) public pure returns (bool) {
        return _subRange.start >= _surroundingRange.start && _subRange.end <= _surroundingRange.end;
    }

    function intersects(types.Range memory _range1, types.Range memory _range2) public pure returns (bool) {
        return Math.max(_range1.start, _range2.start) < Math.min(_range1.end, _range2.end);
    }

    function checkpointExists(bytes32 checkpointId) public view returns (bool) {
        return checkpoints[checkpointId].challengeableUntil != 0 || checkpoints[checkpointId].outstandingChallenges != 0;
    }

    function checkpointFinalized(bytes32 checkpointId) public view returns (bool) {
        // To be considered finalized, a checkpoint:
        // - MUST have no outstanding challenges
        // - MUST no longer be challengable
        return checkpoints[checkpointId].outstandingChallenges == 0
                && checkpoints[checkpointId].challengeableUntil < block.number;
    }

    function exitExists(bytes32 checkpointId) public view returns (bool) {
        return exitRedeemableAfter[checkpointId] != 0;
    }

}
