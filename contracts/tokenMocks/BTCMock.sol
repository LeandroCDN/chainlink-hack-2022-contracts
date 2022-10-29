// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDCMock is ERC20 {
    constructor() ERC20("USDC Mock", "USDC") {
        _mint(msg.sender, 19000000 * 10 ** decimals());
    }
}