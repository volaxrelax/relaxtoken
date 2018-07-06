>ERC:
Title: Token standard
Author: Zeming Yu
Status: Draft
Type: ERC-1201
Created: 6 July 2018
Recommended implementation: TBA

# Summary
---
A two tiered token standard for non-fungible assets which tokenises both ownership rights and rival rental rights.

# Purpose
---
This is inspired by the [ERC-809 standard](https://github.com/ethereum/EIPs/issues/809) (Renting Standard for Rival, Non-Fungible Tokens), which is an extension for the ERC-721 non-fungible token standard.

While the ERC-809 standard caters for rental rights, it does not tokenise them. This standard aims to tokenise such rental rights and thus allow the rental rights to be easily exchanged between different parties.

# Specification
---

## Tier 1 Ownership Token - ERC-721 compatible

### balanceOf

    function balanceOf(address owner) external view returns (uint256);

### ownerOf

    function ownerOf(uint256 tokenId) external view returns (address);

### safeTransferFrom

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) external payable;

### safeTransferFrom

    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;

### transferFrom

    function transferFrom(address from, address to, uint256 tokenId) external payable;

### approve

    function approve(address approved, uint256 tokenId) external payable;

### setApprovalForAll

    function setApprovalForAll(address operator, bool approved) external;

### getApproved

    function getApproved(uint256 tokenId) external view returns (address);

### isApprovedForAll

    function isApprovedForAll(address owner, address operator) external view returns (bool);

## Tier 2 Rental Token

### mintRental

    function mintRental(uint256 tokenId, uint256 startIndex, uint256 stopIndex, address renter) external returns (bool success)

The owner of the token `tokenId` mints rental tokens and assigns them to `renter`. The number of tokens minted is equal to `stopIndex - startIndex + 1`.

The rental tokens are stored in a double mapping such as this:

    mapping(uint256 -> mapping(uint256 -> address)) rentals

The first uint256 stores the `tokenId`. The second uint256 represents the time slot index. Each time slot can be any duration set at by the smart contract constructor. For example, it can be an hour for a bike rental contract and a day for a property rental contract.

`startIndex` and `stopIndex` refers to the second uint256 above.

### approveRentalTransfer

    function approveRentalTransfer(address approved, uint256 tokenId, uint256 startIndex, uint256 stopIndex) external returns (bool success)

Approves `approved` (can be the current rental token owner, or a smart contract) to transfer rental tokens within the indices range `startIndex` and `stopIndex` to a third party.

### rentalTransferFrom
    function rentalTransferFrom(address from, address to, uint256 tokenId, uint256 startIndex, uint256 stopIndex) external returns (bool success)

Transfers rental rights to a third party. This can be done by the current rental token owner, or a market place smart contract.

This function allows a secondary market to be built to trade the rental rights (e.g. via auctions).

### burnRental
    function burnRental(address owner, uint256 tokenId, uint256 startIndex, uint256 stopIndex) external returns (bool success)

When certain conditions are not met (e.g. paying rent regularly, keeping the properties in a good condition), and when necessary, approved by an arbitration panel, the owner of the token can burn rental tokens within the indices range `startIndex` and `stopIndex`, effectively revoking the rental rights.

In another scenario, the current renter decides to move out early. Upon approval by the owner, the rental agreements are terminated early and the rental tokens are burnt.

### rentalExists
    function exists(uint256 tokenId, uint256 index) public view returns (bool)

Check if a rental token exists at `index` for token `tokenId`.

### ownerOfRental
    function ownerOfRental(uint256 tokenId, uint256 index) public view returns (address)

Returns the owner of the rental token within the indices range `startIndex` and `stopIndex` for token `tokenId`.

### balanceOfRental
    function balanceOfRental(address owner, uint256 tokenId) public view returns (uint256)

Returns the number of rental tokens owned by `owner`.