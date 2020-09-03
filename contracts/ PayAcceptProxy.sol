// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./proxy/IRegistry.sol";
import "./proxy/UpgradeabilityProxy.sol";

interface PayAcceptProxyInterFace {
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

/**
 * @title Registry
 * @dev This contract works as a registry of versions, it holds the implementations for the registered versions.
 */
contract PayAcceptRegistery is Ownable, IRegistry {
    // Mapping of versions to implementations of different functions
    mapping(uint256 => address) internal versions;

    uint256 public currentVersion;

    address payable public proxyAddress;

    
    
    constructor()
        public{}

    /**
     * @dev Registers a new version with its implementation address
     * @param version representing the version name of the new implementation to be registered
     * @param implementation representing the address of the new implementation to be registered
     */
    function addVersion(uint256 version, address implementation)
        public
        onlyOwner()
        override
        notZeroAddress(implementation)
    {
        require(
            versions[version] == address(0),
            "This version has implementation attached"
        );
        versions[version] = implementation;
        emit VersionAdded(version, implementation);
    }

    /**
     * @dev Tells the address of the implementation for a given version
     * @param version to query the implementation of
     * @return address of the implementation registered for the given version
     */
    function getVersion(uint256 version) public override view returns (address) {
        return versions[version];
    }

    /**
     * @dev Creates an upgradeable proxy
     * @param version representing the first version to be set for the proxy
     * @return address of the new proxy created
     */
    function createProxy(uint256 version,
        address _oldTokenAddress,
        uint256 _premintToken,
        uint256 _teamToken,
        uint256 _marketingToken,
        uint256[] memory _unlockDate,
        uint256[] memory _unlockAmount,
        address payable _ownerAccount) external onlyOwner() returns (address) {
        require(proxyAddress == address(0), "ERR_PROXY_ALREADY_CREATED");

        UpgradeabilityProxy proxy = new UpgradeabilityProxy(version);

        PayAcceptProxyInterFace(address(proxy)).initialize(
            _oldTokenAddress,
            _premintToken,
            _teamToken,
            _marketingToken,
            _unlockDate,
            _unlockAmount,
            _ownerAccount
        );

        currentVersion = version;
        proxyAddress = address(proxy);
        emit ProxyCreated(address(proxy));
        return address(proxy);
    }



    /**
     * @dev Upgrades the implementation to the requested version
     * @param version representing the version name of the new implementation to be set
     */

    function upgradeTo(uint256 version) public onlyOwner() returns (bool) {
        currentVersion = version;
        UpgradeabilityProxy(proxyAddress).upgradeTo(version);
        return true;
    }
}