// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

//using the Dex contract interface
interface IDex{
    function depositUSDC(uint _amount) external;

    function depositDAI(uint _amount) external;

    function buyDAI() external;

    function sellDAI() external;
}

contract FlashLoanArbitrage is FlashLoanSimpleReceiverBase{
    address payable owner;

    //Aave ERC20 token address on testnet Sepolia + Dex contract address
    address private immutable daiAddress = 0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357;
    address private immutable usdcAddress = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
    address private immutable dexContractAddress = 0xf1900559e0f1E7f48e1e2C388fF87a7c38e8E373;

    IERC20 private dai;
    IERC20 private usdc;
    IDex private dexContract;


    //constructor -> giving the initial address provider to the receiver base
    constructor(address _addressProvider) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)){
        owner = payable(msg.sender);
        dai = IERC20(daiAddress);
        usdc = IERC20(usdcAddress);

        dexContract = IDex(dexContractAddress);
    }

    //overriding execute operation -> called after we receive the flash loaned amount
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns(bool){
       uint amountOwed = amount + premium;
       initiator = initiator;
       params = params;

       //performing the arbitrage
       dexContract.depositUSDC(1000000000); //1000 USDC

       //buying DAI through the smart contract using USDC on the DEX along with the exchange rate to exchange for DAI
       dexContract.buyDAI();
       dexContract.depositDAI(dai.balanceOf(address(this)));

       //the DEX we sell on has a different exchange rate so we make a profit
       dexContract.sellDAI();

       //we give the pool address approval to use amount + premium
       IERC20(asset).approve(address(POOL),amountOwed);

       return true;
    }

    //requesting the flash loan
    function requestFlashLoan(address _token, uint256 _amount) public{
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;

        //using the POOL flashLoanSimple to execute the flash loan -> main function which executes the flash loan with all the params
        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }

    //approve USDC -> smart contract approves the DEX contract for this much amount
    function approveUSDC(uint256 _amount) external returns (bool) {
        //flash loan smart contract approves DEX to use USDC -> the one it gets from the Aave flash loan
        return usdc.approve(dexContractAddress, _amount);
    }

    //check USDC allowance that the contract has given to the DEX contract
    function allowanceUSDC() external view returns (uint256) {
        return usdc.allowance(address(this), dexContractAddress);
    }

    //approve DAI
    function approveDAI(uint256 _amount) external returns (bool) {
        return dai.approve(dexContractAddress, _amount);
    }

    //check DAI allowance that the contract has given to the DEX contract
    function allowanceDAI() external view returns (uint256) {
        return dai.allowance(address(this), dexContractAddress);
    }

    //function to check our balance of a particular ERC20 contract
    function getBalance(address _tokenAddress) external view returns(uint256){
        //we use the smart contract address since this is the one executing the flash loan
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    //function to withdraw the tokens -> all the holdings of the smart contract
    function withdraw(address _tokenAddress) external onlyOwner{
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    //only owner modifier
    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner can call this function.");
        _;
    }

    //to be able to send Ether to the smart contract
    receive() external payable {}

}