const CoverageSubprovider = require('contract-coverager')
const engine = CoverageSubprovider.injectInTruffle(artifacts, web3)
const PredicateUtils = artifacts.require('PredicateUtils')
const StateUpdateEncoder = artifacts.require('StateUpdateEncoder')
const CommitmentChain = artifacts.require('CommitmentChain')
const Deposit = artifacts.require('Deposit')
const MultisendsPredicate = artifacts.require('MultisendsPredicate')
const { constants, utils } = require('ethers')
const { deployRLPdecoder } = require('./helpers/deployRLPdecoder')
const { justSign } = require('./helpers/sign')
const abi = new utils.AbiCoder()

contract('MultisendsPredicate', accounts => {
  const Account1PrivKey =
    '0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3'
  before(() => engine.start())
  after(() => engine.stop())
  const transactionAbiTypes = [
    'address',
    'bytes',
    { type: 'tuple', components: [{ type: 'uint256' }, { type: 'uint256' }] }
  ]
  const stateUpdateAbiTypes = [
    'tuple(tuple(address predicateAddress, bytes data) stateObject, tuple(uint64 start, uint64 end) range, uint64 plasmaBlockNumber, address depositAddress)'
  ]

  beforeEach(async () => {
    await deployRLPdecoder(accounts[0])
    this.commitmentChain = await CommitmentChain.new()
    this.plasmaChain = await Deposit.new(this.commitmentChain.address)
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
      const stateUpdate = [
        stateObject,
        [0, 10000],
        10,
        this.plasmaChain.address
      ]
      const newStateObject = getOwnerStateObject(
        this.multisendsPredicate.address,
        bob
      )
      const newStateUpdate = [
        newStateObject,
        [0, 10000],
        12,
        this.plasmaChain.address
      ]
      const counterStateObject = getOwnerStateObject(
        this.multisendsPredicate.address,
        bob
      )
      const counterStateUpdate = [
        counterStateObject,
        [1, 2],
        3,
        this.plasmaChain.address
      ]
      const counterHash = utils.keccak256(
        abi.encode(stateUpdateAbiTypes, [counterStateUpdate])
      )
      const parameters = getParameters(stateObject, newStateObject, counterHash)
      const transaction = [this.plasmaChain.address, parameters, [0, 10000]]

      const deprecatedExit = [stateUpdate, [0, 10000]]
      const counterExit = [counterStateUpdate, [10000, 20000]]
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
