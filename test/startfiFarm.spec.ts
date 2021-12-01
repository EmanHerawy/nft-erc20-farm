import chai, { expect } from 'chai'
import { Contract, constants, BigNumber } from 'ethers'
import { waffle } from 'hardhat'
const { solidity, deployContract, createFixtureLoader, provider } = waffle

import { tokenFixture } from './shared/fixtures'
import { expandTo18Decimals } from './shared/utilities'

import StartfiFarm from '../artifacts/contracts/StartfiFarm.sol/StartfiFarm.json'
const { AddressZero } = constants

chai.use(solidity)

let blockBefore: any
const dayInSec = 24 * 60 * 60
let launchTime: number // after 2 days from now
let deadline: number // after 5 days
let releaseTime: number // after 5 days
const vidalMax = 10
const nextMax = 30
const ragMax = 100
let startfiTokens: any = []
let startfiTokenIds: any = []
let nextTokens: any = []
let nextTokenIds: any = []
let ragTokens: any = []
let ragTokenIds: any = []
// const vidalMax = 2
// const nextMax = 3
// const ragMax = 10
function* generateSequence(start: number, end: number) {
  for (let i = start; i <= end; i++) {
    yield i
  }
}

describe('Startfi Farm', () => {
  const [wallet, other, user1, user2, user3] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet, other, user1, user2, user3])

  let farm: Contract
  let startfiRewardToken: Contract
  let nexRewardToken: Contract
  let RAGRewardToken: Contract
  let testTokenPool: Contract
  let startFiNFTPool: Contract
  let nextNftPool: Contract
  let RagNftPool: Contract
  const startfiPoolDetails = {
    _token: '',
    _pointsPerTokenInSec: expandTo18Decimals(5),
    _cap: vidalMax,

    _totalShare: 20,
    _totalShareBase: 1,
  }
  const nextPoolDetails = {
    _token: '',
    _pointsPerTokenInSec: expandTo18Decimals(5),
    _cap: nextMax,
    _totalShare: 30,
    _totalShareBase: 1,
  }
  const ragPoolDetails = {
    _token: '',
    _pointsPerTokenInSec: expandTo18Decimals(10),
    _cap: ragMax,
    _totalShare: 30,
    _totalShareBase: 1,
  }
  const startfiRewardDetails = {
    amount: expandTo18Decimals(100),
    _priceInPoint: expandTo18Decimals(10),
    token: null,
    _owner: user1,
  }
  const nextRewardDetails = {
    amount: expandTo18Decimals(100),
    _priceInPoint: expandTo18Decimals(10),
    token: null,
    _owner: user1,
  }
  const ragRewardDetails = {
    amount: expandTo18Decimals(100),
    _priceInPoint: expandTo18Decimals(10),
    token: null,
    _owner: user1,
  }

  before(async () => {
    const fixture = await loadFixture(tokenFixture)
    RAGRewardToken = fixture.RAG
    testTokenPool = fixture.testToken
    startfiRewardToken = fixture.startfi
    nexRewardToken = fixture.NexType
    startFiNFTPool = fixture.VidalNFT
    nextNftPool = fixture.NextNFT
    RagNftPool = fixture.RAGNFT
    startfiPoolDetails._token = startFiNFTPool.address as any
    nextPoolDetails._token = nextNftPool.address as any
    ragPoolDetails._token = RagNftPool.address as any
    const blockNumBefore = await provider.getBlockNumber()
    blockBefore = await provider.getBlock(blockNumBefore)
    launchTime = blockBefore.timestamp + dayInSec * 2 // after 2 days from now
    deadline = launchTime + dayInSec * 30
    releaseTime = deadline + dayInSec * 50
    farm = await deployContract(wallet, StartfiFarm, [launchTime, deadline, releaseTime])
  
  })

  it('checking launch time and deadline ', async () => {
    expect(await farm.launchTime()).to.eq(launchTime)
    expect(await farm.farmDeadline()).to.eq(deadline)
  })

  it('Only owner can add pools to farm ', async () => {
    await expect(
      farm.connect(user1).addPool(
        startfiPoolDetails._token,
        startfiPoolDetails._pointsPerTokenInSec,

        startfiPoolDetails._cap,
        startfiPoolDetails._totalShare,
        startfiPoolDetails._totalShareBase
      )
    ).to.be.reverted
    await expect(
      farm.connect(wallet).addPool(
        startfiPoolDetails._token,
        startfiPoolDetails._pointsPerTokenInSec,

        startfiPoolDetails._cap,
        startfiPoolDetails._totalShare,
        startfiPoolDetails._totalShareBase
      )
    ).to.emit(farm, 'PoolAdded')
    await expect(
      farm.addPool(
        startfiPoolDetails._token,
        startfiPoolDetails._pointsPerTokenInSec,

        startfiPoolDetails._cap,
        startfiPoolDetails._totalShare,
        startfiPoolDetails._totalShareBase
      )
    ).to.be.revertedWith('Duplicated value is not allowed')
    await expect(
      farm.addPool(
        nextPoolDetails._token,
        nextPoolDetails._pointsPerTokenInSec,

        nextPoolDetails._cap,
        nextPoolDetails._totalShare,
        nextPoolDetails._totalShareBase
      )
    ).to.emit(farm, 'PoolAdded')
    await expect(
      farm.addPool(
        ragPoolDetails._token,
        ragPoolDetails._pointsPerTokenInSec,
        ragPoolDetails._cap,
        ragPoolDetails._totalShare,
        ragPoolDetails._totalShareBase
      )
    ).to.emit(farm, 'PoolAdded')
    await expect(
      farm.addPool(
        ragPoolDetails._token,
        ragPoolDetails._pointsPerTokenInSec,
        ragPoolDetails._cap,
        ragPoolDetails._totalShare,
        ragPoolDetails._totalShareBase
      )
    ).to.be.revertedWith('exceed cap')
    // expect(awai`t farm.farmDeadline()).to.eq(deadline);
  })

  it('Only owner can add reward tokens to farm ', async () => {
      await startfiRewardToken.connect(wallet).approve(farm.address, startfiRewardDetails.amount)
    await nexRewardToken.connect(wallet).approve(farm.address, nextRewardDetails.amount)
    await RAGRewardToken.connect(wallet).approve(farm.address, ragRewardDetails.amount)
    await expect(
      farm
        .connect(user1)
        .addTokenReward(
          startfiRewardDetails.amount,
          startfiRewardDetails._priceInPoint,
          startfiRewardToken.address,
          wallet.address
        )
    ).to.be.reverted

      await expect(
        farm
          .connect(wallet)
          .addTokenReward(
            startfiRewardDetails.amount,
            startfiRewardDetails._priceInPoint,
            startfiRewardToken.address,
            wallet.address
          )
      ).to.emit(farm, 'RewardAdded')
   
      await expect(
        farm.connect(wallet).addTokenReward(
          nextRewardDetails.amount,

          nextRewardDetails._priceInPoint,
          nexRewardToken.address,
          wallet.address
        )
      ).to.emit(farm, 'RewardAdded')

      await expect(
        farm
          .connect(wallet)
          .addTokenReward(
            ragRewardDetails.amount,
            ragRewardDetails._priceInPoint,
            RAGRewardToken.address,
            wallet.address
          )
      ).to.emit(farm, 'RewardAdded')
    

    const cap = startfiRewardDetails._priceInPoint
      .mul(startfiRewardDetails.amount)
      .add(
        nextRewardDetails._priceInPoint
          .mul(nextRewardDetails.amount)
          .add(ragRewardDetails._priceInPoint.mul(ragRewardDetails.amount))
      )
    console.log(cap.toHexString(), 'cap')

    expect(await farm.cap()).to.eq(cap)
  })
  it('user can stake or unstake before launch time ', async () => {
    await startFiNFTPool.connect(user1).setApprovalForAll(farm.address, true)
    await nextNftPool.connect(user2).setApprovalForAll(farm.address, true)
    await RagNftPool.connect(user3).setApprovalForAll(farm.address, true)

    //   const test =await  farm.connect(user1).stake(startfiPool.address, expandTo18Decimals (2000))
    // console.log(test);

    for (let index = 0; index < vidalMax; index++) {
      startfiTokens.push(startFiNFTPool.address)
      startfiTokenIds.push(index)
    }
    await expect(farm.connect(user1).stakeBatch(startfiTokens, startfiTokenIds)).to.emit(farm, 'Stake')

    for (let index = 0; index < nextMax; index++) {
      nextTokens.push(nextNftPool.address)
      nextTokenIds.push(index)
    }
    await expect(farm.connect(user2).stakeBatch(nextTokens, nextTokenIds)).to.emit(farm, 'Stake')

    for (let index = 0; index < ragMax; index++) {
      ragTokens.push(RagNftPool.address)
      ragTokenIds.push(index)
    }
    await expect(farm.connect(user3).stakeBatch(ragTokens, ragTokenIds)).to.emit(farm, 'Stake')
  })
  it('go in time and calculate points , user can not unstake ', async () => {
    await provider.send('evm_increaseTime', [launchTime - blockBefore.timestamp - 100])
    await provider.send('evm_mine', [])
    let blockNumBefore = await provider.getBlockNumber()
    blockBefore = await provider.getBlock(blockNumBefore)
    console.log(blockBefore.timestamp, launchTime, deadline, 'blockBefore.timestamp')
    if (blockBefore.timestamp <= launchTime) {
      expect(await farm.userRewards(other.address)).to.eq(BigNumber.from(0))
    }
    await provider.send('evm_increaseTime', [2 * dayInSec])
    await provider.send('evm_mine', [])
    blockNumBefore = await provider.getBlockNumber()
    blockBefore = await provider.getBlock(blockNumBefore)
    if (blockBefore.timestamp > launchTime) {
      expect(await farm.userRewards(user3.address)).to.not.eq(0)
    }
    const rewards = await await farm.userRewards(user3.address)
    console.log(rewards, 'rewardssssssss')

    console.log(blockBefore.timestamp, launchTime, deadline, 'blockBefore.timestamp')
    blockNumBefore = await provider.getBlockNumber()
    blockBefore = await provider.getBlock(blockNumBefore)
  
    await provider.send('evm_increaseTime', [1 * dayInSec])
    await provider.send('evm_mine', [])
    blockNumBefore = await provider.getBlockNumber()
    blockBefore = await provider.getBlock(blockNumBefore)
    if (blockBefore.timestamp > launchTime) {
      const user3Rewards = await farm.userRewards(user3.address)
      if (user3Rewards >= startfiRewardDetails._priceInPoint) {
        console.log({ user3Rewards })
      }
      await expect(
        farm.connect(user1).redeemBatch(startfiTokens, startfiTokenIds)
      ).to.emit(farm, 'Redeem')
      expect(await farm.connect(user3).redeem(ragTokens[0], ragTokenIds[0])).to.emit(farm, 'Redeem')
    }
    
  })

  it('go in time to the fram end time , user can unstake , unstakeBatch or claim regardless the time as long as balalnce is enough ', async () => {
    await provider.send('evm_increaseTime', [launchTime])
    await provider.send('evm_mine', [])

    const user1Reward = await farm.userRewards(user1.address)
    const user2Reward = await farm.userRewards(user2.address)
    const user3Reward = await farm.userRewards(user3.address)
     console.log({ user3Reward })
    console.log({ user2Reward })
    console.log({ user1Reward })
 
 
    await expect(
      farm
        .connect(user2)
        .redeemAndClaim(nextTokens, nextTokenIds,startfiRewardToken.address, 50)
    ).to.emit(farm, 'RewardClaimed')
 
    await expect(
      farm.connect(user2).unstakeBatch(nextTokens, nextTokenIds)
    ).to.emit(farm, 'Unstake')
    await expect(
      farm.connect(user1).unstakeBatch(startfiTokens, startfiTokenIds)
    ).to.emit(farm, 'Unstake')
    await expect(
      farm.connect(user3).unstakeBatch(ragTokens, ragTokenIds)
    ).to.emit(farm, 'Unstake')
    const user3Balance = await farm.balanceOf(user3.address)
    console.log({ user3Balance })
    const user1Balance = await farm.balanceOf(user1.address)
    console.log({ user1Balance })
    const total = await farm.totalSupply()
    console.log({ total })
    await expect(farm.connect(user1).claim(nexRewardToken.address,50)).to.emit(farm, 'RewardClaimed')
    await expect(farm.connect(user3).claim(RAGRewardToken.address,70)).to.emit(farm, 'RewardClaimed')
  })
})
