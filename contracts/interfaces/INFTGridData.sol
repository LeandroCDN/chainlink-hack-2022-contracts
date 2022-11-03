// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";


interface INFTGridData {
    

  function safeMint(address to, string memory uri) external returns(uint);

    
}