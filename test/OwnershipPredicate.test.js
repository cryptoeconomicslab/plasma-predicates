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

  /*
  describe('canStartExitGame', () => {
    it('succeed to canStartExitGame', async () => {
      const stateUpdate = RLP.encode([
        concat([numTo32bytes(0), numTo32bytes(10000)]),
        constants.AddressZero,
        accounts[0]
      ])
      const canInitiateExit = await this.ownershipPredicate.canStartExitGame(
        stateUpdate,
        justSign(Account1PrivKey, utils.keccak256(stateUpdate)),
        {
          from: accounts[0]
        }
      )
      assert.isTrue(canInitiateExit)
    })
  })
  */

  describe('proveExitDeprecation', () => {
    it('succeed to proveExitDeprecation', async () => {
      const stateObject = [
        this.ownershipPredicate.address,
        abi.encode(['address'], [accounts[0]])
      ]
      const stateUpdate = [stateObject, 0, 10000, 10, this.plasmaChain.address]
      const deprecatedExit = [stateUpdate, 0, 10000]
      const newStateObject = [
        this.ownershipPredicate.address,
        abi.encode(['address'], [accounts[1]])
      ]
      const newStateUpdate = [
        newStateObject,
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
      // newStateObject, originBlock, maxBlock
      const parameters = abi.encode(
        [
          {
            type: 'tuple',
            components: [{ type: 'address' }, { type: 'bytes' }]
          },
          'uint64',
          'uint64'
        ],
        [newStateObject, 10, 20]
      )
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
      const key = new utils.SigningKey(Account1PrivKey)
      const signature = key.signDigest(txHash)
      const witness = [signature.r, signature.s, signature.v]

      await this.ownershipPredicate.proveExitDeprecation(
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
