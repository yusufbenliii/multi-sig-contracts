//SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Interfaces/IMultiSigFactory.sol";

contract MultiSigWallet is ReentrancyGuard {
    address public admin;
    uint256 public orderCounter;
    uint256 public walletId;
    string public description;
    IMultiSigFactory multiSigFactory;

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
    address[] public members;
    mapping(address => bool) public isMember;
    mapping(address => uint256) public timeAdded;
    mapping(uint256 => Order) public orderIdToOrder;
    mapping(uint256 => mapping(address => uint256)) orderIdToAddressToDecision;

    constructor(
        address _admin,
        address _factoryAddress,
        uint256 _walletId,
        string memory _description
    ) {
        admin = _admin;
        multiSigFactory = IMultiSigFactory(_factoryAddress);
        walletId = _walletId;
        description = _description;
        timeAdded[admin] = block.timestamp;
        isMember[admin] = true;
        members.push(admin);
        memberCount++;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only owner method");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only member method");
        _;
    }

    function balanceOf(address tokenAddress)
        public
        view
        returns (uint256 balance)
    {
        balance = IERC20(tokenAddress).balanceOf(address(this));
    }

    function addMember(address member) internal {
        require(!isMember[member], "Already a member");
        timeAdded[member] = block.timestamp;
        isMember[member] = true;
        members.push(member);
        multiSigFactory.addMember(walletId, member);
        memberCount++;
    }

    function addMembers(address[] memory newMembers) public onlyAdmin {
        uint256 l = newMembers.length;
        for (uint256 i; i < l; i++) addMember(newMembers[i]);
    }

    // set token address to address(0) to send ether
    function createOrder(
        address _tokenAddress,
        address _toAddress,
        uint256 _amount
    ) public onlyMember returns (uint256 orderId) {
        orderId = orderCounter;
        orderIdToOrder[orderId] = Order({
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
        require(orderId >= orderCounter, "No such order");
        require((decision == 1) || (decision == 2), "Not a valid decision");
        Order storage o = orderIdToOrder[orderId];
        require(o.finalDecision == 0, "Already executed");
        require(
            timeAdded[msg.sender] <= o.creationTime,
            "User wasn't a member at the time of ordering"
        );

        uint256 prevDecision = orderIdToAddressToDecision[orderId][msg.sender];
        if (prevDecision == 1) o.numberOfAcceptance--;
        else if (prevDecision == 2) o.numberOfRejections--;

        orderIdToAddressToDecision[orderId][msg.sender] = decision;
        if (decision == 1) o.numberOfAcceptance++;
        else o.numberOfRejections++;

        if (o.numberOfAcceptance == o.minRequiredDecision) closeOrder(o, 1);
        else if (o.numberOfRejections == o.minRequiredDecision)
            closeOrder(o, 2);
    }

    function closeOrder(Order storage o, uint256 decision) internal {
        if (decision == 1) transfer(o.tokenAddress, o.toAddress, o.amount);
        o.finalDecision = decision;
    }

    function transfer(
        address tokenAddress,
        address to,
        uint256 amount
    ) internal {
        if (tokenAddress == address(0)) payable(to).transfer(amount);
        else
            require(
                IERC20(tokenAddress).transfer(to, amount),
                "Transfer failed"
            );
    }

    receive() external payable {}
}
