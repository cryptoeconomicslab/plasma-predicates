/**
 * Original code is https://github.com/plasma-group/pigi/blob/master/packages/contracts/contracts/Deposit.sol
 * Created by Plasma Group https://github.com/plasma-group/pigi
 * Modified by Cryptoeconomics Lab on Jul 03 2019
 */
pragma solidity >0.5.6;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../library/DataTypes.sol";

// This contract is following pigi spec
// https://docs.plasma.group/en/latest/
contract DepositStandard {
    uint256 public totalDeposited;
    mapping (uint256 => types.Range) public depositedRanges;
    /* 
     * Helpers
     */ 
    function getCheckpointId(types.Checkpoint memory _checkpoint) internal pure returns (bytes32) {
        return keccak256(abi.encode(_checkpoint.stateUpdate, _checkpoint.subrange));
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

}
