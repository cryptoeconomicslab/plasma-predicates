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

/**
 * @title DepositERC20
 * @notice This is the deposit contract for ERC20. Spec is http://spec.plasma.group/en/latest/src/02-contracts/deposit-contract.html
 */
contract DepositERC20 is DepositStandard {

    ERC20 public erc20;

    constructor(address _erc20, address _commitmentChain) DepositStandard(_commitmentChain) public {
        erc20 = ERC20(_erc20);
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

    function finalizeExit(
        types.Checkpoint memory _exit,
        uint256 depositedRangeId
    ) public {
        bytes32 checkpointId = getCheckpointId(_exit);
        // Check that we are authorized to finalize this exit
        require(_exit.stateUpdate.stateObject.predicateAddress == msg.sender, "Exit must be finalized by its predicate");
        require(checkpointFinalized(checkpointId), "Checkpoint must be finalized to finalize an exit");
        require(block.number > exitRedeemableAfter[checkpointId], "Exit must be redeemable after this block");
        require(isSubrange(_exit.subrange, depositedRanges[depositedRangeId]), "Exit must be of an deposited range (one that hasn't been exited)");
        // Remove the deposited range
        removeDepositedRange(_exit.subrange, depositedRangeId);
        // Delete the exit & checkpoint entries
        delete checkpoints[checkpointId];
        delete exitRedeemableAfter[checkpointId];
        // Transfer tokens to the deposit contract
        uint256 amount = _exit.subrange.end - _exit.subrange.start;
        erc20.transfer(_exit.stateUpdate.stateObject.predicateAddress, amount);
        // Emit an event recording the exit's finalization
        emit ExitFinalized(checkpointId);
    }

}
