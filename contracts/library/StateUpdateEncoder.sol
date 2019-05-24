pragma solidity >=0.4.21 <0.6.0;

import "./RLPEncoder.sol";

contract StateUpdateEncoder {

  constructor() public {
  }

  function encode(bytes memory objectId, address predicate, bytes memory data)
    public
    pure
    returns (bytes memory)
  {
    bytes[] memory target = new bytes[](3);
    target[0] = RLPEncode.encodeBytes(objectId);
    target[1] = RLPEncode.encodeBytes(abi.encodePacked(predicate));
    target[2] = RLPEncode.encodeBytes(data);
    return RLPEncode.encodeList(target);
  }

}
