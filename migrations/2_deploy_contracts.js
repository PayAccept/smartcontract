var PaytToken = artifacts.require("PaytToken");
var PayAcceptRegistery = artifacts.require("PayAcceptRegistery");

var ownerAccount = "0xEcF2659415FD22A46a83a1592558c63c00968C89";
module.exports = async function(deployer) {


    await deployer.deploy(PaytToken);

    await deployer.deploy(PayAcceptRegistery);

    PayAcceptRegisteryInstance = await PayAcceptRegistery.deployed();

    await PayAcceptRegisteryInstance.addVersion(1,PaytToken.address);

    await PayAcceptRegisteryInstance.createProxy(1,
      "0xD4A601Ad14185221E1841C35A95D4644785dc0D8", // old token address
      "19000000000000000000000000", // 19m total premint token for owner 
      "5000000000000000000000000", // 5m team token 
      "1000000000000000000000000", // 1m supply for airdrop
      ["1609459200","1622505600","1640995200"], // tema token unlock date 
      ["2000000000000000000000000","2000000000000000000000000","1000000000000000000000000"],//teamToken amount
      ownerAccount // owner account for paytToken
      );
    
    tokenAddress = await PayAcceptRegisteryInstance.proxyAddress();

    console.log("ProxyAddress :",tokenAddress);
};