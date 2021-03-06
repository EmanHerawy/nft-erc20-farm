// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import '@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol';

contract AnyERC721 is ERC721PresetMinterPauserAutoId {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721PresetMinterPauserAutoId(name, symbol, baseTokenURI) {}
}
