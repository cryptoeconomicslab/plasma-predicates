pragma solidity >0.5.6;

library PlasmaModel {
  struct StateObject {
    address predicateAddress;
    bytes data;
  }

  struct StateUpdate {
    StateObject stateObject;
    uint256 start;
    uint256 end;
    uint256 plasmaBlockNumber;
    address plasmaContract;
  }

  struct Checkpoint {
    StateUpdate stateUpdate;
    uint256 start;
    uint256 end;
  }

  struct Transaction {
    address plasmaContract;
    uint256 start;
    uint256 end;
    bytes1 methodId;
    bytes parameters;
  }

  struct Witness {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

}