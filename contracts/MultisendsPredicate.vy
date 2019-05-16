#
# Library
#
# MultisendsPredicate.vy
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
# This map presents for changing ownership is succeeded or failed.
state_updates: public(map(bytes32, bool))

ZERO_HASH: constant(bytes32) = sha3(b'0')

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
  # predicate, block_number, start, end
  values = RLPList(state_update, [address, uint256, uint256, uint256])
  return (values[1], values[2], values[3])

# @dev returns previous_owner and owner address
@public
@constant
def decode_multisends_state(
  state_update: bytes[256]
) -> (address, address, bytes32):
  # predicate, block_number, start, end, previous_owner, owner, counter_part
  values = RLPList(state_update, [address, uint256, uint256, uint256, address, address, bytes32])
  return values[4], values[5], values[6]

@public
@constant
def decode_deprecation_witness(
  deprecation_witness: bytes[1024]
) -> (bytes[256], bytes[512], bytes[65], bytes[256], bytes[512]):
  # next_state_update, inclusion_witnesses, signature, counter_state_update, counter_inclusion_witness
  values = RLPList(deprecation_witness, [bytes, bytes, bytes, bytes, bytes])
  return (
    slice(values[0], start=0, len=256),
    slice(values[0], start=0, len=512),
    slice(values[2], start=0, len=65),
    slice(values[3], start=0, len=256),
    slice(values[0], start=0, len=512))

@public
@constant
def can_initiate_exit(
  state_update: bytes[256],
  initiation_witness: bytes[65]
) -> (bool):
  previous_owner: address
  owner: address
  counter_part: bytes32
  (previous_owner, owner, counter_part)= self.decode_multisends_state(state_update)
  state_update_hash: bytes32 = sha3(state_update)
  initiator: address = PredicateUtils(self.predicate_utils).ecrecover_sig(state_update_hash, initiation_witness, 0)
  assert initiator == owner or initiator == previous_owner
  return True

@public
@constant
def verify_deprecation(
  state_id: uint256,
  state_update: bytes[256],
  deprecation_witness: bytes[1024]
) -> (bool):
  next_state_update: bytes[256]
  inclusion_witness: bytes[512]
  signature: bytes[65]
  counter_state_update: bytes[256]
  counter_inclusion_witness: bytes[512]
  (next_state_update, inclusion_witness, signature, counter_state_update, counter_inclusion_witness) = self.decode_deprecation_witness(deprecation_witness)
  next_state_update_hash: bytes32 = sha3(next_state_update)
  previous_owner: address
  owner: address
  counter_part_hash: bytes32
  (previous_owner, owner, counter_part_hash)= self.decode_multisends_state(state_update)
  assert counter_part_hash == sha3(counter_state_update)
  assert CommitmentContract(self.commitment_chain).verify_update(
    next_state_update,
    self.plasma_chain,
    inclusion_witness
  )
  block_number: uint256
  start: uint256
  end: uint256
  (block_number, start, end) = self.decode_state_update(next_state_update)
  assert start <= state_id and state_id < end
  # Is counter_part included?
  assert CommitmentContract(self.commitment_chain).verify_update(
    counter_state_update,
    self.plasma_chain,
    counter_inclusion_witness
  )
  # inclusion or exclusion
  if counter_part_hash == ZERO_HASH: # exclusion
    assert PredicateUtils(self.predicate_utils).ecrecover_sig(next_state_update_hash, signature, 0) == previous_owner
  else:
    assert PredicateUtils(self.predicate_utils).ecrecover_sig(next_state_update_hash, signature, 0) == owner
  return True

@public
def finalize_exit(
  state_update: bytes[256]
):
  block_number: uint256
  start: uint256
  end: uint256
  previous_owner: address
  owner: address
  counter_part: bytes32
  (block_number, start, end) = self.decode_state_update(state_update)
  (previous_owner, owner, counter_part)= self.decode_multisends_state(state_update)
  state_update_hash: bytes32 = sha3(state_update_hash)
  # TODO: get token_id
  if self.state_updates[state_update_hash]:
    send(owner, as_wei_value(end - start, "gwei"))
  else:
    send(previous_owner, as_wei_value(end - start, "gwei"))

@public
@constant
def get_additional_lockup(
  state_update: bytes[256]
) -> uint256:
  return 0

@public
def show_counter_state(
  state_update: bytes[256],
  counter_state_update: bytes[256],
  inclusion_witness: bytes[512]
) -> (bool):
  previous_owner: address
  owner: address
  counter_part_hash: bytes32
  state_update_hash: bytes32 = sha3(state_update)
  (previous_owner, owner, counter_part_hash)= self.decode_multisends_state(state_update)
  assert counter_part_hash == sha3(counter_state_update)
  # Is counter_part included?
  assert CommitmentContract(self.commitment_chain).verify_update(
    counter_state_update,
    self.plasma_chain,
    inclusion_witness
  )
  # inclusion or exclusion
  if sha3(counter_state_update) == ZERO_HASH: # exclusion
    self.state_updates[state_update_hash] = False
  else:
    self.state_updates[state_update_hash] = True
  return True
