pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "./library/DataTypes.sol";

/**
 * @title CommitmentChain
 * @notice This is mock commitment chain contract. Spec is http://spec.plasma.group/en/latest/src/02-contracts/commitment-contract.html
 */
contract CommitmentChain {
    // Event definitions
    event BlockSubmitted(
        bytes32 root
    );

    function verifyInclusion(types.StateUpdate memory _stateUpdate, bytes memory _inclusionProof) public returns (bool) {
        return true;
    }

    function submit(bytes32 _root) public {
        emit BlockSubmitted(_root);
    }

}
