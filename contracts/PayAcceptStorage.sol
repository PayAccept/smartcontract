// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract PayAcceptStorage {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal constant _name = "PayAccept Token";
    string internal constant _symbol = "PAYT";
    uint8 internal constant _decimals = 18;
    uint256 internal constant _maxSupply = 45000000 ether;

    /**
     * @dev old contract address for swap
     **/
    address public oldTokenAddress;

    /**
     * @dev stack contract address for stack rewards
     **/
    address public mintingOwner;

    address public newMintingOwner;

    bool isSwapPaused;

    uint256 public teamTokens;
    uint256 public marketingTokens;
    mapping(uint8 => uint256) public teamTokenUnlockDate;
    mapping(uint8 => uint256) public teamTokenUnlockAmount;
    mapping(uint8 => bool) public teamTokenUnlocked;
    uint256 teamTokenUnlockLength;

    event TokenSaleStarted(uint256 time);
    event TokenSaleEnded(uint256 time);
    event BasePriceChanged(uint256 oldPrice, uint256 _newPrice);

    event MintingOwnershipTransfered(
        address indexed previousOwner,
        address indexed newOwner
    );
}
