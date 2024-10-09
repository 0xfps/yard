const collectionsJson = require("../json/collections.json")
const dotenv = require("dotenv")
const { ethers } = require("hardhat")
const fs = require("fs")
const path = require("path")
const hardhatConfig = require("../../hardhat.config")
const erc721Abi = require("../json/erc721.json")

dotenv.config()

const pairCreatorPrivateKey = process.env.PRIVATE_KEY
let pairCreatorWallet = new ethers.Wallet(pairCreatorPrivateKey)

const collectionsChains = Object.keys(collectionsJson.chains)

const destinationDir = path.join(__dirname, "/logs")
const destinationFile = path.join(__dirname, "/logs/mints.json")

let currentChain
let nftInstance
let currentNFTAddress
const MINT_SIZE = 125
let mintsObject = {}

if (!fs.existsSync(destinationDir)) {
    fs.mkdirSync(destinationDir)
}

async function mintNFTsOnAllChains() {
    for (let chain of collectionsChains) {
        if (chain != "sepolia") continue
        console.log({ chain })
        await mintAllNFTsOnChain(chain)
        console.log("Minted", MINT_SIZE, "on", chain)
    }
    writeObjectToFile()
}

async function mintAllNFTsOnChain(chainName) {
    currentChain = chainName
    const nftDeploymentAddresses = extractNFTDeploymentAddressesOnChain()
    setUpProviderAndWallet()

    for (let address of nftDeploymentAddresses) {
        currentNFTAddress = address
        setUpNFTInstance()
        const tokenStartIndex = await nftInstance.tokenIndex()
        const tx = await nftInstance.mint(pairCreatorWallet.address, BigInt(MINT_SIZE))
        await tx.wait()
        writeMintToObject(currentNFTAddress, Number(tokenStartIndex))
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

function writeMintToObject(collection, startIndex) {
    mintsObject = {
        ...mintsObject,
        [currentChain]: {
            ...mintsObject[currentChain],
            [collection]: startIndex
        }
    }
}

function writeObjectToFile() {
    if (fs.existsSync(destinationFile)) {
        const existingFileContents = JSON.parse(fs.readFileSync(destinationFile))
        const newFileContent = {
            ...existingFileContents,
            ...mintsObject
        }
        fs.writeFileSync(destinationFile, JSON.stringify(newFileContent))
    } else {
        fs.writeFileSync(destinationFile, JSON.stringify(mintsObject))
    }
    mintsObject = {}
}

mintNFTsOnAllChains()