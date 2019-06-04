const PredicateUtils = artifacts.require('PredicateUtils')
const StateUpdateEncoder = artifacts.require('StateUpdateEncoder')
const OwnershipPredicate = artifacts.require('OwnershipPredicate')
const CommitmentChain = artifacts.require('CommitmentChain')
const PlasmaChain = artifacts.require('PlasmaChain')

module.exports = function(deployer) {
  deployer
    .deploy(PredicateUtils)
    .then(() => deployer.deploy(StateUpdateEncoder))
    .then(() => deployer.deploy(CommitmentChain))
    .then(() => deployer.deploy(PlasmaChain, CommitmentChain.address))
    .then(() =>
      deployer.deploy(
        OwnershipPredicate,
        CommitmentChain.address,
        PlasmaChain.address,
        PredicateUtils.address,
        StateUpdateEncoder.address
      )
    )
}
