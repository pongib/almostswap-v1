// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Exchange__NotAllowAddressZero();

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
}
