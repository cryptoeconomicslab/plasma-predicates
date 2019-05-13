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
  state_update: bytes[256]
) -> (uint256, uint256, uint256):
  values = RLPList(state_update, [address, uint256, uint256, uint256])
  return (values[1], values[2], values[3])

@public
@constant
def decode_ownership_state(
  state_update: bytes[256]
) -> address:
  values = RLPList(state_update, [address, uint256, uint256, uint256, address])
  return values[4]

@public
@constant
def decode_deprecation_witness(
  deprecation_witness: bytes[600]
) -> (bytes[256], bytes[65], bytes[512]):
  values = RLPList(deprecation_witness, [bytes, bytes, bytes])
  next_state_update: bytes[256] = slice(values[0], start=0, len=256)
  signatures: bytes[65] = slice(values[1], start=0, len=65)
  inclusion_witness: bytes[512] = slice(values[2], start=0, len=512)
  return (next_state_update, signatures, inclusion_witness)

@public
@constant
def can_initiate_exit(
  state_update: bytes[256],
  initiation_witness: bytes[65]
) -> (bool):
  owner: address = self.decode_ownership_state(state_update)
  state_update_hash: bytes32 = sha3(state_update)
  initiator: address = PredicateUtils(self.predicate_utils).ecrecover_sig(state_update_hash, initiation_witness, 0)
  #assert initiator == owner
  return True

@public
@constant
def verify_deprecation(
  state_id: uint256,
  state_update: bytes[256],
  # next_state_update should be multiple state_updates
  # deprecation_witness will be RLP structure in production
  deprecation_witness: bytes[600]
) -> (bool):
  exit_segment: uint256
  block_number: uint256
  start: uint256
  end: uint256
  next_state_update: bytes[256]
  signatures: bytes[65]
  inclusion_witness: bytes[512]
  (next_state_update, signatures, inclusion_witness) = self.decode_deprecation_witness(deprecation_witness)
  transaction_hash: bytes32 = sha3(next_state_update)
  exit_owner: address = self.decode_ownership_state(state_update)
  (block_number, start, end) = self.decode_state_update(next_state_update)
  assert start <= state_id and state_id < end
  assert CommitmentContract(self.commitment_chain).verify_update(
    next_state_update,
    self.plasma_chain,
    inclusion_witness
  )
  assert PredicateUtils(self.predicate_utils).ecrecover_sig(transaction_hash, signatures, 0) == exit_owner
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

@public
@constant
def get_additional_lockup(
  state_update: bytes[256]
) -> uint256:
  return 0
