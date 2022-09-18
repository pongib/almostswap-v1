// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";
import "./IFactory.sol";
import "./IExchange.sol";

error TestRevert();
error Exchange__NotAllowAddressZero();
error Exchange__InputOrOutputReserveBelowZero();
error Exchange__BelowZeroAmount(uint256 amount);
error Exchange__ExceedSlipageTolerance();
error Exchange__TransferETHFail();
error Exchange__InputTokenAsLiquidityToLow();
error Exchange__InputLPBelowZero();
error Exchange__ExchangeBoughtNotCreatedOrItSelf();

contract Exchange is ERC20 {
    address private s_tokenAddress;
    address private s_factoryAddress;

    // it have only one token because v1 allowed only eth <-> token
    constructor(address tokenAddress) ERC20("ALMOST V1 LP", "A-V1-LP") {
        if (tokenAddress == address(0)) {
            revert Exchange__NotAllowAddressZero();
        }

        s_tokenAddress = tokenAddress;
        s_factoryAddress = msg.sender;
    }

    function addLiquidity(uint256 amount) public payable returns (uint256) {
        if (getReserve() == 0) {
            IERC20 token = IERC20(s_tokenAddress);
            token.transferFrom(msg.sender, address(this), amount);

            // LP stuff
            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);
            return liquidity;
        } else {
            // we can control only token amount
            // so calculated porpotion from it.
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 tokenToReceive = (tokenReserve * msg.value) / ethReserve;
            if (tokenToReceive > amount) {
                revert Exchange__InputTokenAsLiquidityToLow();
            }
            // test foundry vm.expectRevert
            // require(tokenToReceive <= amount, "xxx");
            IERC20(s_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                tokenToReceive
            );

            uint256 liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
            return liquidity;
        }
    }

    function removeLiquidity(uint256 liquidityAmount)
        public
        returns (uint256, uint256)
    {
        if (liquidityAmount <= 0) {
            revert Exchange__InputLPBelowZero();
        }
        uint256 ethReserve = address(this).balance;
        uint256 returnEthAmount = (ethReserve * liquidityAmount) /
            totalSupply();
        uint256 tokenReserve = getReserve();
        // uint256 returnTokenAmount = (returnEthAmount * tokenReserve) /
        //     ethReserve;

        // use ratio as eth return
        uint256 returnTokenAmount = (tokenReserve * liquidityAmount) /
            totalSupply();
        _burn(msg.sender, liquidityAmount);
        (bool success, ) = address(msg.sender).call{value: returnEthAmount}("");
        if (!success) {
            revert Exchange__TransferETHFail();
        }
        IERC20(s_tokenAddress).transfer(msg.sender, returnTokenAmount);
        return (returnEthAmount, returnTokenAmount);
    }

    function ethToToken(uint256 minAmountToReceive, address recipient) private {
        uint256 ethSoldAmount = msg.value;
        uint256 tokenReserve = getReserve();
        uint256 tokenBoughtAmount = getAmount(
            ethSoldAmount,
            // when call this function it included msg.value to balance.
            address(this).balance - msg.value,
            tokenReserve
        );

        //protect user from frontrun manipulate price.
        if (minAmountToReceive > tokenBoughtAmount) {
            revert Exchange__ExceedSlipageTolerance();
        }
        IERC20(s_tokenAddress).transfer(recipient, tokenBoughtAmount);
    }

    function ethToTokenSwap(uint256 minAmountToReceive) external payable {
        ethToToken(minAmountToReceive, msg.sender);
    }

    function ethToTokenTransfer(uint256 minAmountToReceive, address recipient)
        external
        payable
    {
        ethToToken(minAmountToReceive, recipient);
    }

    function tokenToEthSwap(uint256 tokenSoldAmount, uint256 minAmountToReceive)
        external
        payable
    {
        uint256 tokenReserve = getReserve();
        uint256 ethBoughtAmount = getAmount(
            tokenSoldAmount,
            tokenReserve,
            address(this).balance
        );

        //protect user from frontrun manipulate price.
        if (minAmountToReceive > ethBoughtAmount) {
            revert Exchange__ExceedSlipageTolerance();
        }

        IERC20(s_tokenAddress).transferFrom(
            msg.sender,
            address(this),
            tokenSoldAmount
        );
        (bool success, ) = address(msg.sender).call{value: ethBoughtAmount}("");
        if (!success) {
            revert Exchange__TransferETHFail();
        }
    }

    function tokenToTokenSwap(
        uint256 tokenSoldAmount,
        uint256 minBoughtAmount,
        address tokenBoughtAddress
    ) public {
        address exchangeBoughtAddress = IFactory(s_factoryAddress).getExchange(
            tokenBoughtAddress
        );
        if (
            exchangeBoughtAddress == address(0) ||
            exchangeBoughtAddress != address(this)
        ) {
            revert Exchange__ExchangeBoughtNotCreatedOrItSelf();
        }

        uint256 tokenReserve = getReserve();
        uint256 ethBoughtAmount = getAmount(
            tokenSoldAmount,
            tokenReserve,
            address(this).balance
        );

        IERC20(s_tokenAddress).transferFrom(
            msg.sender,
            address(this),
            tokenSoldAmount
        );

        IExchange(exchangeBoughtAddress).ethToTokenTransfer{
            value: ethBoughtAmount
        }(minBoughtAmount, msg.sender);
    }

    function getReserve() public view returns (uint256) {
        return IERC20(s_tokenAddress).balanceOf(address(this));
    }

    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        if (inputReserve <= 0 || outputReserve <= 0) {
            revert Exchange__InputOrOutputReserveBelowZero();
        }

        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = outputReserve * inputAmountWithFee;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }

    function getEthAmount(uint256 tokenSoldAmount)
        public
        view
        returns (uint256)
    {
        if (tokenSoldAmount <= 0) {
            revert Exchange__BelowZeroAmount(tokenSoldAmount);
        }
        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = getReserve();
        return getAmount(tokenSoldAmount, tokenReserve, ethReserve);
    }

    function getTokenAmount(uint256 ethSoldAmount)
        public
        view
        returns (uint256)
    {
        if (ethSoldAmount <= 0) {
            revert Exchange__BelowZeroAmount(ethSoldAmount);
        }
        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = getReserve();
        return getAmount(ethSoldAmount, ethReserve, tokenReserve);
    }
}
