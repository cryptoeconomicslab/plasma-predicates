const CoverageSubprovider = require('contract-coverager')
const engine = CoverageSubprovider.injectInTruffle(artifacts, web3)
const PredicateUtils = artifacts.require('PredicateUtils')
const StateUpdateEncoder = artifacts.require('StateUpdateEncoder')
const CommitmentChain = artifacts.require('CommitmentChain')
const PlasmaChain = artifacts.require('PlasmaChain')
const MultisendsPredicate = artifacts.require('MultisendsPredicate')
const { constants, utils } = require('ethers')
const { deployRLPdecoder } = require('./helpers/deployRLPdecoder')
const { justSign } = require('./helpers/sign')
const abi = new utils.AbiCoder()

/*
0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000027100000000000000000000000000000000000000000000000000000000000004e20000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000f204a4ef082f5c04bb89f7d5e6568b796096735a00000000000000000000000075c35c980c0d37ef46df04d31a140b65503c0eed00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000020000000000000000000000000f17f52151ebef6c7334fad080c5704d77216b732
0x00000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000027100000000000000000000000000000000000000000000000000000000000004e20000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000f204a4ef082f5c04bb89f7d5e6568b796096735a00000000000000000000000075c35c980c0d37ef46df04d31a140b65503c0eed00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000020000000000000000000000000f17f52151ebef6c7334fad080c5704d77216b732
*/

contract('MultisendsPredicate', accounts => {
  const Account1PrivKey =
    '0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3'
  before(() => engine.start())
  after(() => engine.stop())
  const transactionAbiTypes = ['address', 'uint64', 'uint64', 'bytes1', 'bytes']
  const stateObjectAbiTypes = ['address', 'bytes']
  const stateUpdateAbiTypes = [
    'tuple(tuple(address predicateAddress, bytes data) stateObject, uint64 start, uint64 end, uint64 plasmaBlockNumber, address plasmaContract)'
  ]
  const witnessAbiTypes = ['bytes32', 'bytes32', 'bytes1']

  beforeEach(async () => {
    await deployRLPdecoder(accounts[0])
    this.commitmentChain = await CommitmentChain.new()
    this.plasmaChain = await PlasmaChain.new(this.commitmentChain.address)
    this.multisendsPredicate = await MultisendsPredicate.new(
      this.commitmentChain.address,
      this.plasmaChain.address
    )
  })

  /// Alice transfer range to Bob
  const alice = accounts[0]
  const bob = accounts[1]

  function getOwnerStateObject(predicate, owner) {
    return [predicate, abi.encode(['address'], [owner])]
  }

  function getOwnerStateUpdate(predicate, plasmaChain) {
    const stateObject = getOwnerStateObject(predicate, alice)
    const stateUpdate = [stateObject, 0, 10000, 10, plasmaChain]
    return stateUpdate
  }

  function getParameters(preStateObject, newStateObject, counterHash) {
    // parameters include preStateObject, newStateObject and hash of counter StateUpdate
    return abi.encode(
      [
        {
          type: 'tuple',
          components: [{ type: 'address' }, { type: 'bytes' }]
        },
        {
          type: 'tuple',
          components: [{ type: 'address' }, { type: 'bytes' }]
        },
        'bytes32'
      ],
      [preStateObject, newStateObject, counterHash]
    )
  }

  function createWitness(txHash, privKey) {
    const key = new utils.SigningKey(privKey)
    const signature = key.signDigest(txHash)
    return [signature.r, signature.s, signature.v]
  }

  describe('proveExitDeprecation', () => {
    it('succeed to proveExitDeprecation', async () => {
      const stateObject = getOwnerStateObject(
        this.multisendsPredicate.address,
        alice
      )
      const stateUpdate = [stateObject, 0, 10000, 10, this.plasmaChain.address]
      const newStateObject = getOwnerStateObject(
        this.multisendsPredicate.address,
        bob
      )
      const newStateUpdate = [
        newStateObject,
        0,
        10000,
        12,
        this.plasmaChain.address
      ]
      const counterStateObject = getOwnerStateObject(
        this.multisendsPredicate.address,
        bob
      )
      const counterStateUpdate = [
        counterStateObject,
        1,
        2,
        3,
        this.plasmaChain.address
      ]
      const methodId = utils.hexDataSlice(
        utils.keccak256(utils.toUtf8Bytes('send(address)')),
        0,
        1
      )
      const counterHash = utils.keccak256(
        abi.encode(stateUpdateAbiTypes, [counterStateUpdate])
      )
      const parameters = getParameters(stateObject, newStateObject, counterHash)
      const transaction = [
        this.plasmaChain.address,
        0,
        10000,
        methodId,
        parameters
      ]

      const deprecatedExit = [stateUpdate, 0, 10000]
      const counterExit = [counterStateUpdate, 10000, 20000]
      const txHash = utils.keccak256(
        abi.encode(transactionAbiTypes, transaction)
      )
      const witness = createWitness(txHash, Account1PrivKey)

      await this.multisendsPredicate.finalizeCounterExit(counterExit)
      await this.multisendsPredicate.proveExitDeprecation(
        deprecatedExit,
        transaction,
        witness,
        newStateUpdate,
        {
          from: accounts[0]
        }
      )
    })
  })
})
