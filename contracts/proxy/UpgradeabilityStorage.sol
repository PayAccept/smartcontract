// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './IRegistry.sol';
import './Proxy.sol';

/**
 * @title UpgradeabilityStorage
 * @dev This contract holds all the necessary state variables to support the upgrade functionality
 */
contract UpgradeabilityStorage is Proxy {
    // Versions registry
    IRegistry public registry;

    // Address of the current implementation
    address internal _implementation;

    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() public override view returns (address) {
        return _implementation;
    }
}