// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//for wrapped tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./utils/Swap.sol";

/*
*  Dev @LeanLabiano (youtube chanel ;)
*  First objetive: 
    ALL IN automte trading bot.
*  Two points : BuyPoint (uses all usdc in this contract) and SellPoint(uses all asset in this contract)
*/

contract SpotBot is AccessControl, Swap {

  struct userData{
    uint buyPrice; //In 8 decimals! For chainlink datafeed
    uint sellPrice; //In 8 decimals!
    uint initialAmount;
    address admin;
  }
  bool paused;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  IERC20 stableCoin; // Need One Stable!
  IERC20 tradeableToken;
  AggregatorV3Interface dataFeed;
  userData data;

  //swap router 0xE592427A0AEce92De3Edee1F18E0157C05861564
  constructor(
    address stableCoin_, 
    address tradeableToken_, 
    address dataFeed_,
    uint buyPrice_,
    uint sellPrice_,
    uint initialAmount_,
    address ownerOfBot_,
    address _swapRouter
  ) Swap(_swapRouter){
    stableCoin = IERC20(stableCoin_);
    tradeableToken = IERC20(tradeableToken_);
    dataFeed = AggregatorV3Interface(dataFeed_);
    data = userData(buyPrice_, sellPrice_, initialAmount_, ownerOfBot_);

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(ADMIN_ROLE, msg.sender);
  }

  //------------------ PUBLIC FUNCTIONS ------------------
  function buy() public onlyRole(ADMIN_ROLE){
    uint balance = getBalanceStable();
    require(balance > 0, "Next movement is sell, dont but now");
    bool canExec = _getPrice() <= getBuyPrice();
    require(canExec, "Over price to buy");

    swapExactInputSingle(balance, address(this), address(stableCoin), address(tradeableToken));
  }
  function sell() public onlyRole(ADMIN_ROLE){
    uint balance = getBalanceStable();
    require(balance <= 0, "Next movement is sell, dont but now");
    bool canExec = _getPrice() >= getBuyPrice();
    require(canExec, "Under price to sell");

    swapExactInputSingle(balance, address(this), address(tradeableToken), address(stableCoin));
  }

  function withdraw() public onlyRole(ADMIN_ROLE){
    uint balanceStable = getBalanceStable();
    uint balanceTradeableToken = getBalanceTradeableToken();

    if(balanceStable>0){
      stableCoin.transfer(data.admin, balanceStable);
    }
    if(balanceTradeableToken>0){
      tradeableToken.transfer(data.admin, balanceTradeableToken);
    }
  }
  
  function togglePause() public onlyRole(ADMIN_ROLE){
    paused = !paused;
  }

  // ------------------ VIEW FUNCTIONS ------------------
  function getBuyPrice()public view returns(uint){
    return data.buyPrice;
  }

  //if return true => waitingBuy |  if return false => waitingSell
  function getBalanceStable() public view returns(uint){
    return stableCoin.balanceOf(address(this));
  }
  function getBalanceTradeableToken() public view returns(uint){
    return tradeableToken.balanceOf(address(this));
  }


  // ------------------ PRIVATE FUNCTIONS ------------------ -> public for tests
  function _getPrice() public view returns (uint){
    (,int price,,,) = dataFeed.latestRoundData();
    return uint(price);
  }

}