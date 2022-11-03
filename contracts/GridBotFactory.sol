// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//for wrapped tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // to get price link
import "./SpotBot.sol";
import "./UpkeepIDRegisterFactory.sol";

import "./interfaces/INFTGridData.sol";


contract GridBotFactory is AccessControl {
  bytes32 public constant ADMIN = keccak256("ADMIN");
  uint public totalGrids;
  
  INFTGridData nftGrid;
  AggregatorV3Interface dataFeed;
  UpkeepIDRegisterFactory registerKeeps;
  IERC20 public currency;

  struct userData{
    address gridBotAddress;
    uint nftID;
    uint buyPrice_;
    uint sellPrice_;
  }

  address[] public listOfAllGrid;
  mapping(address => userData[]) public listOfGridsPerUser;

  constructor(address _NFTGridData) {
    nftGrid = INFTGridData(_NFTGridData);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(ADMIN, msg.sender);
  }

  function factoryNewGrid(
    string memory name,
    string memory uri_,
    address tradeableToken_,
    uint buyPrice_,
    uint sellPrice_,
    address owner_

  ) public payable {
    address newGrid = address(new SpotBot(
      address(currency),
      tradeableToken_,
      0x007A22900a3B98143368Bd5906f8E17e9867581b, // Datafeed btc/usd mumbai
      buyPrice_,
      sellPrice_,
      0,
      owner_,
      0xE592427A0AEce92De3Edee1F18E0157C05861564
    ));
    
     
    listOfAllGrid.push(newGrid);
    totalGrids++;
    registerKeeps.checkAndResolve( newGrid, name);
    uint id = nftGrid.safeMint(owner_,uri_);
    
    listOfGridsPerUser[owner_].push(userData(newGrid,id,buyPrice_,sellPrice_));
  }

  function getTotalNumberOfGrid(address _user)public view returns(uint){
    return listOfGridsPerUser[_user].length;
  }

}