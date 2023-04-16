const hre = require("hardhat");

async function main() {
  const PriceConsumerV3 = await hre.ethers.getContractFactory("PriceConsumerV3");
  const priceConsumerV3 = await PriceConsumerV3.deploy();
  await priceConsumerV3.deployed();

  console.log(
    `Finished writing oracle price contract address: ${priceConsumerV3.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
