//things to achieve in this project
//Get funds from users
// withdraw funds
//set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //working with solidity ABI Interface
    function getVersion() internal  view returns (uint256)  {
        //Address - 0x694AA1769357215DE4FAC081bf1f309aDC325306
        //and ABI - Aggregatorv3Interface

        AggregatorV3Interface priceData = AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF);
       return  priceData.version(); //returns the version which is in uint256
    }

    function getPrice() internal view  returns (uint256) {
        //Address - 0x694AA1769357215DE4FAC081bf1f309aDC325306
        //and ABI - Aggregatorv3Interface
        AggregatorV3Interface priceData = AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF);
       (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceData.latestRoundData();
        
        //price of ETH in terms of USD
        //answer returned of ETH are in 8 zeros i.e 1.00000000 - type int256 while
        //msg.value price is 18 zeros 1.e 1.000000000000000000 -type uint256
        //so we need them to match up, adding 10 more decimals

        return  uint256(answer * 1e10); // - adding 10 more decimals - converting TYPE int256 to uint256
    }

//get conversion rate in terms of usd of the ETH 
    function getConversionRate(uint256 ethAmount) internal view returns (uint256) {
        // 1 ETH?
        // 2000_000000000000000000
        uint256 ethPrice = getPrice();
        // (2000_00000000000000000 * 1_000000000000000000) / 1e18
        // $2000 = 1 ETH
        uint256 ethAmountInUsd = (ethPrice * ethAmount)/ 1e18;
        return  ethAmountInUsd;
    }

}

//gas to create contract - 817513wei

//Error handler
error NotOwner();


contract FundMe {
    using PriceConverter for uint256;

//let's learn about- constant or immutable keyword -- saves gas
    address[] public funders; //to store the senders addresses

    address public immutable i_owner; //it is immutable, that is once, it's set, cannot be changed again

    mapping (address funder => uint256 amountFunded) public addressToAmountFunded;

//constant variable because the value is set/initialized at declaration
    uint256 public constant MINIMUM_USD = 5e18; //converting the usd to wei - 5usd

//constructor are like function that are immediately called when the contract is deployed
    constructor() {
        i_owner = msg.sender; //this msg.sender address would be the deployer of the contract address
    }



    //allow users send ETH and minimum usd through a function
    //payable allows the function to rececive payment
    function fund() public payable  {
        //what is revert
        //undo any actions that might have been done and send the remaining gas back
        

        //we use msg.value to get the wei(ETH) sent
        //we can use the require() for logical operation
        //msg.value is going to be the first params to be passed into the getConversionRate func
        require(msg.value.getConversionRate() >= MINIMUM_USD, "didn't send enough ETH"); // 1e18 means 1ETH which means 1000000000000000000(18 zeros)wei
       
       //push the sender address to array
        funders.push(msg.sender); // to get the sender address of the funds

        // assign address to the key and assign ETH to the value
        
        addressToAmountFunded[msg.sender]  +=  msg.value; //using the += to update the value of the key

    }

// we added a modifier to allow only the owner access the content of the function
    function withdraw() public onlyOwner {

        //make sure the withdrawer address is the owner --- i used modifier instead
        // require(msg.sender == i_owner, "Must be owner");

        //code
        //for loop
        //[1,2,3,4] element
        //0,1,2,3 indexes

        //looping through an array 
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
           address funder = funders[funderIndex]; 
           addressToAmountFunded[funder] = 0;
        }

        //resetting an array
        funders = new address[](0);

        //actually withdraw the funds
        // 3 different ways to withdraw ETH- transfer, send and call
        //transfer(least recommended)
        // payable(msg.sender).transfer(address(this).balance); //transfer - automatically throws an error if the gas is above 2300 wei

        //send (recommended)
        // bool sendSuccess = payable (msg.sender).send(address(this).balance); //it returns a boolean if the gas is above 2300wei
        // require(sendSuccess, "Send Failed");

        //call - seems to be the best recommended - i commented out transfer and send
       (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Send Failed");

    }

    modifier onlyOwner(){
        // require(msg.sender == i_owner, "Sender must be the owner!");
        
        if (msg.sender != i_owner) { //we are using the new error Handler instead of require
            revert NotOwner();
        }
        _; //this continues the code in the function where the modifier is called
    }

    //what happens if someone sends this contract ETH without using the send func.

    //receive()
    receive() external payable { 
        fund();
    }
    //fallback()
    fallback() external payable { 
        fund();
    }

}