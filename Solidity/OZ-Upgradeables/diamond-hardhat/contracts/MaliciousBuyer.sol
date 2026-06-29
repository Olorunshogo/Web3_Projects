// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMarketplace {
    function buyNFT(address _nftAddress, uint256 _tokenId) external payable;
}

/// @notice Simulates a reentrancy attack on buyNFT for testing purposes.
contract MaliciousBuyer {
    IMarketplace public marketplace;
    address public nftAddress;
    uint256 public tokenId;
    bool public attacking;

    constructor(address _marketplace) {
        marketplace = IMarketplace(_marketplace);
    }

    function attack(address _nftAddress, uint256 _tokenId) external payable {
        nftAddress = _nftAddress;
        tokenId = _tokenId;
        attacking = true;
        marketplace.buyNFT{value: msg.value}(_nftAddress, _tokenId);
    }

    receive() external payable {
        if (attacking) {
            attacking = false;
            // Attempt reentrant call — should be blocked by nonReentrant
            marketplace.buyNFT{value: address(this).balance}(nftAddress, tokenId);
        }
    }
}
