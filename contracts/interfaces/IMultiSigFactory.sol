//SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IMultiSigFactory {
    function addMember(uint256 walletId, address member) external;
}
