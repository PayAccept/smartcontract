pragma solidity ^0.6.0;
import "./StandardToken.sol";

interface NewToken {
    function swapTokenWitholdToken(uint256 _amount, address _recvier)
        external
        returns (uint256);

    function burn(uint256 amount) external returns (bool);
}

contract SwapToken is StandardToken {
    address public _swapWithOld;

    address public _swapWithNew;

    constructor(address oldTokenAddress) internal {
        _swapWithOld = oldTokenAddress;
    }

    /**
     * @dev Returns the bool on success
     * convert old token with this token
     * user have to give allowence to this contract
     * trasnfer address at 0x1 bcz of conditon in old contract
     * old contract dont have burn method
     */
    function swapWitholdToken(uint256 _amount) external returns (bool) {
        IERC20(_swapWithOld).transferFrom(msg.sender, address(1), _amount);
        return _mint(msg.sender, _amount);
    }

    /**
     * @dev Returns the bool on success
     * updating this token contacrt to new one
     * before updating cheking that updated contacrt is not malicious
     * so before updating cheking that this contacrt dont have any new token
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
        require(returnToken >= 1, "ERR_NEW_TOKEN_UPDATE");
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
        uint256 _senderBalance = balanceOf(msg.sender);
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

contract Crowdsale is SwapToken {
    /**
     * @dev enum of current crowd sale state
     **/
    enum Stages {presale, saleStart, saleEnd}

    Stages public currentStage;
    event BasePriceChanged(uint256 oldPrice, uint256 _newPrice);

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

    uint256 public patternMultiplyer = 2;

    /**
     * @dev divide by 100 to achive into fraction
     **/
    uint256 public bonusMultiplyer = 500;

    constructor(address oldTokenAddress) public SwapToken(oldTokenAddress) {
        currentStage = Stages.saleStart;
    }

    function buyToken() internal notZeroValue(msg.value) {
        require(currentStage == Stages.saleStart, "ERR_CROWD_SALE");
        uint256 _recivableToken = safeMul(msg.value, basePrice);

        if (msg.value >= bonusStartFrom) {
            uint256 bonusCount = 0;
            uint256 _tempCount = bonusStartFrom;

            while (msg.value >= _tempCount) {
                _tempCount = safeMul(_tempCount, patternMultiplyer);
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
        _mint(msg.sender, _recivableToken);
        owner.transfer(msg.value);
    }

    function changeBasePrice(uint256 _baasePrice)
        external
        onlyOwner()
        returns (bool ok)
    {
        emit BasePriceChanged(basePrice, _baasePrice);
        basePrice = _baasePrice;
        return true;
    }

    function changeBonusStartPoint(uint256 _bonusStartFrom)
        external
        onlyOwner()
        returns (bool ok)
    {
        bonusStartFrom = _bonusStartFrom;
        return true;
    }
}

/**
 * @title PayToken
 * @dev Contract to create the PaytToken
 **/
contract PaytToken is Crowdsale {
    uint256 public teamTokens;

    uint256 public marketingTokens;

    mapping(uint8 => uint256) public teamTokenUnlockDate;
    mapping(uint8 => uint256) public teamTokenUnlockAmount;
    mapping(uint8 => bool) public teamTokenUnlocked;

    uint256 teamTokenUnlockLength;

    constructor(
        address oldTokenAddress,
        uint256 _teamToken,
        uint256 _marketingToken,
        uint256[] memory _unlockDate,
        uint256[] memory _unlockAmount
    ) public Crowdsale(oldTokenAddress) {
        _mint(address(this), safeAdd(teamTokens, marketingTokens));
        teamTokens = _teamToken;
        marketingTokens = _marketingToken;
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
            _teamToken == _marketingToken,
            "ERR_UNLOCKING_AMOUNT_DONT_MATCH"
        );
    }

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

    receive() external payable {
        buyToken();
    }
}
