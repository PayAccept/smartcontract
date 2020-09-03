// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./StandardToken.sol";
import "./proxy/Upgradeable.sol";

interface PayAcceptInterFace {
    function initialize(
        address _oldTokenAddress,
        uint256 _premintToken,
        uint256 _teamToken,
        uint256 _marketingToken,
        uint256[] calldata _unlockDate,
        uint256[] calldata _unlockAmount,
        address payable _ownerAccount
    ) external;
}

abstract contract TokenSale is StandardToken {

    /**
     * @dev to start token sale 
     **/
    function startTokenSale() external onlyOwner() returns(bool){
        require(currentStage == Stages.presale,"ERR_SALE_ALREADY_START");
        currentStage = Stages.saleStart;
        emit TokenSaleStarted(now);
        return true;
    }
    
    /**
     * @dev to end token sale 
     **/
    function endTokenSale() external onlyOwner() returns(bool){
        require(currentStage == Stages.saleStart,"ERR_SALE_IS_NOT_START");
        currentStage = Stages.saleEnd;
        emit TokenSaleEnded(now);
        return true;
    }
    
    /**
     * @dev modifier to check if sale is runnung 
    **/
    modifier onlyWhenSaleIsOver(){
        require(currentStage == Stages.saleEnd,"ERR_SALE_IS_NOT_OVER");
        _;
    }
    
    /**
     * @dev modifier to check if sale is ended 
    **/
    modifier onlyWhenSaleIsOn(){
        require(currentStage == Stages.saleStart,"ERR_SALE_IS_NOT_RUNNING");
        _;
    }
    
    /**
     * @dev user can buyToken only during sale
    **/
    function buyToken() internal notZeroValue(msg.value) onlyWhenSaleIsOn() {

        uint256 _recivableToken = safeMul(msg.value, basePrice);
        if (msg.value >= bonusStartFrom) {
            uint256 bonusCount = 0;
            uint256 _tempCount = bonusStartFrom;
            while (msg.value >= _tempCount) {
                _tempCount = safeMul(_tempCount, 2);
                bonusCount = safeAdd(bonusCount, 1);
            }
            _recivableToken = safeAdd(
                _recivableToken,
                safeDiv(
                    safeMul(
                        safeMul(_recivableToken, bonusCount),
                        bonusMultiplyer
                    ),
                    10000,
                    "ERR_BONUS"
                )
            );
        }
        owner.transfer(msg.value);
        _mint(msg.sender, _recivableToken);
    }
    
    /**
     * @dev owner can change base price for token 
     * price count base on 1 ether 
     * if value 100 set then 100 token per ether user get
     * only set when tokensale is going on 
    **/
    function changeBasePrice(uint256 _baasePrice)
        external
        onlyOwner()
        onlyWhenSaleIsOn()
        returns (bool ok)
    {
        emit BasePriceChanged(basePrice, _baasePrice);
        basePrice = _baasePrice;
        return true;
    }

    /**
     * @dev owner can  bonus start point 
     * only set when tokensale is going on 
    **/
    function changeBonusStartPoint(uint256 _bonusStartFrom)
        external
        onlyOwner()
        onlyWhenSaleIsOn()
        returns (bool ok)
    {
        bonusStartFrom = _bonusStartFrom;
        return true;
    }
    
    /**
     * @dev fallback for accept ether 
     * user send ether and recive token 
    **/
    receive() external payable{
        buyToken();
    }
    
}

abstract contract Locking is TokenSale{
    
    mapping(address => uint256) public lockingPeriod;
    
    /**
     * @dev owner can lock any account for any amount of time 
     * Requirements
     *
     * - `_whom` address which going to be locked 
     * - `_period` epoch time until token get Locked
     */
    function setLokignPeriod(address _whom,uint256 _period) external onlyOwner() returns (bool){
        lockingPeriod[_whom] = _period;
    }
    
    
    /**
     * @dev modifier for cheking if account is locked
     */
    modifier checkLocking(address _whom){
        require(now >= lockingPeriod[_whom],"ERR_LOCKING_PERIOD_IS_NOT_ENDED");
        _;
    }
    
}


abstract contract Swapping is Locking {
    
  
    /**
     * @dev Returns the bool on success
     * convert old token with this token
     * user have to give allowence to this contract
     * trasnfer address at 0x1 bcz of conditon in old contract
     * old contract dont have burn method
     */
    function swapWithOldToken(uint256 _amount) external returns (bool) {
        IERC20(_swapWithOld).transferFrom(msg.sender, address(1), _amount);
        return _mint(msg.sender, _amount);
    }

}




abstract contract Paynodes is Swapping {
    
  
    /**
     * @dev adding account in paynode 
    **/
    function addaccountToPayNode(address _whom)
        external
        onlyOwner()
        returns (bool)
    {   
        require(payNoders.length <= payNoderSlot ,"ERR_PAYNODE_LIST_FULL");
        require(_balances[_whom] >= minimumBalance,"ERR_PAYNODE_MINIMUM_BALANCE");
        require(isPayNoder[_whom] == false,"ERR_ALREADY_IN_PAYNODE_LIST");
        isPayNoder[_whom] = true;
        payNoderIndex[_whom] = payNoders.length;
        payNoders.push(_whom);
        return true;
    }
    
    
    /**
     * @dev remove account from paynode 
    **/
    function _removeaccountToPayNode(address _whom)
        internal
        returns (bool)
    {
        require(isPayNoder[_whom], ERR_AUTHORIZED_ADDRESS_ONLY);
        uint256 _payNoderIndex = payNoderIndex[_whom];
        address _lastAddress = payNoders[safeSub(payNoders.length, 1)];
        payNoders[_payNoderIndex] = _lastAddress;
        payNoderIndex[_lastAddress] = _payNoderIndex;
        delete isPayNoder[_whom];
        payNoders.pop();
        return true;
    }
    
    /**
     * @dev remove account from paynode 
    **/
    function removeaccountToPayNode(address _whom)
        external
        onlyOwner()
        returns (bool)
    {
        return _removeaccountToPayNode(_whom);
    }
    
    /**
     * @dev owner can change minimum balance requirement
    **/
    function setMinimumBalanceForPayNoder(uint256 _minimumBalance) external onlyOwner() returns(bool){
        minimumBalance = _minimumBalance;
        return true;
    }
    
    /**
     * @dev owner can chane extra mint percent for paynoder 
     * _extraMintForPayNodes is set in percent with mulitply 100
     * if owner want to set 1.25% then value is 125
    **/
    function setExtraMintingForNodes(uint256 _extraMintForPayNodes) external onlyOwner() returns(bool){
        extraMintForPayNodes = _extraMintForPayNodes;
        return true;
    }
   
}

abstract contract Stacking is Paynodes {

    /**
     * @dev stackign started each month by owner 
    **/
    function startStacking() external onlyOwner() returns(uint256){
        require(now > currentStackPeriod ,"LAST_STACK_IS_NOT_FINISHED");
        currentStackId = safeAdd(currentStackId,1);
        currentStackPeriod = safeAdd(now,stackClaimWindow);
        stackStartTiming[currentStackId] = now;
        return currentStackId;
    }
    
    
    function _claimStack(address _whom) internal returns(bool){
        
        require(stackStartTiming[currentStackId] > lastStackClaimed[_whom],"ERR_STACK_ALREADY_CLAIMED");
        require(currentStackPeriod >= now ,"ERR_STACK_CLAIM_WINDOW_OVER");
        uint256 userBalance = _balances[_whom];
        uint256 stackAmount  = safeDiv(safeMul(userBalance,annualMintPercentage),120000);
        if(isPayNoder[_whom]){
            if(userBalance >= minimumBalance){
                stackAmount = safeDiv(safeMul(stackAmount,extraMintForPayNodes),10000);
            }else if(userBalance < minimumBalance){
                _removeaccountToPayNode(_whom);
            }
        }
        
        if(currentStackPeriod > lockingPeriod[_whom]){
            lockingPeriod[_whom] = currentStackPeriod;
        }
        
        lastStackClaimed[_whom] = now;
        _mint(_whom,stackAmount);
        return true;
    }
    
    /**
     * @dev user can claim own stack
    **/
    function claimStack() external returns(bool){
        return _claimStack(msg.sender);
    }
    
    /**
     * @dev owner can distrubute the stack 
    **/
    function sendStackByOwner(address[] calldata _whom) external onlyOwner() returns(bool){
        uint256 currentStackStartTime = stackStartTiming[currentStackId];
        for (uint8 i = 0; i < _whom.length; i++) {
            if(currentStackStartTime > lastStackClaimed[_whom[i]])
                _claimStack(_whom[i]); 
        }
        return true;
    }
    
}




/**
 * @title PayToken
 * @dev Contract to create the PaytToken
 **/
contract PaytToken is Upgradeable,Stacking,PayAcceptInterFace {
    
    function initialize(
        address oldTokenAddress,
        uint256 _premintToken,
        uint256 _teamToken,
        uint256 _marketingToken,
        uint256[] memory _unlockDate,
        uint256[] memory _unlockAmount,
        address payable ownerAccount
    ) public override{
        
        super.initialize();
        
        _swapWithOld = oldTokenAddress;
        teamTokens = _teamToken;
        marketingTokens = _marketingToken;
        owner = ownerAccount;
        _mint(owner,_premintToken);
        _mint(address(this), safeAdd(teamTokens, marketingTokens));
        require(
            _unlockDate.length == _unlockAmount.length,
            "ERR_ARRAY_LENGTH_IS_NOT_SAME"
        );
        uint256 totalUnlockAmount;
        for (uint8 i = 0; i < _unlockAmount.length; i++) {
            teamTokenUnlockDate[i] = _unlockDate[i];
            teamTokenUnlockAmount[i] = _unlockAmount[i];
            totalUnlockAmount = safeAdd(totalUnlockAmount, _unlockAmount[i]);
        }
        teamTokenUnlockLength = _unlockAmount.length;
        require(
            _teamToken == totalUnlockAmount,
            "ERR_UNLOCKING_AMOUNT_DONT_MATCH"
        );
        annualMintPercentage = 1000;
        stackClaimWindow = 86400;
        extraMintForPayNodes = 5000;
        minimumBalance = 45000 ether;
        payNoderSlot = 10;
        bonusMultiplyer = 500;
        bonusStartFrom = 5 ether;
        basePrice = 1000;
        currentStage = Stages.presale;
    }
    
    /**
     * @dev owner unlock team token 
    **/
    function unlockTeamToken(uint8 _unlockId)
        external
        onlyOwner()
        returns (bool)
    {
        require(teamTokens > 0, "ERR_TEAM_BONUS_ZERO");
        require(teamTokenUnlockDate[_unlockId] < now ,"ERR_UNLOCK_DATE_IS_NOT_PASSED");
        require(
            !teamTokenUnlocked[_unlockId],
            "ERR_TOKEN_IS_UNLOCKED_ALEREADY"
        );
        uint256 unlockAmount = teamTokenUnlockAmount[_unlockId];
        _transfer(address(this), owner, unlockAmount);
        teamTokens = safeSub(teamTokens, unlockAmount);
        teamTokenUnlocked[_unlockId] = true;
        return true;
    }
    
    /**
     * @dev owner airdrop token
    **/
    function airDropTokens(address[] memory recipients, uint256[] memory values)
        public
        onlyOwner()
        returns (bool)
    {
        require(
            recipients.length == values.length,
            "ERR_ARRAY_LENGTH_IS_NOT_SAME"
        );
        for (uint8 i = 0; i < recipients.length; i++) {
            if (marketingTokens >= values[i]) {
                _transfer(address(this), recipients[i], values[i]);
                marketingTokens = safeSub(marketingTokens, values[i]);
            }
        }
        return true;
    }
    
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external  virtual override onlyWhenSaleIsOver() checkLocking(msg.sender) returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external virtual onlyWhenSaleIsOver() checkLocking(sender) override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender,safeSub(_allowances[sender][msg.sender],amount));
        return true;
    }

    
    
}
