// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {
    ERC721 public nftContract;

    uint256 public basePrice = 1 ether;
    uint256 public marketplaceCommission = 2; 

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(uint256 => Listing) public listings;

    event NFTListed(uint256 tokenId, address seller, uint256 price);
    event NFTSold(uint256 tokenId, address seller, address buyer, uint256 price);

    constructor(address _nftContract) {
        nftContract = ERC721(_nftContract);
    }

    function listNFT(uint256 tokenId, uint256 price) external {
        require(msg.sender == nftContract.ownerOf(tokenId), "You don't own this NFT");
        require(price >= basePrice, "Price is below the base price");
        listings[tokenId] = Listing(msg.sender, price);
        emit NFTListed(tokenId, msg.sender, price);
    }

    function buyNFT(uint256 tokenId) external payable {
        Listing storage listing = listings[tokenId];
        require(listing.seller != address(0), "NFT not listed for sale");
        require(msg.value >= listing.price, "Insufficient funds sent");
        address seller = listing.seller;
        uint256 price = listing.price;
        uint256 commission = (price * marketplaceCommission) / 100;
        payable(seller).transfer(price - commission);
        payable(owner()).transfer(commission);
        listings[tokenId] = Listing(address(0), 0);
        nftContract.safeTransferFrom(seller, msg.sender, tokenId);
        emit NFTSold(tokenId, seller, msg.sender, price);
    }
}
