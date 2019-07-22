const StateUpdateEncoder = artifacts.require('StateUpdateEncoder')
const OwnershipPredicate = artifacts.require('OwnershipPredicate')
const CommitmentChain = artifacts.require('CommitmentChain')
const Deposit = artifacts.require('MockDeposit')

module.exports = function(deployer) {
  deployer
    .deploy(StateUpdateEncoder)
    .then(() => deployer.deploy(CommitmentChain))
    .then(() => deployer.deploy(Deposit, CommitmentChain.address))
    .then(() =>
      deployer.deploy(
        OwnershipPredicate,
        CommitmentChain.address,
        Deposit.address,
        StateUpdateEncoder.address
      )
    )
}
