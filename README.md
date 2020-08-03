# PayAccept smart token contract

[![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)](https://travis-ci.org/joemccann/dillinger)

The smart contract of PayAccept

What does it need to do (besides of be an ERC20 compatible token):

1]	Tokensale
2]	Lock
3]	Swap
4]	Staking
5]	Extra staking: PayNodes (which is for top stakers with a big bag)
6] 	Airdrops

## Tokenomics

The initial supply of PayAccept (PAYT) will be 25M, these 25M are divided to:

-	5M for the team
-	5M for marketing (bounty, airdrops, etc...)
-	15M for Initial Coin Offerings (UniSwap, liquidity providing to exchanges etc....)

The total supply will be 45M tokens, which will be minted by stakers, or minted by the direct token-sale (since every new token can be bought or staked).

### 1] Tokensale

The tokensale is where investors can directly purchase tokens for a certain price (basePrice) this can be modified. For big traders they will get more tokens, an example:

Base price is 1 ETH = 1000 PAY

If they buy for 5 ETH, they got 5000 PAY (+5% bonus = 250 PAY)
If they buy for 10 ETH, they got 10000 PAY (+10% bonus = 1000 PAY)
If they buy for 20 ETH, they got 20000 PAY (+15% bonus = 3000 PAY)
If they buy for 40 ETH, they got 40000 PAY (+20% bonus = 8000 PAY)
If they buy for 80 ETH, they got 80000 PAY (+25% bonus = 20000 PAY)
and so on... (so some bonus if they buy extra, this is good for liquidity providers as well). Can be also on percentages, since there is a base price.

### 2] Lock
We have 2 types of lock. A lock till trading start and an address lock.
The team tokens (5M) needs to be released as follows:
2M on 1 jan 2021
2M on 1 jul 2021
1M on 1 jan 2022
Also there needs to be a lock where an account can be entered and a lock date, so for example 0x01 have a lock to transfer the tokens until 31 juli 2020.

The other lock is a general lock, since we are doing a tokensale, we want to enable the smart contract when trading starts (to transfer them to another address). This to prevent that people are start trading on Uniswap of other DEX’s, while the tokensale is up and running.


### 3] Swap

We run an old contact at 0x1Fe72034dA777ef22533eaa6Dd7cBE1D80bE50Fa. We are going to swap, since PAY as symbol is already taken by TenX. We don't want confusing, so we rebrand the symbol to PAYT. PAYT will be unique and listed as the symbol on exchange. Old tokenholders need to swap from PAY to PAYT. Where the old supply will be send to 0x0 or burned and they got PAYT in return, if they send PAY to the new contract. 

### 4] Staking

Holders of the PAY token get all an extra stake on top of their holdings, they payout is monthly. The stake is the minting of new tokens till the total supply is reached. So every month there need to be a snapshot of the tokenholders which are getting extra tokens on top of their amount. So if they hold 120 PAY, they mint every year 12 PAY on top, which is 1 PAY every month. 

>> Adjustable variable:	annualMintPercentage (default: 10%)


### 5] Paynodes

The concept for Paynodes is that we (the Owner of the contract) can assign some account holders as unique payholder (big holders that have at least 45000 PAY). With this they get some extra staking rewards on top of the normal rate (which is 8% annual). PayNode holders get x5 (so 50% rewards). The slots are maximized to 10, but can be adjusted in the future (if the demand raise). 

If the token amount in this account goes lower than 45000 PAY the account need to be kicked out from the Paynode account. 

Adjustable variable:	
>> extraMintForPayNodes (default: 5 (5 is the multiplier on top of the annualMintPercentage)
>> addaccountToPayNode (adds the account to become a PayNode). 
>> removeaccountToPayNode (removes the address from the contract).

### 6] Airdrop

We did an airdrop and reserved 1M of coins from the above 5M marketing tokens. These tokens needs to be distributed in a very easy way, with a low costs. If possible we prefer a batch, where a percentage is automatically send every week, till all is distributed.

Note:

>> Since the staking program will be on the website as well, we need to read all tokenholders >> (like Etherscan is doing). Also the contract needs to output the current paynode accounts, >> to list them on top!. 


### Installation

For testnet environments...

```sh
$ cd payaccept-smarttoken
$ truffle
```

For production environments...

```sh
$ cd payaccept-smarttoken
$ NODE_ENV=production node app
$ truffle
```

