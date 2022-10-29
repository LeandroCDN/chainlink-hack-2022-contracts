// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//for wrapped tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract SpotBot is AccessControl {
  struct userData{
    uint buyPrice;
    uint sellPrice;
    address admin;
  }

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  address stableCoin; // Need One Stable!
  address tradeableToken;
  AggregatorV3Interface dataFeed;
  userData data;


  constructor(
    address stableCoin_, 
    address tradeableToken_, 
    address dataFeed_,
    uint buyPrice_,
    uint sellPrice_,
    address ownerOfBot_
  ) {
    stableCoin = stableCoin_;
    tradeableToken = tradeableToken_;
    dataFeed = AggregatorV3Interface(dataFeed_);
    data = userData(buyPrice_, sellPrice_, ownerOfBot_);

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(ADMIN_ROLE, msg.sender);
  }

  //Public functions
  




  // PRIVATE FUNCTIONS
  function _getLatestPrice() internal view returns (int){
    (,int price,,,) = dataFeed.latestRoundData();
    return price;
  }

}