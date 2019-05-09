const PredicateUtils = artifacts.require('PredicateUtils')
const OwnershipPredicate = artifacts.require('OwnershipPredicate')
const { constants, utils } = require('ethers')

contract('OwnershipPredicate', accounts => {
  beforeEach(async () => {
    this.predicateUtils = await PredicateUtils.new()
    this.ownershipPredicate = await OwnershipPredicate.new()
  })
})
