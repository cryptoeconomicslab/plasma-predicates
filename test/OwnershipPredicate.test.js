const CoverageSubprovider = require('contract-coverager')
const engine = CoverageSubprovider.injectInTruffle(artifacts, web3)
const PredicateUtils = artifacts.require('PredicateUtils')
const StateUpdateEncoder = artifacts.require('StateUpdateEncoder')
const CommitmentChain = artifacts.require('CommitmentChain')
const PlasmaChain = artifacts.require('PlasmaChain')
const OwnershipPredicate = artifacts.require('OwnershipPredicateVy')
const { constants, utils } = require('ethers')
const { deployRLPdecoder } = require('./helpers/deployRLPdecoder')
const { justSign } = require('./helpers/sign')
const RLP = utils.RLP

contract('OwnershipPredicate', accounts => {
  const Account1PrivKey =
    '0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3'
  before(() => engine.start())
  after(() => engine.stop())

  beforeEach(async () => {
    await deployRLPdecoder(accounts[0])
    this.stateUpdateEncoder = await StateUpdateEncoder.new()
    this.predicateUtils = await PredicateUtils.new()
    this.commitmentChain = await CommitmentChain.new()
    this.plasmaChain = await PlasmaChain.new(this.commitmentChain.address)
    this.ownershipPredicate = await OwnershipPredicate.new(
      this.commitmentChain.address,
      this.plasmaChain.address,
      this.predicateUtils.address,
      this.stateUpdateEncoder.address
    )
  })

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

  describe('executeStateTransition', () => {
    it('succeed to executeStateTransition', async () => {
      const stateUpdate = RLP.encode([
        concat([numTo32bytes(0), numTo32bytes(10000)]),
        this.ownershipPredicate.address,
        accounts[0]
      ])
      const newStateUpdate = RLP.encode([
        concat([numTo32bytes(0), numTo32bytes(10000)]),
        this.ownershipPredicate.address,
        accounts[1]
      ])
      const methodId = utils.keccak256(utils.toUtf8Bytes('send(address)'))
      const transaction = RLP.encode([
        concat([numTo32bytes(0), numTo32bytes(10000)]),
        methodId,
        accounts[1]
      ])
      const witness = justSign(Account1PrivKey, utils.keccak256(transaction))

      const newStateUpdateResult = await this.ownershipPredicate.executeStateTransition(
        stateUpdate,
        RLP.encode([transaction, witness]),
        {
          from: accounts[0]
        }
      )
      assert.equal(newStateUpdate, newStateUpdateResult)
    })
  })
})

function concat(arr) {
  return utils.hexlify(utils.concat(arr.map(h => utils.arrayify(h))))
}

function numTo32bytes(n) {
  return utils.hexZeroPad(utils.hexlify(utils.bigNumberify(n)), 32)
}
