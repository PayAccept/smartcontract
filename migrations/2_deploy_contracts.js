var PaytToken = artifacts.require("PaytToken");
var PayAcceptRegistery = artifacts.require("PayAcceptRegistery");

var ownerAccount = "0x4c185CDAA130bE6f8dad25737F9073eB497E6660"; // The deployer account

module.exports = async function(deployer) {


    await deployer.deploy(PaytToken);

    await deployer.deploy(PayAcceptRegistery);

    PayAcceptRegisteryInstance = await PayAcceptRegistery.deployed();

    await PayAcceptRegisteryInstance.addVersion(1,PaytToken.address);

    await PayAcceptRegisteryInstance.createProxy(1,
      "0x1fe72034da777ef22533eaa6dd7cbe1d80be50fa", // old token address
      "19000000000000000000000000", // 19m total premint token for owner
      "5000000000000000000000000", // 5m team token
      "1000000000000000000000000", // 1m supply for airdrop
      ["1609459200","1622505600","1640995200"], // teamToken unlock date
      ["2000000000000000000000000","2000000000000000000000000","1000000000000000000000000"],//teamToken amount
      ownerAccount // owner account for paytToken
      );

    tokenAddress = await PayAcceptRegisteryInstance.proxyAddress();

    console.log("ProxyAddress :",tokenAddress);
};
