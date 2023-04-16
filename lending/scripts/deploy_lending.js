const hre = require("hardhat");

async function main() {
  const LendingPoolV1 = await hre.ethers.getContractFactory("LendingPoolV1");
  const lending = await LendingPoolV1.deploy();
  await lending.deployed();

  console.log(
    `Finished writing lending contract address: ${lending.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
