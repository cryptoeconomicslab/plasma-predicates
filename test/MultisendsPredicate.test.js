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
const RLP = utils.RLP

contract('MultisendsPredicate', accounts => {
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
    this.multisendsPredicate = await MultisendsPredicate.new(
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
        accounts[0],
        accounts[1],
        constants.HashZero
      ])
      const canInitiateExit = await this.multisendsPredicate.can_initiate_exit(
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
