const {
    constants,
    expectEvent,
    expectRevert,
    balance,
    time,
    BN,
  } = require("@openzeppelin/test-helpers");
  
  const { ZERO_ADDRESS } = constants;

const { expect } = require("chai");
const { forEach } = require("lodash");

var PaytToken = artifacts.require("PaytToken");
var ERC20Basic = artifacts.require("ERC20Basic");



const advanceTime = (time) => {
    return new Promise((resolve, reject) => {
      web3.currentProvider.send(
        {
          jsonrpc: "2.0",
          method: "evm_increaseTime",
          params: [time],
          id: new Date().getTime(),
        },
        (err, result) => {
          if (err) {
            return reject(err);
          }
          return resolve(result);
        }
      );
    });
  };


const denominator = new BN(10).pow(new BN(18));

const getWith18Decimals = function (amount) {
  return new BN(amount).mul(denominator);
};

var tokenName = "PayAccept Token" ;
var symbol = "PAYT";
var decimals = 18;
var maxSupply = getWith18Decimals(45000000);

contract("~PaytToken works", function (accounts) {
    const [,
      Owner,
      account1,
      account2,
      account3,
      account4, 
      account5, 
      account6,
      account7,
      account8,
    ] = accounts;

    var basicTokenAmount = getWith18Decimals(10000);

    beforeEach(async function () {

        this.testTokenOLD = await ERC20Basic.new(basicTokenAmount, {
          from: Owner,
        });

        this.paytToken = await PaytToken.new(this.testTokenOLD.address,"19000000000000000000000000", // 19m total premint token for owner 
                                                                        "5000000000000000000000000", // 5m team token 
                                                                        "1000000000000000000000000", // 1m supply for airdrop
                                                                        ["1609459200","1622505600","1640995200"], // tema token unlock date 
                                                                        ["2000000000000000000000000","2000000000000000000000000","1000000000000000000000000"], {
            from: Owner,
        });
    });
   
    describe("System should be initialized correctly", async function () {
       
        it("has a name", async function () {
            expect(await this.paytToken.symbol()).to.equal(symbol);
        });

        it("has a symbol", async function () {
            expect(await this.paytToken.symbol()).to.equal(symbol);
        });

    });

    describe("Before Tokensale Start", async function () {
        
        beforeEach(async function () {

            try{
                await web3.eth.sendTransaction({
                    from: account1,
                    to: this.paytToken.address,
                    value: getWith18Decimals(1),
                });
            }catch(e){

            }
            await this.paytToken.startTokenSale({ from: Owner })
            
;

            await web3.eth.sendTransaction({
                from: account2,
                to: this.paytToken.address,
                value: getWith18Decimals(1),
            });

            //sendign 10 ether for bonus check
            await web3.eth.sendTransaction({
                from: account3,
                to: this.paytToken.address,
                value: getWith18Decimals(10),
            });

            
        })
        
        it("Before TokenSale Start Balance Shold Be Zero", async function () {
            expect(await this.paytToken.balanceOf(account1)).to.be.bignumber.equal(
                getWith18Decimals(0).toString()
            );
        });

        it("after TokenSale Start Balance Shold Be 1000", async function () {
            expect(await this.paytToken.balanceOf(account2)).to.be.bignumber.equal(
                getWith18Decimals(1000).toString()
            );
        });

        it("Cheking Bonus", async function () {
            expect(await this.paytToken.balanceOf(account3)).to.be.bignumber.equal(
                getWith18Decimals(11000).toString()
            );
        });

    });

    describe("Token Swap", async function () {

    
    
    })
    

});