const collectionsJson = require("../json/collections.json")
const deploymentsJson = require("../config/deployments.json")
const dotenv = require("dotenv")
const { ethers } = require("hardhat")
const hardhatConfig = require("../../hardhat.config")
const erc721Abi = require("../json/erc721.json")

dotenv.config()

const pairCreatorPrivateKey = process.env.PRIVATE_KEY
let pairCreatorWallet = new ethers.Wallet(pairCreatorPrivateKey)

const collectionsChains = Object.keys(collectionsJson.chains)

let currentChain
let nftInstance
let router

async function approveAllNFTsOnAllChains() {
    for (let chain of collectionsChains) {
        console.log({ chain })
        router = deploymentsJson[chain].router
        await approveAllNFTsOnChain(chain)
        console.log("Approved all on", chain)
    }
}

async function approveAllNFTsOnChain(chainName) {
    currentChain = chainName
    const nftDeploymentAddresses = extractNFTDeploymentAddressesOnChain()
    setUpProviderAndWallet()

    for (let address of nftDeploymentAddresses) {
        currentNFTAddress = address
        setUpNFTInstance()
        const tx = await nftInstance.setApprovalForAll(router, true)
        await tx.wait()
    }
}

function extractNFTDeploymentAddressesOnChain() {
    const chainCollections = collectionsJson.chains[currentChain]
    const chainCollectionsDeploymentAddresses = chainCollections.map(function ({ address }) {
        return address
    })
    return chainCollectionsDeploymentAddresses
}

async function setUpProviderAndWallet() {
    const RPC = hardhatConfig.networks[currentChain].url
    const provider = new ethers.JsonRpcProvider(RPC)
    pairCreatorWallet = pairCreatorWallet.connect(provider)
}

async function setUpNFTInstance() {
    if (!pairCreatorWallet)
        throw new Error("Pair creator wallet not set.")

    const erc721Instance = new ethers.Contract(currentNFTAddress, erc721Abi, pairCreatorWallet)
    nftInstance = erc721Instance
}

approveAllNFTsOnAllChains()