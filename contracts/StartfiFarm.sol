// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import './UserPools.sol';

/// @title Startfi farm contract where users stake their tokens and get NFT as rewards

contract StartfiFarm is UserPools {
    constructor(
        uint256 launchTime_,
        uint256 deadline_,
        uint256 timeToRelease_
    ) FarmPools(launchTime_, deadline_, timeToRelease_) {}

    /// @param user user address
    ///  @return  currentUserPools user's pool addresses

    function getUserPools(address user) external view returns (userPool[] memory) {
        return _getUserPools(user);
    }

    /// @notice get pool details related to certain nft
    /// @param _token pool token address
    /// @param _tokenId nft id
    /// @return user staking this nft
    /// @return lastrewardBlock last redeeming time
    /// @return pointPerSec  amount of points in sec
    function nftPoolDetails(address _token, uint256 _tokenId)
        internal
        view
        returns (
            address user,
            uint256 lastrewardBlock,
            uint256 pointPerSec
        )
    {
        return _nftPoolDetails(_token, _tokenId);
    }

    // ony before launch time
    /// @notice let user to stake tokens in a certain pool
    /// @dev ony before launch time
    /// @param _token pool token address
    /// @param _tokenId nft id

    function stake(address _token, uint256 _tokenId) external {
        require(_stake(_msgSender(), _token, _tokenId), 'Invalid stake operation');
    }

    // ony before launch time
    /// @notice let user to stake in maltible pools in a single transaction
    /// @dev ony before launch time,
    /// @dev both function arguments length must be identical
    /// @param _tokens array of pool tokens address
    /// @param _tokenIds array of nft ids to be staked for each pool

    function stakeBatch(address[] calldata _tokens, uint256[] calldata _tokenIds) external {
        require(_tokens.length == _tokenIds.length, 'Mismatch array length');
        for (uint256 index = 0; index < _tokens.length; index++) {
            require(_stake(_msgSender(), _tokens[index], _tokenIds[index]), 'Invalid stake operation');
        }
    }

    /// @notice user can redeem token at any time as long as his balance of Rstfi >= the required price " points"
    // we should check if this token reward has conditions to apply
    /// @dev only staker can call it

    /// @param _token reward token address
    /// @param _amount required amount
    function claim(address _token, uint256 _amount) external {
_claimReward(_token, _msgSender(), _amount);    }

    /// @notice if user wants to claim a cetain amount of a token reward and the user's rewards balance of group of pools is more than or equal the required points for that nft, user can call this function rather than redeem -> claim scenario where user has to send many transaction to get the token
    /// @dev only staker can call it

    // /// @param _tokens array of pool tokens address
    // /// @param key nft id

    function redeemAndClaim(
        address[] calldata _tokens,
        uint256[] calldata _tokenIds,
        address _poolToken,
        uint256 _amount
    ) external {
        require(_tokens.length == _tokenIds.length, 'not equal arrays');
        for (uint256 index = 0; index < _tokens.length; index++) {
            require(_redeemPoint(_msgSender(), _tokens[index], _tokenIds[index]), 'Invalid redeem operation');
        }
        _claimReward(_poolToken, _msgSender(), _amount);
     }

    /// @notice Let user redeem token from many pools at once
    /// @dev only staker can call it

    /// @param _tokens array of pool tokens address

    function redeemBatch(address[] calldata _tokens, uint256[] calldata _tokenIds) external {
        require(_tokens.length == _tokenIds.length, 'not equal arrays');

        for (uint256 index = 0; index < _tokens.length; index++) {
            require(_redeemPoint(_msgSender(), _tokens[index], _tokenIds[index]), 'Invalid redeem operation');
        }
    }

    /// @notice users call this functions any time to redeem points for their pool stakes
    /// @dev : calling this function mints point for the caller based on the reward algorithm applied
    /// @dev only staker can call it

    /// @param _token pool token address
    /// @param _tokenId nft id
    function redeem(address _token, uint256 _tokenId) external {
        require(_redeemPoint(_msgSender(), _token, _tokenId), 'Invalid redeem operation');
    }

    //
    /// @notice When the fram ends, users can set their stakes free by calling this function
    /// @dev only after deadline
    /// @dev only staker can call it

    /// @param _token pool token address
    /// @param _tokenId nft id
    function unstake(address _token, uint256 _tokenId) external {
        require(_unstake(_msgSender(), _token, _tokenId), 'Invalid unstake operation');
    }

    /// @notice Let user unstake token from many pools at once
    /// @dev only staker can call it

    /// @param _tokens array of pool tokens address
    function unstakeBatch(address[] calldata _tokens, uint256[] calldata _tokenIds) external {
        require(_tokens.length == _tokenIds.length, 'not equal arrays');

        for (uint256 index = 0; index < _tokens.length; index++) {
            require(_unstake(_msgSender(), _tokens[index], _tokenIds[index]), 'Invalid unstake operation');
        }
    }

    /// @notice before the farm starts, users can set their stakes free by calling this function
    /// @dev only before launchtime
    /// @dev only staker can call it

    /// @param _token pool token address
    /// @param _tokenId nft id
    function unStakeEarly(address _token, uint256 _tokenId) external {
        require(_unstakeEarly(_msgSender(), _token, _tokenId), 'Invalid stake operation');
    }

    /// @notice before the farm starts, Let user unstake token from many pools at once
    /// @dev only before launchtime
    /// @dev only staker can call it
    /// @param _tokens array of pool tokens address
    function unStakeEarlyBatch(address[] calldata _tokens, uint256[] calldata _tokenIds) external {
        require(_tokens.length == _tokenIds.length, 'not equal arrays');
        for (uint256 index = 0; index < _tokens.length; index++) {
            require(_unstakeEarly(_msgSender(), _tokens[index], _tokenIds[index]), 'Invalid stake operation');
        }
    }

    /// @notice create new pool
    /// @dev only owner can call it
    /// @param _token erc721 token address
    /// @param _pointsPerTokenInSec amount of points to be generated in sec
    /// @param  cap_ the maxmum amount of tokens to be staked in this pool
    /// @param  _totalShare perenage numerator of pool share of the farm overall points
    /// @param  _totalShareBase perenage denominator of pool share of the farm overall points
    function addPool(
        address _token,
        uint256 _pointsPerTokenInSec,
        uint256 cap_,
        uint256 _totalShare,
        uint256 _totalShareBase
    ) external {
        _addPool(_token, _pointsPerTokenInSec, cap_, _totalShare, _totalShareBase);
    }

    /// @notice add the token rewards that users will claim
    /// @dev only owner can call it
    /// @dev nft point increase the RSFTI cap
    /// @param  _amount amount of token to be deposited
    /// @param  _priceInPoint how many point required to calim it
    /// @param  _token token contract address
    /// @param  owner_ the owner of this nft , this is used as well to return the nft back if no one calim it with no points left in the farm
 
    function addTokenReward(
        uint256 _amount,
        uint256 _priceInPoint,
        address _token,
        address owner_
     ) external {
        _addTokenReward(_amount, _priceInPoint, _token, owner_);
    }
  
    /// @notice to protect tokens from being locked in the contract , owner can call it after the time to release and return it back to the original owner as long as minted point is less than the reward `_priceInPoint`
    /// @dev only  owner can call it
    /// @dev called only after the `_timeToRelease`

    function releaseRewardToken(address _token) external {
        _releaseRewardToken(_token);
    }
}
