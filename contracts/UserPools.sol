// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
// import 'hardhat/console.sol';

import './FarmPools.sol';
import './lib/SafeDecimalMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

abstract contract UserPools is FarmPools {
    using SafeDecimalMath for uint256;

    struct userPool {
        address token;
        uint256 tokenId;
    }
    // user address to token address to stake details
    mapping(address => userPool[]) private userPools;
    // nft address to token id to user
    mapping(address => mapping(uint256 => address)) private _nftHolders;
    // mapping(address => mapping(address => uint256)) private _nftHolders;

    // nft address to token id to rewardBlock
    mapping(address => mapping(uint256 => uint256)) private _nftRewardBlock;

    event Stake(address indexed staker, address indexed pool, uint256 tokenId, uint256 timestamp);
    event Unstake(address indexed staker, address indexed pool, uint256 tokenId, uint256 timestamp);
    event Redeem(address indexed redeemer, address indexed pool, uint256 tokenId, uint256 timestamp);

    /// @notice calculate user rewards at the call time ( between launchtime to deadline) in all user pools
    /// @param user user address
    /// @return _totalRewards number of rewards
    function userRewards(address user) external view returns (uint256 _totalRewards) {
        uint256 currentBlock = _farmDeadline > block.timestamp ? block.timestamp : _farmDeadline;
        userPool [] storage _userPool = userPools[user];
        for (uint256 index = 0; index < _userPool.length; index++) {
            uint256 rewardBlock = _nftRewardBlock[_userPool[index].token][_userPool[index].tokenId];
            uint256 pointPerSec = _pools[_userPool[index].token].pointsPerTokenInSec;
            if (rewardBlock < currentBlock) {
                _totalRewards += _calcReward(pointPerSec, currentBlock - rewardBlock);
            }
        }
    }

    /// @notice calculate user rewards at the call time ( between launchtime to deadline) in a certain pool
    /// @param _token pool token address
    /// @param _tokenId nft id
    /// @return _totalRewards number of rewards
    function userPoolReward(address _token, uint256 _tokenId) external view returns (uint256 _totalRewards) {
        uint256 currentBlock = _farmDeadline > block.timestamp ? block.timestamp : _farmDeadline;
        uint256 rewardBlock = _nftRewardBlock[_token][_tokenId];
        uint256 pointPerSec = _pools[_token].pointsPerTokenInSec;
        if (rewardBlock < currentBlock) {
            _totalRewards = _calcReward(pointPerSec, currentBlock - rewardBlock);
        }
    }

    function _calcReward(uint256 pointPerSec, uint256 rewardBlocks) public pure returns (uint256) {
        return pointPerSec * rewardBlocks;
    }

    function _nftPoolDetails(address _token, uint256 _tokenId)
        internal
        view
        returns (
            address user,
            uint256 lastrewardBlock,
            uint256 pointPerSec
        )
    {
        lastrewardBlock = _nftRewardBlock[_token][_tokenId];
        user = _nftHolders[_token][_tokenId];

        pointPerSec = _pools[_token].pointsPerTokenInSec;
    }

    function _getUserPools(address user) internal view returns (userPool[] memory) {
        return userPools[user];
    }

    function _stake(
        address _user,
        address _token,
        uint256 _tokenId
    ) internal canStake(_user, _token, _tokenId) returns (bool) {
        _pools[_token].totalSupply += 1;
        userPools[_user].push(userPool(_token, _tokenId));
        _nftHolders[_token][_tokenId] = _user;
        _nftRewardBlock[_token][_tokenId] = _launchTime;
        // emit event here
        emit Stake(_user, _token, _tokenId, block.timestamp);
        return _transferNFT(_token, _tokenId, _user, address(this));
    }

    function _unstake(
        address _user,
        address _token,
        uint256 _tokenId
    ) internal canUnstake returns (bool) {
        require(IERC721(_token).ownerOf(_tokenId) == address(this), 'contact does not own the nft');
        _redeemPoint(_user, _token, _tokenId);

        _nftHolders[_token][_tokenId] = address(0);

        emit Unstake(_user, _token, _tokenId, block.timestamp);

        return _transferNFT(_token, _tokenId, address(this), _user);
    }

    // grady function

    function _unstakeEarly(
        address _user,
        address _token,
        uint256 _tokenId
    ) internal canUnStakeEarly returns (bool) {
        require(_nftHolders[_token][_tokenId] == _user, 'Un Authorized');
        require(IERC721(_token).ownerOf(_tokenId) == address(this), 'contact does not own the nft');
        _nftHolders[_token][_tokenId] = address(0);
        emit Unstake(_user, _token, _tokenId, block.timestamp);

        return _transferNFT(_token, _tokenId, address(this), _user);
    }

    function _redeemPoint(
        address _user,
        address _token,
        uint256 _tokenId
    ) internal returns (bool redeemed) {
        require(_nftHolders[_token][_tokenId] == _user, 'Un Authorized');
        uint256 lastrewardBlock = _nftRewardBlock[_token][_tokenId];
        if (lastrewardBlock < _farmDeadline) {
            uint256 currentBlock = _farmDeadline > block.timestamp ? block.timestamp : _farmDeadline;
            uint256 pointPerSec = _pools[_token].pointsPerTokenInSec;
            uint256 userTotalRewards = _calcReward(pointPerSec, currentBlock - lastrewardBlock);

            if (userTotalRewards > 0) {
                _nftRewardBlock[_token][_tokenId] = block.timestamp;
                emit Redeem(_user, _token, userTotalRewards, block.timestamp);

                _mint(_user, userTotalRewards);
                redeemed = true;
            }

        }
    }
 
}
