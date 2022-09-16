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
        uint256 amount = 1000000 ether;
        token = new Token("PONG", "PNG", amount);
        exchange = new Exchange(address(token));
    }

    function testAddLiquidity() public {
        token.approve(address(exchange), 10 ether);
        exchange.addLiquidity{value: 1 ether}(10 ether);
        assertEq(exchange.getReserve(), 10 ether);
        assertEq(address(exchange).balance, 1 ether);
    }

    function testGetEthAmount() public {
        token.approve(address(exchange), 2000 ether);
        exchange.addLiquidity{value: 1000 ether}(2000 ether);
        uint256 tokenSoldAmount = 2 ether;
        assertEq(exchange.getEthAmount(tokenSoldAmount), 999000999000999000);
        // increase more to see more price impact

        assertEq(exchange.getEthAmount(2 ether), 999000999000999000);
        assertEq(exchange.getEthAmount(100 ether), 47619047619047619047);
        assertEq(exchange.getEthAmount(2000 ether), 500000000000000000000);
    }

    function testGetTokenAmount() public {
        token.approve(address(exchange), 2000 ether);
        exchange.addLiquidity{value: 1000 ether}(2000 ether);
        uint256 ethSoldAmount = 1 ether;
        assertEq(exchange.getTokenAmount(ethSoldAmount), 1998001998001998001);
        assertEq(exchange.getTokenAmount(100 ether), 181818181818181818181);
        assertEq(exchange.getTokenAmount(1000 ether), 1000000000000000000000);
    }
}
