//Flash Loan smart contract deployed on address :  0x8767183f93Cb02731f3b1ec15b42071458a97fF5
const { ethers } = require("hardhat");

//deploying with the provider address
async function main(){
    const FlashLoan = await ethers.getContractFactory("FlashLoan");
    const flashLoan = await FlashLoan.deploy("0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A");

    await flashLoan.waitForDeployment();

    console.log("Flash Loan smart contract deployed on address : ", flashLoan.target);
}

//main + error handling
main().then(() => {
    process.exit(0);
}).catch((error) => {
    console.error(error);
    process.exit(1);
});