//SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Interfaces/IMultiSigFactory.sol";

contract MultiSigWallet is ReentrancyGuard {
    address public owner;
    uint256 public orderCounter;
    uint256 public walletId;
    IMultiSigFactory multiSigFactory;

    struct Member {
        uint256 timeAdded;
        address walletAddress;
    }

    struct Order {
        uint256 creationTime;
        address tokenAddress;
        address toAddress;
        uint256 amount;
        uint256 numberOfAcceptance;
        uint256 numberOfRejections;
        uint256 minRequiredDecision;
        uint256 finalDecision;
    }

    uint256 public memberCount;
    mapping(address => Member) public addressToMember;
    mapping(address => bool) public isMember;
    mapping(address => uint256) public balanceOf;

    mapping(uint256 => Order) public orderIdToOrder;
    mapping(uint256 => mapping(address => uint256)) orderIdToAddressToDecision;

    constructor(
        address _owner,
        address _factoryAddress,
        uint256 _walletId
    ) {
        owner = _owner;
        multiSigFactory = IMultiSigFactory(_factoryAddress);
        walletId = _walletId;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner method");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only member method");
        _;
    }

    function addMember(address member) internal {
        require(!isMember[member], "Already a member");
        addressToMember[member] = Member(block.timestamp, member);
        isMember[member] = true;
        multiSigFactory.addMember(walletId, member);
        memberCount++;
    }

    function addMembers(address[] memory members) public onlyOwner {
        for (uint256 i; i < members.length; i++) addMember(members[i]);
    }

    function createOrder(
        address _tokenAddress,
        address _toAddress,
        uint256 _amount
    ) public onlyMember {
        orderIdToOrder[orderCounter] = Order({
            creationTime: block.timestamp,
            tokenAddress: _tokenAddress,
            toAddress: _toAddress,
            amount: _amount,
            numberOfAcceptance: 0,
            numberOfRejections: 0,
            minRequiredDecision: memberCount - memberCount / 2,
            finalDecision: 0
        });
        orderCounter++;
    }

    // 1 is for acceptance
    // 2 is for rejectance
    function makeDecision(uint256 orderId, uint256 decision)
        public
        nonReentrant
    {
        require((decision == 1) || (decision == 2), "Not a valid decision");
        Order storage o = orderIdToOrder[orderId];
        require(o.finalDecision != 0, "Already executed");
        require(
            addressToMember[msg.sender].timeAdded <= o.creationTime,
            "User wasn't a member at the time of ordering"
        );
        require(
            orderIdToAddressToDecision[orderId][msg.sender] == 0,
            "Already made a decision"
        );
        orderIdToAddressToDecision[orderId][msg.sender] = decision;
        if (decision == 1) o.numberOfAcceptance++;
        else o.numberOfRejections++;
        if (
            (o.numberOfAcceptance >= o.minRequiredDecision) ||
            (o.numberOfRejections >= o.minRequiredDecision)
        ) finalizeOrder(o);
    }

    function finalizeOrder(Order storage o) internal {
        if (o.numberOfAcceptance >= o.minRequiredDecision) {
            transfer(o.tokenAddress, o.toAddress, o.amount);
            o.finalDecision = 1;
        } else if (o.numberOfRejections >= o.minRequiredDecision)
            o.finalDecision = 2;
    }

    function transfer(
        address tokenAddress,
        address to,
        uint256 amount
    ) internal {
        require(IERC20(tokenAddress).transfer(to, amount), "Transfer failed");
    }
}
