const collectionsJson = require("../json/collections.json")
const deploymentsJson = require("../config/deployments.json")
const { router: routerAbi, factory: factoryAbi } = require("../config/abis.json")
const fs = require("fs")
const path = require("path")
const dotenv = require("dotenv")
const { ethers } = require("hardhat")
const hardhatConfig = require("../../hardhat.config")
const mints = require("./logs/mints.json")

dotenv.config()

const pairCreatorPrivateKey = process.env.PRIVATE_KEY
let pairCreatorWallet = new ethers.Wallet(pairCreatorPrivateKey)

const collectionsChains = Object.keys(collectionsJson.chains)

const destinationDir = path.join(__dirname, "/logs")
const destinationFile = path.join(__dirname, "/logs/pairs.json")

let currentChain
let yardRouterInstance
let yardFactoryInstance
let pairsObject = {}

if (!fs.existsSync(destinationDir)) {
    fs.mkdirSync(destinationDir)
}

async function createPairsForAllNFTsOnAllChains() {
    for (let chain of collectionsChains) {
        await createPairsForAllNFTsOnChain(chain)
    }
}

async function createPairsForAllNFTsOnChain(chainName) {
    currentChain = chainName
    const nftDeploymentAddresses = extractNFTDeploymentAddressesOnChain()
    const stopIndex = nftDeploymentAddresses.length - 2
    for (let i = 0; i <= stopIndex; i++) {
        const currentNFT = nftDeploymentAddresses[i]
        const otherNFTs = nftDeploymentAddresses.slice(i + 1, nftDeploymentAddresses.length)
        await createPairForCurrentNFTWithEachOfTheOtherNFTs(currentNFT, otherNFTs)
    }

    writeObjectToFile()
}

function extractNFTDeploymentAddressesOnChain() {
    const chainCollections = collectionsJson.chains[currentChain]
    const chainCollectionsDeploymentAddresses = chainCollections.map(function ({ address }) {
        return address
    })
    return chainCollectionsDeploymentAddresses
}

async function createPairForCurrentNFTWithEachOfTheOtherNFTs(thisNFT, otherNFTs) {
    setUpProviderAndWallet()
    setUpFactoryInstance()
    setUpRouterInstance()

    for (let nft of otherNFTs) {
        const pair = await yardFactoryInstance.getPair(thisNFT, nft)
        writePairToObject(pair)
    }
}

async function setUpProviderAndWallet() {
    const RPC = hardhatConfig.networks[currentChain].url
    const provider = new ethers.JsonRpcProvider(RPC)
    pairCreatorWallet = pairCreatorWallet.connect(provider)
}

async function setUpRouterInstance() {
    if (!pairCreatorWallet)
        throw new Error("Pair creator wallet not set.")

    const routerAddress = deploymentsJson[currentChain].router
    const yardRouterContractInstance = new ethers.Contract(routerAddress, routerAbi, pairCreatorWallet)
    yardRouterInstance = yardRouterContractInstance
}

async function setUpFactoryInstance() {
    if (!pairCreatorWallet)
        throw new Error("Pair creator wallet not set.")

    const factoryAddress = deploymentsJson[currentChain].factory
    const yardFactoryContractInstance = new ethers.Contract(factoryAddress, factoryAbi, pairCreatorWallet)
    yardFactoryInstance = yardFactoryContractInstance
}

function writePairToObject(pair) {
    const writtenPairs = pairsObject[currentChain]
    const newWrite = writtenPairs ? [...writtenPairs, pair] : [pair]
    pairsObject = {
        [currentChain]: newWrite
    }
}

function writeObjectToFile() {
    if (fs.existsSync(destinationFile)) {
        const existingFileContents = JSON.parse(fs.readFileSync(destinationFile))
        const newFileContent = {
            ...existingFileContents,
            ...pairsObject
        }
        fs.writeFileSync(destinationFile, JSON.stringify(newFileContent))
    } else {
        fs.writeFileSync(destinationFile, JSON.stringify(pairsObject))
    }
    pairsObject = {}
}

function generateArrayOfLength25(start) {
    const finalArray = []
    const end = start + 25
    for (let i = start; i < end; i++) {
        finalArray.push(i)
    }
    console.log(finalArray)
    console.log(end)
}

generateArrayOfLength25(203)

createPairsForAllNFTsOnAllChains()