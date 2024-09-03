require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
const dotenv = require("dotenv")

dotenv.config()
const { PRIVATE_KEY, ARBITRUM_TOKEN, BASE_TOKEN, BSC_TOKEN, SCROLL_TOKEN, SEPOLIA_TOKEN, INFURA_ID } = process.env

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  },
  etherscan: {
    apiKey: {
      arbitrumSepolia: ARBITRUM_TOKEN,
      baseSepolia: BASE_TOKEN,
      bscTestnet: BSC_TOKEN,
      scroll: SCROLL_TOKEN,
      sepolia: SEPOLIA_TOKEN,
    },
    customChains: [{
      network: "scroll",
      chainId: 534351,
      urls: {
        apiURL: "https://api-sepolia.scrollscan.com/api",
        browserURL: "https://api-sepolia.scrollscan.com/api"
      }
    }
    ]
  },
  networks: {
    arbitrum: {
      url: `https://arbitrum-sepolia.infura.io/v3/${INFURA_ID}`,
      chainId: 421614,
      accounts: [PRIVATE_KEY],
      allowUnlimitedContractSize: true,
    },
    base: {
      url: "https://base-sepolia.blockpi.network/v1/rpc/public",
      chainId: 84532,
      accounts: [PRIVATE_KEY],
      allowUnlimitedContractSize: true,
    },
    bsc: {
      url: "https://bsc-testnet-rpc.publicnode.com",
      chainId: 97,
      accounts: [PRIVATE_KEY],
      allowUnlimitedContractSize: true,
    },
    scroll: {
      url: "https://scroll-public.scroll-testnet.quiknode.pro",
      chainId: 534351,
      accounts: [PRIVATE_KEY],
      allowUnlimitedContractSize: true
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${INFURA_ID}`,
      chainId: 11155111,
      accounts: [PRIVATE_KEY],
      allowUnlimitedContractSize: true,
      gasPrice: 50_000_000_000
    }
  }
};