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

abstract contract Locking is StandardToken {
    mapping(address => uint256) public lockingPeriod;

    /**
     * @dev owner can lock any account for any amount of time
     * Requirements
     *
     * - `_whom` address which going to be locked
     * - `_period` epoch time until token get Locked
     */
    function setLockingPeriod(address _whom, uint256 _period)
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
     * @dev pause swap
     */
    function pauseSwap() external onlyOwner() returns (bool) {
        require(isSwapPaused == false, "ERR_SWAP_ALEREADY_PAUSED");
        isSwapPaused = true;
        return true;
    }

    /**
     * @dev unpause swap
     */
    function unPauseSwap() external onlyOwner() returns (bool) {
        require(isSwapPaused, "ERR_SWAP_ALEREADY_UNPAUSED");
        isSwapPaused = false;
        return true;
    }

    /**
     * @dev Returns the bool on success
     * convert old token with this token
     * user have to give allowence to this contract
     * trasnfer address at 0x1 bcz of conditon in old contract
     * old contract dont have burn method
     */
    function swapWithOldToken(uint256 _amount) external returns (bool) {
        require(isSwapPaused == false, "ERR_SWAP_IS_PAUSED");
        IERC20(oldTokenAddress).transferFrom(msg.sender, address(1), _amount);
        return _mint(msg.sender, _amount);
    }
}

abstract contract minter is Swapping {
    /**
     * @dev modifier onlyMinter
     */
    modifier onlyMinter() {
        require(msg.sender == mintingOwner, "ERR_ONLY_MINTING_OWNER_ALLOWED");
        _;
    }

    function _trasnferMintingOwnership(address _whom) internal {
        emit MintingOwnershipTransfered(mintingOwner, _whom);
        mintingOwner = _whom;
    }

    /**
     * @dev transfer minting ownership
     * first we have owner as minter then we transfer
     * onwership to stack contract
     */
    function transferMintingOwnerShip(address _whom)
        external
        onlyMinter()
        returns (bool)
    {
        newMintingOwner = _whom;
        return true;
    }

    /**
     * @dev accept minting ownership
     */
    function acceptMintingOwnerShip() external returns (bool) {
        require(msg.sender == newMintingOwner, "ERR_ONLY_NEW_MINTING_OWNER");
        _trasnferMintingOwnership(newMintingOwner);
        newMintingOwner = address(0);
        return true;
    }

    /**
     * @dev mint Token for stacking
     */
    function mintToken(uint256 _amount) external onlyMinter() returns (bool) {
        return _mint(msg.sender, _amount);
    }
}

/**
 * @title PayToken
 * @dev Contract to create the PaytToken
 **/
contract PaytToken is Upgradeable, minter, PayAcceptInterFace {
    function initialize(
        address _oldTokenAddress,
        uint256 _premintToken,
        uint256 _teamToken,
        uint256 _marketingToken,
        uint256[] memory _unlockDate,
        uint256[] memory _unlockAmount,
        address payable ownerAccount
    ) public override {
        super.initialize();

        oldTokenAddress = _oldTokenAddress;
        teamTokens = _teamToken;
        marketingTokens = _marketingToken;
        _trasnferOwnership(ownerAccount);
        _trasnferMintingOwnership(ownerAccount);
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
        isSwapPaused = false;
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
            teamTokenUnlockDate[_unlockId] < now,
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
            if (marketingTokens >= values[i]) {
                _transfer(address(this), recipients[i], values[i]);
                marketingTokens = safeSub(marketingTokens, values[i]);
            }
        }
        return true;
    }

    /**
     * @dev burn token from airdrop amount
     */
    function burnAirDropTokens(uint256 _amount)
        external
        onlyOwner()
        returns (bool)
    {
        require(marketingTokens >= _amount, "ERR_NOT_ENOUGH_TOKEN");
        return _burn(address(this), _amount);
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
        checkLocking(msg.sender)
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
    ) external virtual override checkLocking(sender) returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            safeSub(_allowances[sender][msg.sender], amount)
        );
        return true;
    }

    /**
     * @dev fallback is not accept any ether
     **/
    receive() external payable {
        revert();
    }
}
