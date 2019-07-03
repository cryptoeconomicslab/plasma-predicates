/**
 * Original code is https://github.com/plasma-group/pigi/blob/master/packages/contracts/contracts/Deposit.sol
 * Created by Plasma Group https://github.com/plasma-group/pigi
 * Modified by Cryptoeconomics Lab on Jul 03 2019
 */
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import {DataTypes as types} from "../library/DataTypes.sol";
import "../standard/DepositStandard.sol";
import "../CommitmentChain.sol";

/**
 * @title DepositERC20
 * @notice This is mock deposit contract. Spec is http://spec.plasma.group/en/latest/src/02-contracts/deposit-contract.html
 */
contract DepositERC20 is DepositStandard {

    // Event definitions
    event CheckpointFinalized(
        bytes32 checkpoint
    );

    event LogCheckpoint(
        types.Checkpoint checkpoint
    );

    ERC20 public erc20;
    CommitmentChain public commitmentChain;

    constructor(address _erc20, address _commitmentChain) public {
        erc20 = ERC20(_erc20);
        commitmentChain = CommitmentChain(_commitmentChain);
    }

    /**
     * @notice
     * @param _amount TODO
     * @param _initialState  TODO
     */
    function deposit(uint256 _amount, types.StateObject memory _initialState) public {
        // Transfer erc20 tokens from sender to deposit contract
        erc20.transferFrom(msg.sender, address(this), _amount);
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
        extendDepositedRanges(_amount);
        bytes32 checkpointId = getCheckpointId(checkpoint);
        emit CheckpointFinalized(checkpointId);
        emit LogCheckpoint(checkpoint);
    }

}
