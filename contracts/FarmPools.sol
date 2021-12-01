// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './FarmTokens.sol';
import './lib/SafeDecimalMath.sol';

contract FarmPools is FarmTokens {
    using SafeDecimalMath for uint256;

    using EnumerableSet for EnumerableSet.AddressSet;
    uint256 internal immutable _timeToRelease;
    uint256 internal immutable _farmDeadline;
    uint256 internal immutable _launchTime;
    uint256 private _RstfiMaxSupply;
    uint256 private totalShares;

    struct poolDetails {
        uint256 pointsPerTokenInSec;
        // how many nfts this pool can hold
        uint256 cap;
        // how many nfts supplied to this pool
        uint256 totalSupply;
        //pool total share  of RSTFI in the whole farm
        uint256 totalShare;
        uint256 totalShareBase;
    }
    EnumerableSet.AddressSet private _poolsSet;
    // token address to token details
    mapping(address => poolDetails) internal _pools;
    event PoolAdded(address token, uint256 pointsPerTokenInSec, uint256 cap, uint256 totalShare, uint256 totalShareBase);
    // modifiers

    modifier canStake(
        address _user,
        address _token,
        uint256 _tokenId
    ) {
        require(block.timestamp < _launchTime, 'Staking is locked');
        require(_poolsSet.contains(_token), 'non existe pool');
        require(_pools[_token].cap > _pools[_token].totalSupply, 'cap exceeded');
        require(
            IERC721(_token).getApproved(_tokenId) == address(this) ||
                IERC721(_token).isApprovedForAll(_user, address(this)),
            'Not approved'
        );
        _;
    }
    modifier canUnStakeEarly() {
        require(_launchTime > block.timestamp, 'Staking is locked');
        _;
    }
    modifier canUnstake() {
        require(block.timestamp > _farmDeadline, 'Staking is locked');
        _;
    }

    constructor(
        uint256 launchTime_,
        uint256 deadline_,
        uint256 timeToRelease_
    ) {
        require(deadline_ > launchTime_, 'Launch time should be less then deadline');
        require(timeToRelease_ > deadline_, 'deadline should be less then release time');
        _farmDeadline = deadline_;
        _launchTime = launchTime_;
        _timeToRelease = timeToRelease_;
    }

    function farmDeadline() external view returns (uint256) {
        return _farmDeadline;
    }

    function launchTime() external view returns (uint256) {
        return _launchTime;
    }

    /// @notice Only Owner can call it

    function _addPool(
        address _token,
        uint256 _pointsPerTokenInSec,
        uint256 cap_,
        uint256 _totalShare,
        uint256 _totalShareBase
    ) internal onlyOwner {
        totalShares = totalShares + (_totalShare.divideDecimal(_totalShareBase));
        // every toen should have a share of the total rstfi and the math for APR and amount token staked should match that share so that the APR doesn't exceed it
        require(totalShares / 1 ether <= 100, 'exceed cap');
        require(
            _pointsPerTokenInSec != 0 && cap_ != 0 && _totalShare != 0 && _totalShareBase != 0 && _token != address(0),
            'Zero values not allowed'
        );
        require(!_poolsSet.contains(_token), 'Duplicated value is not allowed');
        _poolsSet.add(_token);
        _pools[_token] = poolDetails(_pointsPerTokenInSec, cap_, 0, _totalShare, _totalShareBase);
        emit PoolAdded(_token, _pointsPerTokenInSec, cap_, _totalShare, _totalShareBase);
    }

    function getPoolByIndex(uint256 index) external view returns (address poolAddress) {
        return _poolsSet.at(index);
    }

    function getPoolDetails(address _token)
        external
        view
        returns (
            uint256 _pointsPerTokenInSec,
            uint256 cap_,
            uint256 totalSupply_,
            uint256 _totalShare,
            uint256 _totalShareBase
        )
    {
        _pointsPerTokenInSec = _pools[_token].pointsPerTokenInSec;
        cap_ = _pools[_token].cap;
        totalSupply_ = _pools[_token].totalSupply;
        _totalShare = _pools[_token].totalShare;
        _totalShareBase = _pools[_token].totalShareBase;
    }

 

    function getPools() external view returns (address[] memory poolAddreses) {
        return _poolsSet.values();
    }
       function _transferNFT(
        address _nftAddress,
        uint256 tokenId,
        address from,
        address to
    ) internal nonReentrant returns (bool) {
        IERC721(_nftAddress).safeTransferFrom(from, to, tokenId);
        return true;
    }
}
