const hre = require("hardhat");

async function main() {
  const StableToken = await hre.ethers.getContractFactory("StableToken");
  const stableToken = await StableToken.deploy();
  await stableToken.deployed();

  console.log(
    `Finished writing stable token contract address: ${stableToken.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
