//SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./MultiSigWallet.sol";

contract MultiSigFactory {
    address public owner;
    uint256 public walletIdCounter;
    uint256 public price;

    constructor(uint256 _price) {
        owner = msg.sender;
        price = _price;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner method");
        _;
    }

    mapping(uint256 => address) public walletIdToWalletAddress;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256[]) public memberToWalletIds;

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function createWallet() public payable returns (uint256 walletId) {
        require(msg.value == price, "Insufficient payment amount");
        walletIdCounter++;
        MultiSigWallet newMultiSigWallet = new MultiSigWallet(
            msg.sender,
            address(this),
            walletIdCounter
        );
        walletIdToWalletAddress[walletIdCounter] = address(newMultiSigWallet);
        ownerOf[walletIdCounter] = msg.sender;
        walletId = walletIdCounter;
    }

    function addMember(uint256 walletId, address member) public {
        require(
            walletIdToWalletAddress[walletId] == msg.sender,
            "Only wallet method"
        );
        memberToWalletIds[member].push(walletId);
    }
}
