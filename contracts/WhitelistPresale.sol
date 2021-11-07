//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/IERC20.sol";

contract WhitelistPresale is Ownable {

    event AddressRegistered(address buyer, uint256 amount); // Log the User and the amount they can buy
    
    IERC20 public BUSD = IERC20();
    
    uint8 constant tokensPerBUSD = 1; 
    
    bool public presaleStarted = false;
    bool public isStopped = false;
    bool public isRefundEnabled = false;

    mapping(address => uint) public accountBuyLimit;
    mapping(address => uint) public amountSpent;

    modifier whitelisted{
        require(
            msg.sender == whitelistedAddress, "Not whitelisted";
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function emergencyRefund() external onlyOwner nonReentrant {
        isRefundEnabled = true;
        isStopped = true;
    }

    function getRefund() external nonReentrant {
        require(msg.sender == tx.origin);
        require(!justTrigger);
        // Refund should be enabled by the owner OR 7 days passed 
        require(isRefundEnabled || block.timestamp >= refundTime,"Cannot refund");
        address payable user = msg.sender;
        uint256 amount = amountSpent[user];
        amountSpent[user] = 0;
        BUSD.transfer(user, amount);
    }

    function buyTokens(uint amount) external nonReentrant {
        require(msg.sender == tx.origin);
        require(presaleStarted == true, "Presale is paused, do not send BUSD");
        require(DOGEDOLLAR != IERC20(address(0)), "Main token contract address not set");
        require(!isStopped, "Presale stopped by contract, do not send BUSD");
        require(amount >= accountBuyLimit[msg.sender].mul(90).div(100) , "You cannot send less than 10% of allocated BUSD");
        require(amount <= accountBuyLimit[msg.sender], "You cannot send more than your allocation");
        require(BUSDSent < 40000 ether, "Hard cap reached");
        require (amount.add(BUSDSent) <= 40000 ether, "Hardcap will be reached");
        require(BUSDSpent[msg.sender].add(amount) <= 200 ether, "You cannot buy more");
        uint256 tokens = amount.mul(tokensPerBUSD).div(10**9);
        require(DOGEDOLLAR.balanceOf(address(this)) >= tokens, "Not enough tokens in the contract");

        BUSDSpent[msg.sender] = BUSDSpent[msg.sender].add(amount);
        tokensBought = tokensBought.add(tokens);
        BUSDSent = BUSDSent.add(amount);
        BUSD.transferFrom(msg.sender, address(this), amount)
        DOGEDOLLAR.transfer(msg.sender, tokens);
    }
    
    function registerAddress(address buyer, uint256 buyerLimit) external onlyOwner {
        accountBuyLimit[buyer] = buyerLimit;

    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }
}
