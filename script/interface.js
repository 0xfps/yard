const { ethers } = require("hardhat")
const { readFileSync, existsSync, writeFileSync, mkdirSync } = require("fs")
const path = require("path")

const destinationDir = path.join(__dirname, "/config")
const destination = path.join(__dirname, "/config/abis.json")

if (!existsSync(destinationDir)) {
    mkdirSync(destinationDir)
}

async function main() {
    let abis = existsSync(destination) ? JSON.parse(readFileSync(destination)) : {}
    const [yardFactory, yardPair, yardRouter] = [await ethers.getContractFactory("YardFactory"), await ethers.getContractFactory("YardPair"), await ethers.getContractFactory("YardRouter")]

    abis = {
        ...abis,
        factory: yardFactory.interface.fragments,
        pair: yardPair.interface.fragments,
        router: yardRouter.interface.fragments
    }

    try {
        writeFileSync(destination, JSON.stringify(abis))
    } catch (e) {
        throw new Error(e)
    }
}

main()