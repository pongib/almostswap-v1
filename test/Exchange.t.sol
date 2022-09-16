// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Exchange.sol";
import "../src/Token.sol";

contract ExchangeTest is Test {
    Token public token;
    Exchange public exchange;

    function setUp() public {
        uint256 amount = 100 ether;
        token = new Token("PONG", "PNG", amount);
        exchange = new Exchange(address(token));
    }

    function testAddLiquidity() public {
        token.approve(address(exchange), 10 ether);
        exchange.addLiquidity{value: 1 ether}(10 ether);
        assertEq(exchange.getReserve(), 10 ether);
        assertEq(address(exchange).balance, 1 ether);
    }
}
