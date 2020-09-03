// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./PayAcceptStorage.sol";

abstract contract StandardToken is IERC20,PayAcceptStorage,SafeMath, Ownable {
    
  
  
    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev Returns the token supply that minted max
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }


    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount)
        internal
        virtual
        notZeroAddress(account)
        notZeroValue(amount)
        returns (bool)
    {
        _totalSupply = safeAdd(_totalSupply, amount);
        require(_maxSupply >= _totalSupply,"ERR_MAX_TOKEN_SUPPLY_REACH");
        _balances[account] = safeAdd(_balances[account], amount);
        emit Transfer(address(0), account, amount);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount)
        internal
        virtual
        notThisAddress(account)
        notZeroAddress(account)
        notZeroValue(amount)
    {
        require(_balances[account] >= amount, ERR_NOT_ENOUGH_BALANCE);
        _balances[account] = safeSub(_balances[account], amount);
        _totalSupply = safeSub(_totalSupply, amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        virtual
        notThisAddress(recipient)
        notZeroAddress(recipient)
        returns (bool)
    {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, ERR_NOT_ENOUGH_BALANCE);
        _balances[sender] = safeSub(senderBalance, amount);
        _balances[recipient] = safeAdd(_balances[recipient], amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual notZeroAddress(owner) notZeroAddress(spender) {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    
    
    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, safeAdd(_allowances[spender][msg.sender],addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(_allowances[spender][msg.sender] >= subtractedValue,"");
        _approve(msg.sender, spender, safeSub(_allowances[spender][msg.sender],subtractedValue));
        return true;
    }
    
     
    
    function burn(uint256 amount)
        external
        virtual
        returns (bool) 
    {
        _burn(msg.sender,amount);
    }

    
}


