const hre = require("hardhat");


async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  console.log("\n\n");

  const NFTGridData = await hre.ethers.getContractFactory("NFTGridData");
  const nftGridData = await NFTGridData.deploy();
  await nftGridData.deployed();

  const GridBotFactory = await hre.ethers.getContractFactory("GridBotFactory");
  const gridBotFactory = await GridBotFactory.deploy(nftGridData.address);
  await gridBotFactory.deployed();

  console.log(`  NFTGridData Address: ${nftGridData.address}`);
  console.log(`  GridBotFactory Address: ${gridBotFactory.address}`);

  const WAIT_BLOCK_CONFIRMATION = 6;
  await nftGridData.deployTransaction.wait(WAIT_BLOCK_CONFIRMATION);
  await gridBotFactory.deployTransaction.wait(WAIT_BLOCK_CONFIRMATION);

  console.log(`Verifying contract on Scan`);

  await run(`verify:verify`,{
    address: nftGridData.address,
    constructorArguments: [    
    ],
    contract: "contracts/NFTGridData.sol:NFTGridData",
  })
  await run(`verify:verify`,{
    address: gridBotFactory.address,
    constructorArguments: [nftGridData.address],
    contract: "contracts/GridBotFactory.sol:GridBotFactory",
  })


  console.log(`\n\n END Script`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
