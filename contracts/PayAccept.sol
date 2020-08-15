pragma solidity ^0.6.0;
import "./StandardToken.sol";

interface NewToken {
    function swapTokenWitholdToken(uint256 _amount, address _recvier)
        external
        returns (uint256);

    function burn(uint256 amount) external returns (bool);
}

abstract contract TokenSale is StandardToken {
    /**
     * @dev enum of current crowd sale state
     **/
    enum Stages {presale, saleStart, saleEnd}

    /**
     * @dev user get token when send 1 ether
     **/
    uint256 public basePrice = 1000;

    /**
     * @dev pattern follow for bonus like
     * 5 ETH >= 5% ,10 ETH >= 10%,20 ETH >= 15%,40 ETH >= 20%,80 ETH >= 25% and so on
     * Here pattern follow mulitply with 2 and increase in 5%
     **/
    uint256 public bonusStartFrom = 5 ether;

    /**
     * @dev divide by 100 to achive into fraction
     **/
    uint256 public bonusMultiplyer = 500;

    /**
     * @dev token sale currentStage
     **/
    Stages public currentStage = Stages.presale;

    event TokenSaleStarted(uint256 time);
    event TokenSaleEnded(uint256 time);
    event BasePriceChanged(uint256 oldPrice, uint256 _newPrice);

    /**
     * @dev to start token sale
     **/
    function startTokenSale() external onlyOwner() returns (bool) {
        require(currentStage == Stages.presale, "ERR_SALE_ALREADY_START");
        currentStage = Stages.saleStart;
        emit TokenSaleStarted(now);
        return true;
    }

    /**
     * @dev to end token sale
     **/
    function endTokenSale() external onlyOwner() returns (bool) {
        require(currentStage == Stages.saleStart, "ERR_SALE_IS_NOT_START");
        currentStage = Stages.saleEnd;
        emit TokenSaleEnded(now);
        return true;
    }

    /**
     * @dev modifier to check if sale is runnung
     **/
    modifier onlyWhenSaleIsOver() {
        require(currentStage == Stages.saleEnd, "ERR_SALE_IS_NOT_OVER");
        _;
    }

    /**
     * @dev modifier to check if sale is ended
     **/
    modifier onlyWhenSaleIsOn() {
        require(currentStage == Stages.saleStart, "ERR_SALE_IS_NOT_RUNNING");
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
    receive() external payable {
        buyToken();
    }
}

abstract contract Locking is TokenSale {
    mapping(address => uint256) public lockingPeriod;

    /**
     * @dev owner can lock any account for any amount of time
     * Requirements
     *
     * - `_whom` address which going to be locked
     * - `_period` epoch time until token get Locked
     */
    function setLokignPeriod(address _whom, uint256 _period)
        external
        onlyOwner()
        returns (bool)
    {
        lockingPeriod[_whom] = _period;
    }

    /**
     * @dev modifier for cheking if account is locked
     */
    modifier checkLocking(address _whom) {
        require(now >= lockingPeriod[_whom], "ERR_LOCKING_PERIOD_IS_NOT_ENDED");
        _;
    }
}

abstract contract Swapping is Locking {
    /**
     * @dev old contract address for swap
     **/
    address public _swapWithOld;

    /**
     * @dev new contract address if owner need to update
     **/
    address public _swapWithNew;

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

    /**
     * @dev Returns the bool on success
     * updating this token contacrt to new one
     * before updating cheking that updated contract is not malicious
     * so before updating cheking that this contract dont have any new token
     * after we convert 1 token and check if new contarct give back token or not
     */
    function updateContractToNewToken(address _newTokenAddress)
        external
        onlyOwner()
        notThisAddress(_newTokenAddress)
        returns (bool)
    {
        require(_swapWithNew == address(0), "ERR_NEW_TOKEN_ALREADY_SET");

        require(
            IERC20(_newTokenAddress).balanceOf(address(this)) == 0,
            "ERR_CONTRACT_TOKEN_UPDATE"
        );
        uint256 returnToken = NewToken(_newTokenAddress).swapTokenWitholdToken(
            1,
            address(this)
        );

        require(returnToken == 1, "ERR_NEW_TOKEN_UPDATE_NOT_WORKING");
        require(
            IERC20(_newTokenAddress).balanceOf(address(this)) == returnToken,
            "ERR_NEW_CONTACRT_IS_NOT_VALID"
        );
        _swapWithNew = _newTokenAddress;
        NewToken(_newTokenAddress).burn(returnToken);
        return true;
    }

    /**
     * @dev Returns the bool on success
     * convert token with new token
     * user can call this method to update with new token
     * This token is burned and replace with new one
     */
    function swapWithNewToken()
        external
        notZeroAddress(_swapWithNew)
        returns (bool)
    {
        uint256 _senderBalance = _balances[msg.sender];
        uint256 returnToken = NewToken(_swapWithNew).swapTokenWitholdToken(
            _senderBalance,
            address(this)
        );
        require(
            IERC20(_swapWithNew).balanceOf(msg.sender) >= returnToken,
            "ERR_NEW_TOKEN_SWAP_ERROR"
        );
        _burn(msg.sender, _senderBalance);
        return true;
    }
}

abstract contract Paynodes is Swapping {
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
    uint8 public payNoderSlot = 10;

    /**
     * @dev minimum balance require for be in paynode
     **/
    uint256 public minimumBalance = 45000 ether;

    /**
     * @dev divide by 100 to achive into fraction
     * it is mulitply
     **/
    uint256 public extraMintForPayNodes = 5000;

    /**
     * @dev adding account in paynode
     **/
    function addaccountToPayNode(address _whom)
        external
        onlyOwner()
        returns (bool)
    {
        require(payNoderSlot <= payNoders.length, "ERR_PAYNODE_LIST_FULL");
        require(
            _balances[_whom] >= minimumBalance,
            "ERR_PAYNODE_MINIMUM_BALANCE"
        );
        require(isPayNoder[_whom] == false, "ERR_ALREADY_IN_PAYNODE_LIST");
        isPayNoder[_whom] = true;
        payNoderIndex[_whom] = payNoders.length;
        payNoders.push(_whom);
        return true;
    }

    /**
     * @dev remove account from paynode
     **/
    function _removeaccountToPayNode(address _whom) internal returns (bool) {
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
    function setMinimumBalanceForPayNoder(uint256 _minimumBalance)
        external
        onlyOwner()
        returns (bool)
    {
        minimumBalance = _minimumBalance;
        return true;
    }

    /**
     * @dev owner can chane extra mint percent for paynoder
     * _extraMintForPayNodes is set in percent with mulitply 100
     * if owner want to set 1.25% then value is 125
     **/
    function setExtraMintingForNodes(uint256 _extraMintForPayNodes)
        external
        onlyOwner()
        returns (bool)
    {
        extraMintForPayNodes = _extraMintForPayNodes;
        return true;
    }
}

abstract contract Stacking is Paynodes {
    /**
     * @dev stack timer
     **/
    uint256 public stackClaimWindow = 86400;

    /**
     * @dev stack current time when current stack is end
     **/
    uint256 public currentStackPeriod = 0;

    /**
     * @dev stack current id
     **/
    uint256 public currentStackId = 0;

    /**
     * @dev mint percent annualy on balance
     * value is mulitply of 100
     **/
    uint256 public annualMintPercentage = 1000;

    /**
     * @dev record each stacking start time
     **/
    mapping(uint256 => uint256) public stackStartTiming;

    /**
     * @dev record each user last stack claimed time
     **/
    mapping(address => uint256) public lastStackClaimed;

    /**
     * @dev stackign started each month by owner
     **/
    function startStacking() external onlyOwner() returns (uint256) {
        require(now > currentStackPeriod, "LAST_STACK_IS_NOT_FINISHED");
        currentStackId = safeAdd(currentStackId, 1);
        currentStackPeriod = safeAdd(now, stackClaimWindow);
        stackStartTiming[currentStackId] = now;
        return currentStackId;
    }

    function _claimStack(address _whom) internal returns (bool) {
        require(
            stackStartTiming[currentStackId] > lastStackClaimed[_whom],
            "ERR_STACK_ALREADY_CLAIMED"
        );

        require(currentStackPeriod >= now, "ERR_STACK_CLAIM_WINDOW_OVER");

        uint256 userBalance = _balances[_whom];
        uint256 stackAmount = safeDiv(
            safeMul(userBalance, annualMintPercentage),
            120000
        );

        if (isPayNoder[_whom]) {
            if (userBalance >= minimumBalance) {
                stackAmount = safeDiv(
                    safeMul(stackAmount, extraMintForPayNodes),
                    10000
                );
            } else if (userBalance < minimumBalance) {
                _removeaccountToPayNode(_whom);
            }
        }

        if (currentStackPeriod > lockingPeriod[_whom]) {
            lockingPeriod[_whom] = currentStackPeriod;
        }

        lastStackClaimed[_whom] = now;
        _mint(_whom, stackAmount);
        return true;
    }

    /**
     * @dev user can claim own stack
     **/
    function claimStack() external returns (bool) {
        return _claimStack(msg.sender);
    }

    /**
     * @dev owner can distrubute the stack
     **/
    function claimStack(address[] calldata _whom)
        external
        onlyOwner()
        returns (bool)
    {
        uint256 currentStackStartTime = stackStartTiming[currentStackId];
        for (uint8 i = 0; i < _whom.length; i++) {
            if (currentStackStartTime > lastStackClaimed[_whom[i]])
                _claimStack(_whom[i]);
        }
        return true;
    }
}

/**
 * @title PayToken
 * @dev Contract to create the PaytToken
 **/
contract PaytToken is Stacking {
    uint256 public teamTokens;
    uint256 public marketingTokens;
    mapping(uint8 => uint256) public teamTokenUnlockDate;
    mapping(uint8 => uint256) public teamTokenUnlockAmount;
    mapping(uint8 => bool) public teamTokenUnlocked;
    uint256 teamTokenUnlockLength;

    constructor(
        address oldTokenAddress,
        uint256 _premintToken,
        uint256 _teamToken,
        uint256 _marketingToken,
        uint256[] memory _unlockDate,
        uint256[] memory _unlockAmount
    ) public {
        _swapWithOld = oldTokenAddress;
        teamTokens = _teamToken;
        marketingTokens = _marketingToken;
        _mint(owner, _premintToken);
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
        require(
            now > teamTokenUnlockDate[_unlockId],
            "ERR_UNLOCK_DATE_IS_NOT_PASSED"
        );
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
            if (values[i] > marketingTokens) {
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
    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        onlyWhenSaleIsOver()
        returns (bool)
    {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override onlyWhenSaleIsOver() returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            safeSub(_allowances[sender][msg.sender], amount)
        );
        return true;
    }
}
