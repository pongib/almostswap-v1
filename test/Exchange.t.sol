// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Exchange.sol";
import "../src/Token.sol";

import "../src/Factory.sol";

contract ExchangeTest is Test {
    Token public token;
    Exchange public exchange;
    Exchange public exchangeA;
    Exchange public exchangeB;
    Factory public factory;
    Token public tokenA;
    Token public tokenB;

    function setUp() public {
        uint256 amount = 1000000 ether;
        token = new Token("PONG", "PNG", amount);
        exchange = new Exchange(address(token));
        factory = new Factory();
        tokenA = new Token("TOKEN-A", "TKA", amount);
        tokenB = new Token("TOKEN-B", "TKB", amount);
        exchangeA = Exchange(factory.createExchange(address(tokenA)));
        exchangeB = Exchange(factory.createExchange(address(tokenB)));
    }

    // function testAddLiquidity() public {
    //     token.approve(address(exchange), 10 ether);
    //     exchange.addLiquidity{value: 1 ether}(10 ether);
    //     assertEq(exchange.getReserve(), 10 ether);
    //     assertEq(address(exchange).balance, 1 ether);
    // }

    function testGetEthAmount() public {
        token.approve(address(exchange), 2000 ether);
        exchange.addLiquidity{value: 1000 ether}(2000 ether);
        // increase more to see more price impact
        assertEq(exchange.getEthAmount(2 ether), 989020869339354039);
        assertEq(exchange.getEthAmount(100 ether), 47165316817532158170);
        assertEq(exchange.getEthAmount(2000 ether), 497487437185929648241);
    }

    function testGetTokenAmount() public {
        token.approve(address(exchange), 2000 ether);
        exchange.addLiquidity{value: 1000 ether}(2000 ether);
        assertEq(exchange.getTokenAmount(1 ether), 1978041738678708079);
        assertEq(exchange.getTokenAmount(100 ether), 180163785259326660600);
        assertEq(exchange.getTokenAmount(1000 ether), 994974874371859296482);
    }

    function testAddLiquidityInEmptyReseve() public {
        token.approve(address(exchange), 2000 ether);
        exchange.addLiquidity{value: 100 ether}(200 ether);
        assertEq(exchange.getReserve(), 200 ether);
        assertEq(address(exchange).balance, 100 ether);
    }

    function testMintLpTokenInEmptyReseve() public {
        token.approve(address(exchange), 2000 ether);
        exchange.addLiquidity{value: 100 ether}(200 ether);
        assertEq(exchange.balanceOf(address(this)), 100 ether);
        assertEq(exchange.totalSupply(), 100 ether);
    }

    function testMintZeroLpTokenInEmptyReseve() public {
        token.approve(address(exchange), 2000 ether);
        exchange.addLiquidity{value: 0 ether}(0 ether);
        assertEq(exchange.balanceOf(address(this)), 0 ether);
        assertEq(exchange.totalSupply(), 0 ether);
    }

    function testPreserveExchangeRateInExistReserve() public {
        token.approve(address(exchange), 2000 ether);
        exchange.addLiquidity{value: 100 ether}(200 ether);
        exchange.addLiquidity{value: 50 ether}(100 ether);
        assertEq(address(exchange).balance, 150 ether);
        assertEq(exchange.getReserve(), 300 ether);
    }

    function testMintLPTokenInExistReserve() public {
        token.approve(address(exchange), 2000 ether);
        exchange.addLiquidity{value: 100 ether}(200 ether);
        exchange.addLiquidity{value: 50 ether}(100 ether);
        assertEq(exchange.balanceOf(address(this)), 150 ether);
        assertEq(exchange.totalSupply(), 150 ether);
    }

    function testWhenNotEnoughTokenInExistReserve() public {
        token.approve(address(exchange), 2000 ether);
        exchange.addLiquidity{value: 100 ether}(200 ether);
        // vm.expectRevert(Exchange.Exchange__InputTokenAsLiquidityToLow.selector);
        console.logBytes4(
            bytes4(keccak256(bytes("Exchange__InputTokenAsLiquidityToLow()")))
        );
        vm.expectRevert(
            bytes4(keccak256(bytes("Exchange__InputTokenAsLiquidityToLow()")))
        );
        exchange.addLiquidity{value: 50 ether}(50 ether);
    }

    function testTokenToTokenSwap() public {}
}
