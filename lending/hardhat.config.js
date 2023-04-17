require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
const ALCHEMY_API_KEY = "9Pdl63oZZ5oSpbyXWykLmAVQU1BsOBaV";

const SEPOLIA_PRIVATE_KEY = "0a7d4713015d55bb91844e9151097e88b91c35c5e42a0f1416be704e89b498d1";
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
