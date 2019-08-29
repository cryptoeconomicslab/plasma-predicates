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

/**
 * @title DepositNFT
 * @notice This is the deposit contract for NFT. Spec is http://spec.plasma.group/en/latest/src/02-contracts/deposit-contract.html
 */
contract DepositNFT is DepositStandard {

    ERC721 public erc721;
    mapping (uint256 => uint256) public nftTokens;
    constructor(address _erc721, address _commitmentChain) DepositStandard(_commitmentChain) public {
        erc721 = ERC721(_erc721);
    }

    /**
     * @notice
     * @param _tokenId The ID of deposited ERC721 token
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
        // Range must have exactly 1 token
        require(_exit.subrange.end - _exit.subrange.start == 1, "range must be 1");
        // Remove the deposited range
        removeDepositedRange(_exit.subrange, depositedRangeId);
        // Delete the exit & checkpoint entries
        delete checkpoints[checkpointId];
        delete exitRedeemableAfter[checkpointId];
        // Transfer ERC721 token to the deposit contract
        erc721.approve(_exit.stateUpdate.stateObject.predicateAddress, nftTokens[_exit.subrange.start]);
        // Emit an event recording the exit's finalization
        emit ExitFinalized(checkpointId);
    }    

}
