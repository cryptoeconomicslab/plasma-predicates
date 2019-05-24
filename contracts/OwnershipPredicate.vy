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

contract StateUpdateEncoder():
  def encode(
    object_id: bytes[64],
    predicate: address,
    data: bytes[256]
  ) -> bytes[256]: constant

contract ERC20:
  def transferFrom(_from: address, _to: address, _value: uint256) -> bool: modifying
  def transfer(_to: address, _value: uint256) -> bool: modifying

commitment_chain: public(address)
plasma_chain: public(address)
predicate_utils: public(address)
encoder: public(address)

# @dev Constructor
@public
def __init__(
  _commitment_chain: address,
  _plasma_chain: address,
  _predicate_utils: address,
  _encoder: address
):
  self.commitment_chain = _commitment_chain
  self.plasma_chain = _plasma_chain
  self.predicate_utils = _predicate_utils
  self.encoder = _encoder

@public
@constant
def decode_state_update(
  state_update: bytes[256]
) -> (uint256, uint256):
  values = RLPList(state_update, [bytes, address])
  start: bytes[32] = slice(values[0], start=0, len=32)
  end: bytes[32] = slice(values[0], start=32, len=32)
  return (convert(start, uint256), convert(end, uint256))

@public
@constant
def decode_ownership_state(
  state_update: bytes[256]
) -> address:
  # The data of ownership predicate is address
  values = RLPList(state_update, [bytes, address, address])
  return values[2]

@public
@constant
def decode_transaction(
  signed_transaction: bytes[512]
) -> (bytes[64], bytes32, bytes[20], bytes32, bytes[65]):
  signed_transaction_values = RLPList(signed_transaction, [bytes, bytes])
  values = RLPList(signed_transaction_values[0], [bytes, bytes32, bytes])
  object_id: bytes[64] = slice(values[0], start=0, len=64)
  parameters: bytes[20] = slice(values[2], start=0, len=20)
  witness: bytes[65] = slice(signed_transaction_values[1], start=0, len=65)
  return (object_id, values[1], parameters, sha3(signed_transaction_values[0]), witness)

@public
@constant
def canStartExitGame(
  state_update: bytes[256],
  witness: bytes[65]
) -> (bool):
  owner: address = self.decode_ownership_state(state_update)
  state_update_hash: bytes32 = sha3(state_update)
  initiator: address = PredicateUtils(self.predicate_utils).ecrecover_sig(state_update_hash, witness, 0)
  # We have to check signature by owner in ownership predicate
  return True

@public
@constant
def executeStateTransition(
  state_update: bytes[256],
  transaction: bytes[512]
) -> (bytes[256]):
  exit_segment: uint256
  start: uint256
  end: uint256
  object_id: bytes[64]
  _method_id: bytes32
  parameters: bytes[20]
  transaction_hash: bytes32
  witness: bytes[65]
  (object_id, _method_id, parameters, transaction_hash, witness) = self.decode_transaction(transaction)
  exit_owner: address = self.decode_ownership_state(state_update)
  # check _method_id
  assert PredicateUtils(self.predicate_utils).ecrecover_sig(transaction_hash, witness, 0) == exit_owner
  return StateUpdateEncoder(self.encoder).encode(object_id, self, parameters)

@public
def onExitGameFinalized(
  state_update: bytes[256]
):
  start: uint256
  end: uint256
  exit_owner: address
  (start, end) = self.decode_state_update(state_update)
  exit_owner = self.decode_ownership_state(state_update)
  # TODO: get token_id
  send(exit_owner, as_wei_value(end - start, "gwei"))

@public
@constant
def getAdditionalExitPeriod(
  state_update: bytes[256]
) -> uint256:
  return 0
