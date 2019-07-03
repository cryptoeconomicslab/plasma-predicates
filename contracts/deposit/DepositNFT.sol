/**
 * Original code is https://github.com/plasma-group/pigi/blob/master/packages/contracts/contracts/Deposit.sol
 * Created by Plasma Group https://github.com/plasma-group/pigi
 * Modified by Cryptoeconomics Lab on Jul 03 2019
 */
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import {DataTypes as types} from "../library/DataTypes.sol";
import "../standard/DepositStandard.sol";
import "../CommitmentChain.sol";

/**
 * @title DepositNFT
 * @notice This is mock deposit contract. Spec is http://spec.plasma.group/en/latest/src/02-contracts/deposit-contract.html
 */
contract DepositNFT is DepositStandard {

    // Event definitions
    event CheckpointFinalized(
        bytes32 checkpoint
    );

    event LogCheckpoint(
        types.Checkpoint checkpoint
    );

    ERC721 public erc721;
    CommitmentChain public commitmentChain;
    mapping (uint256 => uint256) public nftTokens;
    constructor(address _erc721, address _commitmentChain) public {
        erc721 = ERC721(_erc721);
        commitmentChain = CommitmentChain(_commitmentChain);
    }

    /**
     * @notice
     * @param _tokenId TODO
     * @param _initialState  TODO
     */
    function deposit(uint256 _tokenId, types.StateObject memory _initialState) public {
        // Transfer a erc721 token from sender to deposit contract
        erc721.transferFrom(msg.sender, address(this), _tokenId);
        // Put to mapping between totalDeposited and tokenId
        nftTokens[totalDeposited] = _tokenId;
        types.Range memory depositRange = types.Range({
            start: totalDeposited,
            end: totalDeposited + 1
        });
        totalDeposited += 1;
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
        extendDepositedRanges(1);
        bytes32 checkpointId = getCheckpointId(checkpoint);
        emit CheckpointFinalized(checkpointId);
        emit LogCheckpoint(checkpoint);
    }

}
