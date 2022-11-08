// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // to get price link
import "./SpotBotGrid.sol";
import "./UpKeepIDRegisterFactory.sol";
import "./interfaces/INFTGridData.sol";

contract GridBotFactory is AccessControl {
  bytes32 public constant ADMIN = keccak256("ADMIN");
  uint public totalGrids;
  address[] public listOfAllGrid;
  struct userData{
    address gridBotAddress;
    uint nftID;    
  }

  mapping(address => userData[]) public listOfGridsPerUser;
  
  INFTGridData nftGrid;
  AggregatorV3Interface maticUsdFeed;
  AggregatorV3Interface linkUsdFeed;
  UpKeepIDRegisterFactory registerKeeps;
  IERC20 public currency;


  constructor(address _NFTGridData, address _currency, address _registerKeeps) {
    currency = IERC20(_currency);
    nftGrid = INFTGridData(_NFTGridData);
    registerKeeps = UpKeepIDRegisterFactory(_registerKeeps);
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
    require(msg.value >= (calculatePriceInMatic()/1000), "need more matic");
    uint id = nftGrid.getCurrentId();

    address newGrid = _newGrid(tradeableToken_, buyPrice_, sellPrice_, owner_, id); 
    registerKeeps.checkAndResolve(name, newGrid );
    nftGrid.safeMint(owner_, uri_, newGrid);
    
    _updateData(newGrid,id,owner_);
  }

  function changeOwnerOfNFT(address newOwner)public onlyRole(ADMIN){
    nftGrid.transferOwnership(newOwner);
  }

  // --------------------------------- VIEW FUNCTIONS ---------------------------------

  function getTotalNumberOfGrid(address _user)public view returns(uint){
    return listOfGridsPerUser[_user].length;
  }

  function getGridDataPerUser(
    address _user, 
    uint index
  )public view returns(
    address,
    uint nftID,
    uint buyPrice,
    uint sellPrice,
    address 
  ){
    SpotBotGrid grid = SpotBotGrid(listOfGridsPerUser[_user][index].gridBotAddress);
    nftID = listOfGridsPerUser[_user][index].nftID;
    buyPrice = grid.getBuyPrice();
    sellPrice = grid.getBuyPrice();

    return(address(grid), nftID, buyPrice, sellPrice, grid.getTradeableTokenAddress());
  }

  // --------------------------------- INTERNAL FUNCTIONS ---------------------------------

  function _newGrid(address _tradeableToken, uint _buyPrice, uint _sellPrice, address _owner, uint id) internal returns(address newGrid){
    newGrid = address(new SpotBotGrid(
      address(currency),
      _tradeableToken,
      0x007A22900a3B98143368Bd5906f8E17e9867581b, // Datafeed btc/usd mumbai
      _buyPrice,
      _sellPrice,
      0,
      _owner,
      0xE592427A0AEce92De3Edee1F18E0157C05861564, //swap router, can be constant in mainet
      id
    ));
  }

  function _updateData(address _grid, uint _id,address _owner) internal {
    listOfAllGrid.push(_grid);
    totalGrids++;
    listOfGridsPerUser[_owner].push(userData(_grid, _id));
  }


  function calculatePriceInMatic() public view returns(uint){
    uint linkPrice = _getPrice(linkUsdFeed);
    uint maticPrice = _getPrice(maticUsdFeed)*10000000000;
    uint cantInMatic = (linkPrice / maticPrice) * 1 ether;

    return cantInMatic + 1 ether;
  }

  function _getPrice(AggregatorV3Interface dataFeed) public view returns (uint){
    (,int price,,,) = dataFeed.latestRoundData();
    return uint(price);
  }
}