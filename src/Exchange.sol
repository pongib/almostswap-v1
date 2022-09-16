// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Exchange__NotAllowAddressZero();
error Exchange__InputOrOutputReserveBelowZero();
error Exchange__BelowZeroAmount(uint256 amount);
error Exchange__ExceedSlipageTolerance();
error Exchange__TransferETHFail();

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

    function ethToTokenSwap(uint256 minAmountToReceive) external payable {
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
        IERC20 token = IERC20(s_tokenAddress);
        token.transfer(msg.sender, tokenBoughtAmount);
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
        (bool success, ) = address(this).call{value: ethBoughtAmount}("");
        if (!success) {
            revert Exchange__TransferETHFail();
        }
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
