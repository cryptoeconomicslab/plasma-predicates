const { utils } = require('ethers')

function justSign(privKey, message) {
  const key = new utils.SigningKey(privKey)
  return utils.joinSignature(key.signDigest(message))
}

module.exports = {
  justSign
}
