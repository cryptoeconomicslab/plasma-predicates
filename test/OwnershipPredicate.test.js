const PredicateUtils = artifacts.require('PredicateUtils')
const CommitmentChain = artifacts.require('CommitmentChain')
const PlasmaChain = artifacts.require('PlasmaChain')
const OwnershipPredicate = artifacts.require('OwnershipPredicate')
const { constants, utils } = require('ethers')

contract('OwnershipPredicate', accounts => {
  beforeEach(async () => {
    this.predicateUtils = await PredicateUtils.new()
    this.commitmentChain = await CommitmentChain.new()
    this.plasmaChain = await PlasmaChain.new(this.commitmentChain.address)
    this.ownershipPredicate = await OwnershipPredicate.new(
      this.commitmentChain.address,
      this.plasmaChain.address,
      this.predicateUtils.address
    )
  })
})
