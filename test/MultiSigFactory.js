// Artifacts
const MultiSigFactory = artifacts.require("MultiSigFactory");
const MultiSigWallet = artifacts.require("MultiSigWallet");
const MyToken = artifacts.require("MyToken");

// Imports
const { time } = require("@openzeppelin/test-helpers");
const { expect } = require("chai");

const chai = require("chai");
const ChaiTruffle = require("chai-truffle");
chai.use(ChaiTruffle);
const { BigNumber } = require("ethers");

function toBN(val) {
  return new web3.utils.BN(val);
}

contract("MultiSigFactory Test", async (accounts) => {
  let multiSigFactory;
  let multiSigWallet;
  let owner = accounts[0];
  before(async () => {
    multiSigFactory = await MultiSigFactory.deployed();
  });
  describe("MultiSigFactory", () => {
    it("check price of createing wallet", async () => {
      const price = await multiSigFactory.price.call();
      expect(price.toString()).to.be.eq("1", "wrong set price");
    });

    it("check set price onlyOwner", async () => {
      expect(multiSigFactory.setPrice(0, { from: accounts[1] })).to.evmRevert(
        "Only owner method",
        "set price modifier error"
      );
    });

    it("create wallet msg value requirement", async () => {
      expect(
        multiSigFactory.createWallet("First Multi-Sig Wallet", {
          from: owner,
          value: "2",
        })
      ).to.evmRevert("Insufficient payment amount", "msg value check error");
    });

    it("check WalletCreated event", async () => {
      expect(
        await multiSigFactory.createWallet("First Multi-Sig Wallet", {
          from: owner,
          value: 1,
        })
      ).to.emitEventWithArgs("WalletCreated", async (args) => {
        expect(args.creator).to.be.eq(owner, "wrong creator");
        expect(args.walletId.toString()).to.be.eq("0", "wrong wallet id");
        expect(args.newWalletAddress).not.to.be.eq(0x0, "0 wallet address");
        expect(args.newWalletAddress).not.to.be.eq("", "empty wallet address");
      });
    });

    it("check create wallet effects", async () => {
      const returnValue = await multiSigFactory.createWallet(
        "First Multi-Sig Wallet",
        {
          from: owner,
          value: 1,
        }
      );

      const creator = returnValue.logs[0].args.creator;
      const walletId = returnValue.logs[0].args.walletId.toString();
      expect(walletId).to.be.eq("1", "wrong wallet id");
      const newWalletAddress = returnValue.logs[0].args.newWalletAddress;

      expect(
        await multiSigFactory.walletIdToWalletAddress.call(walletId)
      ).to.be.eq(newWalletAddress, "walletIdToWalletAddress mapping error");

      expect(await multiSigFactory.ownerOf.call(walletId)).to.be.eq(
        creator,
        "ownerOf mapping error"
      );

      const walletId1 = await multiSigFactory.memberToWalletIds.call(
        creator,
        1
      );

      expect(walletId1.toString()).to.be.eq(
        "1",
        "memberToWalletIds mapping error"
      );

      expect(await multiSigFactory.isWallet.call(newWalletAddress)).to.be.eq(
        true,
        "isWallet mapping error"
      );

      expect(
        multiSigFactory.addMember(walletId1, accounts[1], { from: owner })
      ).to.evmRevert("Only wallet method", "addMember function error");

      multiSigWallet = await MultiSigWallet.at(newWalletAddress);
      expect(multiSigWallet.address).to.be.eq(
        newWalletAddress,
        "wallet addresses do not match"
      );
    });
  });
});
