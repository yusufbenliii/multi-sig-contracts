const MultiSigFactory = artifacts.require("MultiSigFactory");
const MultiSigWallet = artifacts.require("MultiSigWallet");
const MyToken = artifacts.require("MyToken");

module.exports = async function (deployer, network, accounts) {
  const admin = accounts[0];
  await deployer.deploy(MyToken, { from: admin });
  await MyToken.deployed();
  await deployer.deploy(MultiSigFactory, "1");
};
