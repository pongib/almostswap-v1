// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Exchange.sol";

error Factory__InputZeroAddress();
error Factory__ExchangeAlreadyCreated(
    address tokenAddress,
    address exchangeAddress
);

contract Factory {
    mapping(address => address) private s_tokenToExchange;

    function createExchange(address tokenAddress) public returns (address) {
        if (tokenAddress == address(0)) {
            revert Factory__InputZeroAddress();
        }

        if (s_tokenToExchange[tokenAddress] != address(0)) {
            revert Factory__ExchangeAlreadyCreated(
                tokenAddress,
                s_tokenToExchange[tokenAddress]
            );
        }

        Exchange exchange = new Exchange(tokenAddress);
        s_tokenToExchange[tokenAddress] = address(exchange);
        return address(exchange);
    }

    function getExchange(address tokenAddress) public view returns (address) {
        return s_tokenToExchange[tokenAddress];
    }
}
