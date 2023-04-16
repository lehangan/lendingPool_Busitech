require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
const ALCHEMY_API_KEY = "9Pdl63oZZ5oSpbyXWykLmAVQU1BsOBaV";

const SEPOLIA_PRIVATE_KEY = "b6458af28172bacef5aa0e38929cc07e3737c88e781f7d9e30ef83684c0c8baa";
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.18",
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY]
    }
  }
};
