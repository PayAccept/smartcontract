/*
 * NB: since truffle-hdwallet-provider 0.0.5 you must wrap HDWallet providers in a 
 * function when declaring them. Failure to do so will cause commands to hang. ex:
 * ```
 * mainnet: {
 *     provider: function() { 
 *       return new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/<infura-key>') 
 *     },
 *     network_id: '1',
 *     gas: 4500000,
 *     gasPrice: 10000000000,
 *   },
 */

var HDWalletProvider = require("truffle-hdwallet-provider");
const MNEMONIC = '0x3D62939FE6276F92600063C1FA71FBEFA647F4EA23F8BD72CB1D07964DF026FF';

module.exports = {
  compilers: {
    solc: {
      version: "0.4.26",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
 },
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(MNEMONIC,"https://ropsten.infura.io/v3/708ba26d4eab49ecad5d3b4dd2f4b347")
      },
      network_id: '3',
      gas: 8000000,
	    gasPrice: 41000000000,
	    timeoutBlocks: 200,
	    skipDryRun: true
    }
  }
};