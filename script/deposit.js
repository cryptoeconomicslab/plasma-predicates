// deposit

const ethers = require('ethers');

const url = 'http://127.0.0.1:8545'
const privateKey = '0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3'

const httpProvider = new ethers.providers.JsonRpcProvider(url)
const wallet = new ethers.Wallet(privateKey, httpProvider)

const MockDepositAbi = [
  'function deposit(uint256, tuple(address, bytes))'
]

deposit().then(() => {
  console.log('deposited!!')
}).catch(e => {
  console.error(2, e)
})


async function deposit() {
  const predicate = '0xc4375b7de8af5a38a93548eb8453a498222c4ff2'
  const contract = new ethers.Contract('0x8f0483125FCb9aaAEFA9209D8E9d7b9C8B9Fb90F', MockDepositAbi, httpProvider)
  const rootChainContract = contract.connect(wallet)
  const result = await rootChainContract.deposit(
    100000,
    [predicate, '0x00']
  )
  console.log(result)
  result.wait()
  const receipt = await httpProvider.getTransactionReceipt(result.hash)
  console.log(receipt)
}