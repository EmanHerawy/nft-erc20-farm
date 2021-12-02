# startfi nft farm 
the farm where users can stake nft tokens in pre-setup pools and in return get erc20 tokens as rewards 

## How it works ?
### setup 
- contract is deployed with specifying when it would start, when it should end and when the owner can release stuck reward tokens in case of the farm couldn't reach the target users 
- owner add nft pool 
- owner add  reward tokens 
- if the farm target couldn't be reached, the owner can release the reward token as long as no minted points more or equal the required points to get this reward

### user activities 
- user can stake before farm's launch time 
- user can unstake before the launch time if they no longer want to be participating in the farm by calling unstakeEarly 
- once the fram started , user can NOT unstake , they have to wait til the end time
- either while the farm is running or after the end, the users can redeem , claim a reward or do both in a single transaction via redeemAndClaim.
- redeeming means minting Rstfi token as points 
- claiming means getting a certain amount of a token reward by burning RSTFI
- Once the farm ends, users can unstake their tokens. unstake will check if users haven't redeemed all their tokens and redeem them if so    