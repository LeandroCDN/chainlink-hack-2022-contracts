// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// Registrar Address: 0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d //mumbai!
// Registry address: 0x02777053d6764996e594c3E88AF1D58D5363a2e6	 //mumbai!

import "@openzeppelin/contracts/access/AccessControl.sol";
import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol"; 
import "./interfaces/ISpotGrid.sol";

contract AutomateGrids is AccessControl {
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  address[] public listOfGrid;
  uint maxGridMange = 5;

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(ADMIN_ROLE, msg.sender);
  }

  function pushNewGrid(address spotBotGrid) public onlyRole(ADMIN_ROLE){
    require(listOfGrid.length <= maxGridMange, "Max of grids" );
    listOfGrid.push(spotBotGrid);
  }

  function checkUpkeep(bytes calldata)
    external 
    view 
    returns (bool upkeepNeeded, bytes memory performData)
    {
      uint[5] memory checkData; //0 nathing to do - 1 buy - 2sell
      for (uint i; i < listOfGrid.length; i++){
      ISpotGrid grid = ISpotGrid(listOfGrid[i]);
      bool buy = grid.canBuy();
      bool sell = grid.canBuy();
      if(buy){
        checkData[i] = 1;
        upkeepNeeded = true;
      }
      if(sell){
        checkData[i] = 2;
        upkeepNeeded = true;
      }
    }
    performData = abi.encode(checkData);
    return(upkeepNeeded,performData);
  }

  function performUpkeep(bytes calldata performData) public {
    uint[5] memory checkData = abi.decode(performData,( uint[5]));

    for (uint i; i < listOfGrid.length; i++){
      ISpotGrid grid = ISpotGrid(listOfGrid[i]);

      if(checkData[i] == 1){
        grid.buy();
      }
      
      if(checkData[i] == 2){
        grid.sell();
      }
    }
  }

} 