#
# Library
#
# OwnershipPredicate.vy
#   This is predicate sample for Plasma.
#

contract CommitmentContract():
  def verify_update(
    stateUpdate: bytes[256],
    subject: address,
    stateUpdateWitness: bytes[512]
  ) -> bool: constant

contract PredicateUtils():
  def ecrecover_sig(
    _txHash: bytes32,
    _sig: bytes[260],
    index: int128
  ) -> address: constant

contract ERC20:
  def transferFrom(_from: address, _to: address, _value: uint256) -> bool: modifying
  def transfer(_to: address, _value: uint256) -> bool: modifying

commitment_chain: public(address)
plasma_chain: public(address)
predicate_utils: public(address)

# @dev Constructor
@public
def __init__(
  _commitment_chain: address,
  _plasma_chain: address,
  _predicate_utils: address
):
  self.commitment_chain = _commitment_chain
  self.plasma_chain = _plasma_chain
  self.predicate_utils = _predicate_utils

@public
@constant
def decode_state_update(
  stateBytes: bytes[256]
) -> (uint256, uint256, uint256):
  # assert self == extract32(stateBytes, 0, type=address)
  return (
    extract32(stateBytes, 32*1, type=uint256),  # blkNum
    extract32(stateBytes, 32*2, type=uint256),   # start
    extract32(stateBytes, 32*3, type=uint256)   # end
  )

@public
@constant
def decode_ownership_state(
  stateBytes: bytes[256]
) -> (address):
  return (
    extract32(stateBytes, 32*4, type=address)   # owner
  )

@public
@constant
def can_initiate_exit(
  state_update: bytes[256],
  initiation_witness: bytes[512],
  exit_owner: address
) -> (bool):
  owner: address = self.decode_ownership_state(state_update)
  assert exit_owner == owner
  return True

@public
@constant
def verify_deprecation(
  state_id: uint256,
  state_update: bytes[256],
  # next_state_update should be multiple state_updates
  next_state_update: bytes[256],
  deprecation_witness: bytes[65],
  inclusion_witness: bytes[512]
) -> (bool):
  exit_segment: uint256
  block_number: uint256
  start: uint256
  end: uint256
  transaction_hash: bytes32 = sha3(next_state_update)
  exit_owner: address = self.decode_ownership_state(state_update)
  (block_number, start, end) = self.decode_state_update(next_state_update)
  assert start <= state_id and state_id < end
  assert CommitmentContract(self.commitment_chain).verify_update(
    next_state_update,
    self.plasma_chain,
    inclusion_witness
  )
  assert PredicateUtils(self.predicate_utils).ecrecover_sig(transaction_hash, deprecation_witness, 0) == exit_owner
  return True

@public
def finalize_exit(
  state_update: bytes[256]
):
  block_number: uint256
  start: uint256
  end: uint256
  exit_owner: address
  (block_number, start, end) = self.decode_state_update(state_update)
  exit_owner = self.decode_ownership_state(state_update)
  # TODO: get token_id
  send(exit_owner, as_wei_value(end - start, "gwei"))
