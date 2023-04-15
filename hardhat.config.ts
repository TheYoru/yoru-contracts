import "dotenv/config"
import "@nomiclabs/hardhat-ethers"
import "@nomiclabs/hardhat-etherscan"
import "@nomicfoundation/hardhat-foundry"

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || ""
const NODE_RPC = process.env.NODE_RPC || ""

module.exports = {
    networks: {
        goerli: {
            chainId: 5,
            url: NODE_RPC,
        },
    },
    etherscan: {
        apiKey: ETHERSCAN_API_KEY,
    },
    solidity: {
        compilers: [
            {
                version: "0.8.17",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000,
                    },
                },
            },
        ],
    },
}
