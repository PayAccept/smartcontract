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
                                                                        ["1565971900","1568650300","1571242300"], // team token unlock date 
                                                                        ["2000000000000000000000000","2000000000000000000000000","1000000000000000000000000"], {
            from: Owner,
        });
        this.testTokenOLD.transfer(account4,basicTokenAmount, {
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
            await this.paytToken.startTokenSale({ from: Owner });

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

            await web3.eth.sendTransaction({
                from: account4,
                to: this.paytToken.address,
                value: getWith18Decimals(1),
            });
            try{
                await this.paytToken.transfer(account5,getWith18Decimals(100),{ from: account4 });
            }catch(e){

            }
            
        })
        
        it("Before TokenSale Start Balance is Zero", async function () {
            expect(await this.paytToken.balanceOf(account1)).to.be.bignumber.equal(
                getWith18Decimals(0).toString()
            );
        });

        it("after TokenSale Start Balance is 1000", async function () {
            expect(await this.paytToken.balanceOf(account2)).to.be.bignumber.equal(
                getWith18Decimals(1000).toString()
            );
        });
        it("Cheking Bonus", async function () {
            expect(await this.paytToken.balanceOf(account3)).to.be.bignumber.equal(
                getWith18Decimals(11000).toString()
            );
        });

        it("Cheking Transfer During TokenSale", async function () {
            expect(await this.paytToken.balanceOf(account4)).to.be.bignumber.equal(
                getWith18Decimals(1000).toString()
            );
            expect(await this.paytToken.balanceOf(account5)).to.be.bignumber.equal(
                getWith18Decimals(0).toString()
            );
        });

        

    });

    describe("Token Swap", async function () {
        beforeEach(async function () {
            await this.testTokenOLD.approve(this.paytToken.address,basicTokenAmount.toString(),{ from: account4 })
            await this.paytToken.swapWithOldToken(basicTokenAmount.toString(),{ from: account4 });
        });
        it("Cheking Swap", async function () {
            expect(await this.paytToken.balanceOf(account4)).to.be.bignumber.equal(
                basicTokenAmount.toString()
            );
        });
    })

    describe("Cheking Airdrop", async function () {
        beforeEach(async function () {
          await this.paytToken.airDropTokens(["0x0000000000000000000000000000000000000001","0x0000000000000000000000000000000000000002"],[basicTokenAmount.toString(),basicTokenAmount.toString()],{ from: Owner }) 
        });
        it("Cheking Airdrop account Balance", async function () {
            expect(await this.paytToken.balanceOf("0x0000000000000000000000000000000000000001")).to.be.bignumber.equal(
                basicTokenAmount.toString()
            );
            expect(await this.paytToken.balanceOf("0x0000000000000000000000000000000000000002")).to.be.bignumber.equal(
                basicTokenAmount.toString()
            );
        });
    })

    describe("End Token Sale", async function () {
        beforeEach(async function () {
          await this.paytToken.startTokenSale({ from: Owner }) 
          await web3.eth.sendTransaction({
            from: account4,
            to: this.paytToken.address,
            value: getWith18Decimals(1),
          });
          await this.paytToken.endTokenSale({ from: Owner }) 
          await this.paytToken.transfer(account5,getWith18Decimals(1000),{ from: account4 });
        });
        it("Cheking Transfer After TokenSale End", async function () {
            expect(await this.paytToken.balanceOf(account5)).to.be.bignumber.equal(
                getWith18Decimals(1000).toString()
            );
            
            expect(await this.paytToken.balanceOf(account4)).to.be.bignumber.equal(
                getWith18Decimals(0).toString()
            );
        });
    })

    describe("Test Locking", async function () {
        beforeEach(async function () {
          await this.paytToken.startTokenSale({ from: Owner }) 
          await web3.eth.sendTransaction({
            from: account4,
            to: this.paytToken.address,
            value: getWith18Decimals(1),
          });
          await this.paytToken.endTokenSale({ from: Owner }) 
          await this.paytToken.setLokignPeriod(account4,"1600266713",{ from: Owner }) ;

          try{
            await this.paytToken.transfer(account5,getWith18Decimals(1000),{ from: account4 });
          }catch(e){}
          await this.paytToken.setLokignPeriod(account4,"0",{ from: Owner }) ;
          await this.paytToken.transfer(account6,getWith18Decimals(1000),{ from: account4 });
        });

        it("Cheking Transfer After Locking", async function () {
            expect(await this.paytToken.balanceOf(account5)).to.be.bignumber.equal(
                getWith18Decimals(0).toString()
            );
        });

        it("Cheking Transfer After Locking Time Over", async function () {
            expect(await this.paytToken.balanceOf(account6)).to.be.bignumber.equal(
                getWith18Decimals(1000).toString()
            );
        });
    })
    

    describe("Test Stacking & PayNodes", async function () {
       
        beforeEach(async function () {
          await this.paytToken.startTokenSale({ from: Owner }) 
          await web3.eth.sendTransaction({
            from: account4,
            to: this.paytToken.address,
            value: getWith18Decimals(1),
          });
          await web3.eth.sendTransaction({
            from: account6,
            to: this.paytToken.address,
            value: getWith18Decimals(45),
          });
          await this.paytToken.endTokenSale({ from: Owner }) 
          await this.paytToken.addaccountToPayNode(account6,{from: Owner}) 
          await this.paytToken.startStacking({ from: Owner })
          await this.paytToken.claimStack({ from: account4 }) 
          await this.paytToken.claimStack({ from: account6 }) 
 
          await web3.eth.sendTransaction({
            from: Owner,
            to: account6,
            value: getWith18Decimals(45),
          });
          
        });

        it("Cheking Claim Stack for Not a payNoder", async function () {
            expect(await this.paytToken.balanceOf(account4)).to.be.bignumber.equal(
                "1008333333333333333333"
            );
        });

        it("Cheking Claim Stack For PayNoder", async function () {
            expect(await this.paytToken.balanceOf(account6)).to.be.bignumber.equal(
                "54225000000000000000000"
            );
        });

       
    })

    describe("Test PayNodes For AutoMatic Remove", async function () {
        beforeEach(async function () {
          await this.paytToken.startTokenSale({ from: Owner }) 
          await web3.eth.sendTransaction({
            from: account4,
            to: this.paytToken.address,
            value: getWith18Decimals(1),
          });
          await web3.eth.sendTransaction({
            from: account6,
            to: this.paytToken.address,
            value: getWith18Decimals(45),
          });
          await this.paytToken.endTokenSale({ from: Owner }) 
          await this.paytToken.addaccountToPayNode(account6,{from: Owner}) 
          await this.paytToken.startStacking({ from: Owner })
          await this.paytToken.transfer(account4,await this.paytToken.balanceOf(account6),{ from: account6 }) 
          await this.paytToken.transfer(account6,getWith18Decimals(1000),{ from: account4 }) 
          await this.paytToken.claimStack({ from: account6 }) 
          
        });

        it("Cheking Claim Stack payNoder when balance is below limit", async function () {
            expect(await this.paytToken.balanceOf(account6)).to.be.bignumber.equal(
                "1008333333333333333333"
            );
        });   
    })
    describe("Team Token", async function () {
        
        beforeEach(async function () {
          await this.paytToken.startTokenSale({ from: Owner });
          await this.paytToken.endTokenSale({ from: Owner });
          await this.paytToken.transfer(account8,await this.paytToken.balanceOf(Owner),{ from: Owner });
          await this.paytToken.unlockTeamToken(0,{ from: Owner });
          await this.paytToken.unlockTeamToken(1,{ from: Owner });
          await this.paytToken.unlockTeamToken(2,{ from: Owner });
        });

        it("Team Token Unlocked", async function () {
            expect(await this.paytToken.balanceOf(Owner)).to.be.bignumber.equal(
                "5000000000000000000000000"
            );
        });   
    })
});