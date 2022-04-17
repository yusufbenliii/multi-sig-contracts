const MultiSigFactory = artifacts.require("MultiSigFactory");
const MultiSigWallet = artifacts.require("MultiSigWallet");
const MyToken = artifacts.require("MyToken");

module.exports = async function (deployer, network, accounts) {
  const admin = "0x034A97527CCc60dB3D786B9d724a64b0921FfCE5";
  await deployer.deploy(MyToken, { from: admin });
  let Token = await MyToken.deployed();
  await deployer.deploy(MultiSigFactory, "1");
  let MSF = await MultiSigFactory.deployed();
  let returnValues = await MSF.createWallet.sendTransaction(
    "First MultiSig Wallet",
    {
      from: admin,
      value: "1",
    }
  );

  let walletAddresses = await MSF.getWalletAddresses_msgSender({ from: admin });
  console.log(walletAddresses);
  let walletAddress = walletAddresses[1][0];
  console.log(walletAddress);
  await Token.transfer(walletAddress, "1000000000000000000000", {
    from: admin,
  });
  let MSW = await MultiSigWallet.at(walletAddress);
  await MSW.addMembers(["0x0792D268DD590B6d6dB00940E98fc7827deD8346"], {
    from: admin,
  });
};
