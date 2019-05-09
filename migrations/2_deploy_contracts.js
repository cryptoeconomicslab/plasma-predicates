const PredicateUtils = artifacts.require('PredicateUtils')
const OwnershipPredicate = artifacts.require('OwnershipPredicate')

module.exports = function(deployer) {
  deployer
    .deploy(PredicateUtils)
    .then(() => deployer.deploy(OwnershipPredicate, PredicateUtils.address))
}
