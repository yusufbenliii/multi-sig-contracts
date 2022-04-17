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

    mapping(uint256 => address) internal walletIdToWalletAddress;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256[]) internal memberToWalletIds;
    mapping(address => bool) public isWallet;

    function getWalletAddresses_msgSender()
        public
        view
        returns (uint256[] memory, address[] memory)
    {
        return getWalletAddresses(msg.sender);
    }

    function getWalletAddresses(address member)
        internal
        view
        returns (uint256[] memory, address[] memory)
    {
        uint256[] memory walletIds = memberToWalletIds[member];
        uint256 l = walletIds.length;
        address[] memory addresses = new address[](l);
        for (uint256 i; i < l; i++) {
            addresses[i] = walletIdToWalletAddress[walletIds[i]];
        }
        return (walletIds, addresses);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function createWallet(string memory description)
        public
        payable
        returns (uint256 walletId, address newWalletAddress)
    {
        require(msg.value == price, "Insufficient payment amount");
        MultiSigWallet newMultiSigWallet = new MultiSigWallet(
            msg.sender,
            address(this),
            walletIdCounter,
            description
        );
        newWalletAddress = address(newMultiSigWallet);
        walletId = walletIdCounter;
        walletIdToWalletAddress[walletId] = newWalletAddress;
        isWallet[newWalletAddress] = true;
        ownerOf[walletId] = msg.sender;
        memberToWalletIds[msg.sender].push(walletId);
        walletIdCounter++;
    }

    function addMember(uint256 walletId, address member) public {
        require(
            walletIdToWalletAddress[walletId] == msg.sender,
            "Only wallet method"
        );
        memberToWalletIds[member].push(walletId);
    }
}
