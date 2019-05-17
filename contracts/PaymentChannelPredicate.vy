#
# Library
#
# PaymentChannel.vy
#   This is predicate sample for Plasma.
#
struct Channel:
  sender: address
  recipient: address
  total_coins: uint256
  channel_balance: uint256

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

channels: public(map(bytes32, Channel))
successful_openings: public(map(bytes32, bool))
opening_claims_in_progess: public(map(bytes32, uint256))

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
def decode_payment_channel_state(
  state_update: bytes[256]
) -> (address, address, bytes32, uint256):
  # predicate, block_number, start, end, sender, recipient, opening_updates_hash, channel_balance
  values = RLPList(state_update, [address, uint256, uint256, uint256, address, address, bytes32, uint256])
  return values[4], values[5], values[6], values[7]

@public
@constant
def decode_deprecation_witness(
  deprecation_witness: bytes[1024]
) -> (bytes[256], bytes[512], bytes[130]):
  # next_state_update, inclusion_witnesses, signature
  values = RLPList(deprecation_witness, [bytes, bytes, bytes])
  return (
    slice(values[0], start=0, len=256),
    slice(values[1], start=0, len=512),
    slice(values[2], start=0, len=130))

@public
@constant
def can_initiate_exit(
  state_update: bytes[256],
  initiation_witness: bytes[65]
) -> (bool):
  sender: address
  recipient: address
  opening_updates_hash: bytes32
  channel_balance: uint256
  (sender, recipient, opening_updates_hash, channel_balance) = self.decode_payment_channel_state(state_update)
  state_update_hash: bytes32 = sha3(state_update)
  initiator: address = PredicateUtils(self.predicate_utils).ecrecover_sig(state_update_hash, initiation_witness, 0)
  assert initiator == sender or initiator == recipient
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
  signature: bytes[130]
  (next_state_update, inclusion_witness, signature) = self.decode_deprecation_witness(deprecation_witness)
  next_state_update_hash: bytes32 = sha3(next_state_update)
  sender: address
  recipient: address
  opening_updates_hash: bytes32
  channel_balance: uint256
  (sender, recipient, opening_updates_hash, channel_balance) = self.decode_payment_channel_state(state_update)
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
  assert PredicateUtils(self.predicate_utils).ecrecover_sig(next_state_update_hash, signature, 0) == sender
  assert PredicateUtils(self.predicate_utils).ecrecover_sig(next_state_update_hash, signature, 1) == recipient
  return True

@public
def finalize_exit(
  state_update: bytes[256]
):
  block_number: uint256
  start: uint256
  end: uint256
  sender: address
  recipient: address
  opening_updates_hash: bytes32
  channel_balance: uint256
  (block_number, start, end) = self.decode_state_update(state_update)
  (sender, recipient, opening_updates_hash, channel_balance) = self.decode_payment_channel_state(state_update)
  state_update_hash: bytes32 = sha3(state_update_hash)
  self.channels[opening_updates_hash] = Channel({
    sender: sender,
    recipient: recipient,
    total_coins: end - start,
    channel_balance: channel_balance
  })

@public
@constant
def get_additional_lockup(
  state_update: bytes[256]
) -> uint256:
  return 0

@public
def dispute(
  state_update: bytes[256],
  signatures: bytes[130]
):
  sender: address
  recipient: address
  opening_updates_hash: bytes32
  channel_balance: uint256
  (sender, recipient, opening_updates_hash, channel_balance) = self.decode_payment_channel_state(state_update)
  state_update_hash: bytes32 = sha3(state_update)
  assert PredicateUtils(self.predicate_utils).ecrecover_sig(state_update_hash, signatures, 0) == sender
  assert PredicateUtils(self.predicate_utils).ecrecover_sig(state_update_hash, signatures, 1) == recipient
  self.channels[opening_updates_hash].channel_balance = channel_balance

@public
def finalize_channel(
  state_update: bytes[256],
):
  state_update_hash: bytes32 = sha3(state_update)
  channel: Channel = self.channels[state_update_hash]
  send(channel.recipient, as_wei_value(channel.channel_balance, "wei"))
  send(channel.sender, as_wei_value(channel.total_coins - channel.channel_balance, "wei"))
  clear(self.channels[state_update_hash])
