// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract PayAcceptStorage {
    
    
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal constant _name = "PayAccept Token" ;
    string internal constant _symbol = "PAYT";
    uint8 internal constant _decimals = 18;
    uint256 internal constant _maxSupply = 45000000 ether;
    
     /**
     * @dev enum of current crowd sale state
     **/
    enum Stages {presale, saleStart, saleEnd}
    
    
    /**
     * @dev user get token when send 1 ether
     **/
    uint256 public basePrice;

    /**
     * @dev pattern follow for bonus like
     * 5 ETH >= 5% ,10 ETH >= 10%,20 ETH >= 15%,40 ETH >= 20%,80 ETH >= 25% and so on
     * Here pattern follow mulitply with 2 and increase in 5%
     **/
    uint256 public bonusStartFrom;
    
  
    /**
     * @dev divide by 100 to achive into fraction
     **/
    uint256 public bonusMultiplyer;
    
    /**
     * @dev token sale currentStage
     **/
    Stages public currentStage;
    
     /**
     * @dev check if address is in paynode
    **/
    mapping(address => bool) public isPayNoder;
    
    /**
     * @dev maintain array index for address
    **/
    mapping(address => uint256) public payNoderIndex;
    
    /**
     * @dev list of paynoder 
    **/
    address[] public payNoders;
    
    /**
     * @dev maximum paynoder 
    **/
    uint256 public payNoderSlot;
    
    /**
     * @dev minimum balance require for be in paynode
    **/
    uint256 public minimumBalance;
    
    /**
     * @dev divide by 100 to achive into fraction
     * it is mulitply
    **/
    uint256 public extraMintForPayNodes;
    
    /**
     * @dev stack timer 
    **/
    uint256 public stackClaimWindow;
    
    /**
     * @dev stack current time when current stack is end  
    **/
    uint256 public currentStackPeriod;
    
    /**
     * @dev stack current id
    **/
    uint256 public currentStackId;
    
    /**
     * @dev mint percent annualy on balance 
     * value is mulitply of 100
    **/
    uint256 public annualMintPercentage;
    
    
    /**
     * @dev old contract address for swap  
    **/
    address public _swapWithOld;

 
    /**
     * @dev record each stacking start time 
    **/
    mapping(uint256 => uint256) public stackStartTiming;
    
    /**
     * @dev record each user last stack claimed time
    **/
    mapping(address => uint256) public lastStackClaimed;
    
    uint256 public teamTokens;
    uint256 public marketingTokens;
    mapping(uint8 => uint256) public teamTokenUnlockDate;
    mapping(uint8 => uint256) public teamTokenUnlockAmount;
    mapping(uint8 => bool) public teamTokenUnlocked;
    uint256 teamTokenUnlockLength;

    event TokenSaleStarted(uint256 time);
    event TokenSaleEnded(uint256 time);
    event BasePriceChanged(uint256 oldPrice, uint256 _newPrice);
    
    
}