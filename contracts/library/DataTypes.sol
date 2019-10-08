/*
 * Original code is https://github.com/plasma-group/pigi/blob/master/packages/contracts/contracts/DataTypes.sol
 * From Plasma Group https://github.com/plasma-group/pigi
 */
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

/**
 * @title DataTypes
 * @notice TODO
 */
contract DataTypes {

    /*** Structs ***/
    struct Range {
        uint256 start;
        uint256 end;
    }

    struct StateObject {
        address predicateAddress;
        bytes data;
    }

    struct StateUpdate {
        StateObject stateObject;
        Range range;
        uint256 plasmaBlockNumber;
        address depositAddress;
    }

    struct Checkpoint {
        StateUpdate stateUpdate;
        Range subrange;
    }

    struct Transaction {
        address depositAddress;
        bytes body;
        Range range;
    }

    struct AssetTreeNode {
        bytes32 hashValue;
        uint256 start;
    }
    
    struct StateSubtreeNode {
        bytes32 hashValue;
        uint128 start;
    }

    struct Witness {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct BatchCheckpoint {
        bytes32 rangeAndBlockNumber;
        bytes32 hashOfStateObject;
    }    

}
