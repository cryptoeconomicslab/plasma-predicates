const CoverageSubprovider = require('contract-coverager')
const engine = CoverageSubprovider.injectInTruffle(artifacts, web3)
const PredicateUtils = artifacts.require('PredicateUtils')
const CommitmentChain = artifacts.require('CommitmentChain')
const PlasmaChain = artifacts.require('PlasmaChain')
const OwnershipPredicate = artifacts.require('OwnershipPredicate')
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
    this.predicateUtils = await PredicateUtils.new()
    this.commitmentChain = await CommitmentChain.new()
    this.plasmaChain = await PlasmaChain.new(this.commitmentChain.address)
    this.ownershipPredicate = await OwnershipPredicate.new(
      this.commitmentChain.address,
      this.plasmaChain.address,
      this.predicateUtils.address
    )
  })

  describe('can_initiate_exit', () => {
    it('succeed to can_initiate_exit', async () => {
      const stateUpdate = RLP.encode([
        constants.AddressZero,
        constants.Zero,
        utils.bigNumberify(0),
        utils.bigNumberify(10000),
        accounts[0]
      ])
      const canInitiateExit = await this.ownershipPredicate.can_initiate_exit(
        stateUpdate,
        justSign(Account1PrivKey, utils.keccak256(stateUpdate)),
        {
          from: accounts[0]
        }
      )
      assert.isTrue(canInitiateExit)
    })
  })
})
