const CoverageSubprovider = require('contract-coverager')
const engine = CoverageSubprovider.injectInTruffle(artifacts, web3)
const PredicateUtils = artifacts.require('PredicateUtils')
const StateUpdateEncoder = artifacts.require('StateUpdateEncoder')
const CommitmentChain = artifacts.require('CommitmentChain')
const PlasmaChain = artifacts.require('PlasmaChain')
const OwnershipPredicate = artifacts.require('OwnershipPredicate')
const { constants, utils } = require('ethers')
const { deployRLPdecoder } = require('./helpers/deployRLPdecoder')
const { justSign } = require('./helpers/sign')
const abi = new utils.AbiCoder()

contract('OwnershipPredicate', accounts => {
  const Account1PrivKey =
    '0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3'
  before(() => engine.start())
  after(() => engine.stop())
  const transactionAbiTypes = ['address', 'uint64', 'uint64', 'bytes1', 'bytes']
  const stateObjectAbiTypes = ['address', 'bytes']
  const stateUpdateAbiTypes = [
    { type: 'tuple', components: [{ type: 'address' }, { type: 'bytes' }] },
    'uint64',
    'uint64',
    'uint64',
    'address'
  ]
  const witnessAbiTypes = ['bytes32', 'bytes32', 'bytes1']

  beforeEach(async () => {
    await deployRLPdecoder(accounts[0])
    this.commitmentChain = await CommitmentChain.new()
    this.plasmaChain = await PlasmaChain.new(this.commitmentChain.address)
    this.ownershipPredicate = await OwnershipPredicate.new(
      this.commitmentChain.address,
      this.plasmaChain.address
    )
  })

  /// Alice transfer range to Bob
  const alice = accounts[0]
  const bob = accounts[1]

  function getOwnerStateUpdate(predicate, plasmaChain) {
    const stateObject = [predicate, abi.encode(['address'], [alice])]
    const stateUpdate = [stateObject, 0, 10000, 10, plasmaChain]
    return stateUpdate
  }

  function getParameters(nextStateObject) {
    // parameters include bobStateObject, originBlock and maxBlock
    return abi.encode(
      [
        {
          type: 'tuple',
          components: [{ type: 'address' }, { type: 'bytes' }]
        },
        'uint64',
        'uint64'
      ],
      [nextStateObject, 10, 20]
    )
  }

  function createWitness(txHash, privKey) {
    const key = new utils.SigningKey(privKey)
    const signature = key.signDigest(txHash)
    return [signature.r, signature.s, signature.v]
  }

  describe('proveExitDeprecation', () => {
    it('succeed to proveExitDeprecation', async () => {
      const stateUpdate = getOwnerStateUpdate(
        this.ownershipPredicate.address,
        this.plasmaChain.address
      )
      const bobStateObject = [
        this.ownershipPredicate.address,
        abi.encode(['address'], [bob])
      ]
      const bobStateUpdate = [
        bobStateObject,
        0,
        10000,
        10,
        this.plasmaChain.address
      ]
      const methodId = utils.hexDataSlice(
        utils.keccak256(utils.toUtf8Bytes('send(address)')),
        0,
        1
      )
      // parameters include bobStateObject, originBlock and maxBlock
      const parameters = getParameters(bobStateObject)
      const transaction = [
        this.plasmaChain.address,
        0,
        10000,
        methodId,
        parameters
      ]

      const deprecatedExit = [stateUpdate, 0, 10000]
      const txHash = utils.keccak256(
        abi.encode(transactionAbiTypes, transaction)
      )
      const witness = createWitness(txHash, Account1PrivKey)

      await this.ownershipPredicate.proveExitDeprecation(
        deprecatedExit,
        transaction,
        witness,
        bobStateUpdate,
        {
          from: accounts[0]
        }
      )
    })
  })

  describe('targetLimboExit', () => {
    it('succeed to targetLimboExit', async () => {
      const stateUpdate = getOwnerStateUpdate(
        this.ownershipPredicate.address,
        this.plasmaChain.address
      )
      const sourceExit = [stateUpdate, 0, 10000]
      const bobStateObject = [
        this.ownershipPredicate.address,
        abi.encode(['address'], [bob])
      ]
      const limboTarget = [
        bobStateObject,
        0,
        10000,
        10,
        this.plasmaChain.address
      ]
      const methodId = utils.hexDataSlice(
        utils.keccak256(utils.toUtf8Bytes('send(address)')),
        0,
        1
      )
      const parameters = getParameters(bobStateObject)
      const transaction = [
        this.plasmaChain.address,
        0,
        10000,
        methodId,
        parameters
      ]

      const txHash = utils.keccak256(
        abi.encode(transactionAbiTypes, transaction)
      )
      const witness = createWitness(txHash, Account1PrivKey)

      await this.ownershipPredicate.targetLimboExit(
        sourceExit,
        transaction,
        witness,
        limboTarget,
        {
          from: accounts[0]
        }
      )
    })
  })
})
