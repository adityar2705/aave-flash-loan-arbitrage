const { ethers } = require("hardhat");

//deploying the Dex contract to use for our arbitrage
async function main(){
    const Dex = await ethers.getContractFactory("Dex");
    const dex = await Dex.deploy();

    await dex.waitForDeployment();

    console.log("Dex smart contract deployed on address : ", dex.target);
}

//main + error handling
main().then(() => {
    process.exit(0);
}).catch((error) => {
    console.error(error);
    process.exit(1);
});