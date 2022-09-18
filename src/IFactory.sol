// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IFactory {
    function getExchange(address tokenAddress) external returns (address);
}
