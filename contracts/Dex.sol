// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

contract Dex{
    address payable public owner;

    //Aave ERC20 token address on testnet Sepolia
    address private immutable daiAddress = 0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357;
    address private immutable usdcAddress = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;

    IERC20 private dai;
    IERC20 private usdc;

    //exchange rates in two exchanges to perform arbitrage
    uint dexARate = 90;
    uint dexBRate = 100;

    //keep track of token balances of the user that they have deposited in the DEX
    mapping(address => uint) daiBalances;
    mapping(address => uint) usdcBalances;

    constructor(){
        owner = payable(msg.sender);
        dai = IERC20(daiAddress);
        usdc = IERC20(usdcAddress);
    }

    //function to deposit USDC
    function depositUSDC(uint _amount) external{
        usdcBalances[msg.sender] += _amount;

        //buying amount permission that the msg.sender -> has given to the smart contract
        uint allowance = usdc.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token amount.");

        //to perform a transferFrom we need to have a pre-approval
        usdc.transferFrom(msg.sender,address(this),_amount);
    }

    //function to deposit DAI
    function depositDAI(uint _amount) external{
        daiBalances[msg.sender] += _amount;

        //buying amount permission that the contract has
        uint allowance = dai.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token amount.");
        dai.transferFrom(msg.sender,address(this),_amount);
    }

    //function to buy DAI -> use the conversion rate to convert from DAI to USDC
    function buyDAI() external{
        uint daiToReceive = ((usdcBalances[msg.sender] / dexARate) * 100) *(10**12);
        dai.transfer(msg.sender,daiToReceive);
    }

    //function to sell DAI
    function sellDAI() external{
        //uses the DAI balance that they have on the DEX
        uint usdcToReceive = ((daiBalances[msg.sender] * dexBRate) / 100) /(10**12);
        usdc.transfer(msg.sender,usdcToReceive);
    }

    //functions to get the balances of the token and withdraw amount
    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Only the owner can call this function.");
        _;
    }

    receive() external payable {}
}