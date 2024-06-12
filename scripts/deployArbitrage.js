//Flash loan arbitrage smart contract deployed on address :  0xFF3348D15529c4bC38E94BE1568059ab61c50f3e
const { ethers } = require("hardhat");

//deploying the Dex contract to use for our arbitrage
async function main(){
    const Arbitrage = await ethers.getContractFactory("FlashLoanArbitrage");
    const arbitrage = await Arbitrage.deploy("0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A");

    await arbitrage.waitForDeployment();

    console.log("Flash loan arbitrage smart contract deployed on address : ", arbitrage.target);
}

//main + error handling
main().then(() => {
    process.exit(0);
}).catch((error) => {
    console.error(error);
    process.exit(1);
});