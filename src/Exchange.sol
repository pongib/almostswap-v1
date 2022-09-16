// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Exchange__NotAllowAddressZero();
error Exchange__InputOrOutputReserveBelowZero();
error Exchange__BelowZeroAmount(uint256 amount);

contract Exchange {
    address public s_tokenAddress;

    // it have only one token because v1 allowed only eth <-> token
    constructor(address tokenAddress) {
        if (tokenAddress == address(0)) {
            revert Exchange__NotAllowAddressZero();
        }

        s_tokenAddress = tokenAddress;
    }

    function addLiquidity(uint256 amount) public payable {
        IERC20 token = IERC20(s_tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);
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

        return (outputReserve * inputAmount) / (inputReserve + inputAmount);
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
