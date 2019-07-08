pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../library/DataTypes.sol";
import "../standard/DepositStandard.sol";

/**
 * @title MockDeposit
 * @notice This is mock deposit contract. Spec is http://spec.plasma.group/en/latest/src/02-contracts/deposit-contract.html
 */
contract MockDeposit {

    // Event definitions
    event CheckpointFinalized(
        bytes32 checkpoint
    );

    event LogCheckpoint(
        types.Checkpoint checkpoint
    );

    CommitmentChain public commitmentChain;
    uint256 public totalDeposited;

    constructor(address _commitmentChain) public {
        commitmentChain = CommitmentChain(_commitmentChain);
    }

    /**
     * @notice
     * @param _amount TODO
     * @param _initialState  TODO
     */
    function deposit(uint256 _amount, types.StateObject memory _initialState) public {
        types.Range memory depositRange = types.Range({
            start: totalDeposited,
            end: totalDeposited + _amount
        });
        totalDeposited += _amount;
        types.StateUpdate memory stateUpdate = types.StateUpdate({
            range: depositRange,
            stateObject: _initialState,
            depositAddress: address(this),
            plasmaBlockNumber: 0
        });
        types.Checkpoint memory checkpoint = types.Checkpoint({
            stateUpdate: stateUpdate,
            subrange: depositRange
        });
        bytes32 checkpointId = getCheckpointId(checkpoint);
        emit CheckpointFinalized(checkpointId);
        emit LogCheckpoint(checkpoint);
    }

    /* 
     * Helpers
     */ 
    function getCheckpointId(types.Checkpoint memory _checkpoint) private pure returns (bytes32) {
        return keccak256(abi.encode(_checkpoint.stateUpdate, _checkpoint.subrange));
    }

}
