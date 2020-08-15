var PaytToken = artifacts.require("PaytToken");



module.exports = function(deployer) {
    deployer.deploy(
       PaytToken,
      "0xD4A601Ad14185221E1841C35A95D4644785dc0D8", // old token address
      "19000000000000000000000000", // 19m total premint token for owner 
      "5000000000000000000000000", // 5m team token 
      "1000000000000000000000000", // 1m supply for airdrop
      ["1609459200","1622505600","1640995200"], // tema token unlock date 
      ["2000000000000000000000000","2000000000000000000000000","1000000000000000000000000"]
    );
};