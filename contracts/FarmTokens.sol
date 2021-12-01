// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract FarmTokens is Ownable, ERC20, ERC721Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;
    uint256 private _cap;
    uint256 private _mintedPoints;
    uint256 private _tokenCount;
    struct tokenRewardDetails {
        uint256 priceInPoint;
        address owner;
     }
    // token address to details
    mapping(address => tokenRewardDetails) internal rewardTokens;

    event RewardReleased(address indexed owner, address indexed token, uint256 amount, uint256 timestamp);
    event RewardClaimed(address indexed claimer, address indexed token, uint256 amount, uint256 timestamp);
    event RewardAdded(
        address indexed owner,
        address indexed token,
         uint256 priceInPoint,
        uint256 timestamp
    );

    constructor() ERC20('Startfi Reward Token', 'RSTFI') {}

    function mintedPoints() external view returns (uint256) {
        return _mintedPoints;
    }

    function cap() external view returns (uint256) {
        return _cap;
    }

    function rewardCount() external view returns (uint256) {
        return _tokenCount;
    }

    /// @notice Only woner can call it

    function _addTokenReward(
        uint256 _amount,
        uint256 _priceInPoint,
        address _token,
        address owner_
     ) internal virtual onlyOwner {
        require(
            _priceInPoint != 0 && _amount != 0 && _token != address(0) && owner_ != address(0),
            'Zero values not allowed'
        );

        require(IERC20(_token).allowance(owner_, address(this)) >= _amount, 'Not approved');
        rewardTokens[_token] = tokenRewardDetails(_priceInPoint, owner_);
        _cap += _amount * _priceInPoint;
        emit RewardAdded(owner_, _token, _priceInPoint, block.timestamp);

        IERC20(_token).safeTransferFrom(owner_, address(this), _amount);
    }

    function _claimReward(
        address _token,
        address _user,
        uint256 _amount
    ) internal virtual {
        uint256 price = rewardTokens[_token].priceInPoint * _amount;
        require(balanceOf(_user) >= price, 'Insufficient fund');
        // burn decrease the total supply which might be vulnarabity when we try to enforce cap
        _burn(_user, price);

        require(IERC20(_token).balanceOf(address(this)) >= _amount, 'UnAuthorized');
        emit RewardClaimed(_user, _token, _amount, block.timestamp);
        // safetransfer
        IERC20(_token).safeTransfer(_user, _amount);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        // require(ERC20.totalSupply() + amount <= _cap, 'cap exceeded');
        require(_mintedPoints + amount <= _cap, 'Mint: cap exceeded');
        _mintedPoints += amount;
        super._mint(account, amount);
    }
}
