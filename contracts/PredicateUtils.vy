# @dev from https://github.com/LayerXcom/plasma-mvp-vyper
@public
@constant
def ecrecover_sig(_txHash: bytes32, _sig: bytes[260], index: int128) -> address:
  if len(_sig) % 65 != 0:
    return ZERO_ADDRESS
  # ref. https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
  # The signature format is a compact form of:
  # {bytes32 r}{bytes32 s}{uint8 v}
  r: uint256 = extract32(_sig, 0 + 65 * index, type=uint256)
  s: uint256 = extract32(_sig, 32+ 65 * index, type=uint256)
  v: int128 = convert(slice(_sig, start=64 + 65 * index, len=1), int128)
  # Version of signature should be 27 or 28, but 0 and 1 are also possible versions.
  # geth uses [0, 1] and some clients have followed. This might change, see:
  # https://github.com/ethereum/go-ethereum/issues/2053
  if v < 27:
    v += 27
  if v in [27, 28]:
    return ecrecover(_txHash, convert(v, uint256), r, s)
  return ZERO_ADDRESS
