const { ethers, network, run } = require("hardhat")
const dotenv = require("dotenv")
const { existsSync, readFileSync, mkdirSync, writeFileSync } = require("fs")
const path = require("path")
const tokens = require("./json/tokens.json")

dotenv.config()

const BLOCKS = 10
const destinationDir = path.join(__dirname, "/config")
const destination = path.join(__dirname, "/config/config.json")

if (!existsSync(destinationDir)) {
    mkdirSync(destinationDir);
}

async function main() {
    const networkName = network.name
    const feeToken = tokens[networkName]
    let configObject = existsSync(destination) ? JSON.parse(readFileSync(destination)) : {}

    // Deploying YardNFTWrapper.
    console.log(`############### Deploying YardNFTWrapper on ${networkName}. ###############`)
    const YardNFTWrapper = await ethers.getContractFactory("YardNFTWrapper")
    const yardNFTWrapper = await YardNFTWrapper.deploy()
    await yardNFTWrapper.deploymentTransaction().wait(BLOCKS)
    const yardNFTWrapperAddress = await yardNFTWrapper.getAddress()

    await run("verify:verify", {
        address: yardNFTWrapperAddress,
        constructorArguments: []
    })

    configObject = {
        ...configObject,
        [networkName]: {
            ...configObject[networkName],
            wrapper: yardNFTWrapperAddress,
            feeToken
        }
    }

    console.log(`############### YardNFTWrapper on ${networkName} at ${yardNFTWrapperAddress}. ###############`)
    // Deployment of YardNFTWrapper finished.

    // Deploying YardFactory.
    console.log(`############### Deploying YardFactory on ${networkName}. ###############`)
    const YardFactory = await ethers.getContractFactory("YardFactory")
    const yardFactory = await YardFactory.deploy()
    await yardFactory.deploymentTransaction().wait(BLOCKS)
    const yardFactoryAddress = await yardFactory.getAddress()

    await run("verify:verify", {
        address: yardFactoryAddress,
        constructorArguments: []
    })

    configObject = {
        ...configObject,
        [networkName]: {
            ...configObject[networkName],
            factory: yardFactoryAddress
        }
    }

    console.log(`############### YardFactory on ${networkName} at ${yardFactoryAddress}. ###############`)
    // Deployment of YardFactory finished.

    // Deploying YardRouter.
    console.log(`############### Deploying YardRouter on ${networkName}. ###############`)
    const YardRouter = await ethers.getContractFactory("YardRouter")
    const yardRouter = await YardRouter.deploy(feeToken, yardNFTWrapperAddress)
    await yardRouter.deploymentTransaction().wait(BLOCKS)
    const yardRouterAddress = await yardRouter.getAddress()

    await run("verify:verify", {
        address: yardRouterAddress,
        constructorArguments: [feeToken, yardNFTWrapperAddress]
    })

    configObject = {
        ...configObject,
        [networkName]: {
            ...configObject[networkName],
            router: yardRouterAddress
        }
    }

    console.log(`############### YardRouter on ${networkName} at ${yardRouterAddress}. ###############`)
    // Deployment of YardRouter finished.

    // Write to file.
    try {
        writeFileSync(destination, JSON.stringify(configObject))
    } catch (e) {
        console.log(e)
    }
    // Write to file.


    console.log(`############### Configuring... ###############`)
    // Configurations.
    // Configuring YardRouter.
    // Set factory in YardRouter.
    const setFactoryTx = await yardRouter.setFactory(yardFactoryAddress)
    await setFactoryTx.wait()
    console.log(`############### Set factory in YardRouter. ###############`)

    // Configuring YardNFTWrapper.
    // Set factory in YardNFTWrapper.
    const setFactoryTx2 = await yardNFTWrapper.setFactory(yardFactoryAddress)
    await setFactoryTx2.wait()
    console.log(`############### Set factory in YardNFTWrapper. ###############`)

    // Configuring YardFactory.
    // Set NFT Wrapper in YardFactory.
    const setNFTWrapperTx = await yardFactory.setWrapper(yardNFTWrapperAddress)
    await setNFTWrapperTx.wait()
    console.log(`############### Set NFT Wrapper in YardFactory. ###############`)
    // Set Router in YardFactory.
    const setRouterTx = await yardFactory.setRouter(yardRouterAddress)
    await setRouterTx.wait()
    console.log(`############### Set Router in YardFactory. ###############`)
}

main()