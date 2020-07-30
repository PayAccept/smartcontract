pragma solidity ^0.6.0;
import "./StandardToken.sol";

contract SwapToken is StandardToken {
    address public _swapWith;

    constructor(address oldTokenAddress) public {
        _swapWith = oldTokenAddress;
    }

    /**
     * @dev Returns the bool on success
     * convert old token with new convert
     * user have to give allowence to this contract
     * trasnfer address at 0x1 bcz of conditon in old contract
     * old contract dont have burn method
     */
    function swapToken(uint256 _amount) external returns (bool) {
        IERC20(_swapWith).transferFrom(msg.sender, address(1), _amount);
        return _mint(msg.sender, _amount);
    }

    function swapTokenWithNewToken() external returns (bool) {}
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

    receive() external payable {
        buyToken();
    }
}

/**
 * @title PayToken
 * @dev Contract to create the PaytToken
 **/
contract PaytToken is Crowdsale {
    uint256 public teamTokens = 5000000 ether;

    // uint256[] public
    uint256 public marketingTokens = 5000000 ether;

    constructor(address oldTokenAddress) public Crowdsale(oldTokenAddress) {
        _mint(address(this), safeAdd(teamTokens, marketingTokens));
    }

    function unlockTeamToken() external onlyOwner() returns (bool) {
        require(teamTokens > 0, "ERR_TEAM_BONUS_ZERO");

        if (now > 1609459200) {
            _transfer(address(this), owner, safeExponent(2000000, 18));
            teamTokens = safeSub(teamTokens, safeExponent(2000000, 18));
        }
        if (now > 1622505600) {
            _transfer(address(this), owner, safeExponent(2000000, 18));
            teamTokens = safeSub(teamTokens, safeExponent(2000000, 18));
        }
        if (now > 1640995200) {
            _transfer(address(this), owner, teamTokens);
            teamTokens = 0;
        }

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
}
