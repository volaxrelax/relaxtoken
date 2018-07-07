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

    function mintRental(uint256 tokenId, uint256 start, uint256 end, address renter) external

The owner of the token `tokenId` mints rental tokens and assigns them to `renter`. The start and end time is divided by `minRentTime` to work out the `startIndex` and `endIndex`. The number of tokens minted is equal to `endIndex - startIndex + 1`.

The rental tokens are stored in a double mapping such as this:

    mapping(uint256 -> mapping(uint256 -> address)) rentals

The first uint256 stores the `tokenId`. The second uint256 represents the time slot index. Each time slot can be any duration set at by the smart contract constructor. For example, it can be an hour for a bike rental contract and a day for a property rental contract.

`startIndex` and `endIndex` refers to the second uint256 above.

### setRentalRights

    function setRenterRights(uint256 tokenId, address renter, bool canBurn, bool canTransferToAll, bool canTransferToPreapproved, bool canCopyAcrossRights) public

Sets the rights for the rental token owner, including the following:

- canBurn: whether or not the renter can burn the token, effecively cancelling the rental agreement
- canTransferToAll: whether or not the renter can transfer the rental token to anyone else
- canTransferToPreapproved: whether or not the renter can transfer the rental token to anyone within a list of preapproved renters
- canCopyAcrrossRights: whether or not the renter can copy across the same rights to the person receiving the rental tokens (as opposed to requiring the owner to manually set the rights for the new rental token owner)

### addPreapprovedRenters

    function addPreapprovedRenters(uint tokenId, address[] preapprovedList) public

Owner adds new addresses to the preapproved renters list.

The preApprovedRenters can be stored inside a double mapping such as this:

     mapping (uint => mapping (address => bool)) public preapprovedRenters;

### removePreapprovedRenters

    function addPreapprovedRenters(uint tokenId, address[] preapprovedList) public

Owner removes a list of addresses from the preapproved renters list.

### approveRentalTransfer

    function approveRentalTransfer(address approved, uint256 tokenId, uint256 start, uint256 end) public

Rental token holder approves `approved` (can be a market place smart contract) to transfer rental tokens within the time range `start` and `end` to a third party.

### transferRentalFrom
    function rentalTransferFrom(address from, address to, uint256 tokenId, uint256 start, uint256 end) public

Transfers rental tokens to a third party based on the rental token holder's current rights as set by `setRentalRights`.

The transfer can be done by the current rental token owner, or a market place smart contract which is approved by `approveRentalTransfer`. This function allows a secondary market to be built to trade the rental rights.

### cancelRental
    function cancelRental(address owner, uint256 tokenId, uint256 start, uint256 stop) public returns (bool success)

With the owner's approval (by setting `canBurn` to `true` for the renter), the rental token holder can cancel the rental agreement.

### rentalExists
    function exists(uint256 tokenId, uint256 timeIndex) public view returns (bool)

Check if a rental token exists at `timeIndex` for token `tokenId`.

### ownerOfRental
    function ownerOfRental(uint256 tokenId, uint256 time) public view returns (address)

Returns the owner of the rental token at `time` for token `tokenId`.

### balanceOfRental
    function balanceOfRental(address owner, uint256 tokenId, uint256 start, uint256 end) public view returns (uint256)

Returns the number of rental tokens owned by `owner` between the time `start` and `end`.

### balanceOfRentalApproval
    function balanceOfRentalApproval(address approved, uint256 tokenId, uint256 start, uint256 end) public view returns (uint256)

Returns the number of rental tokens that `approved` is approved to transfer between the time `start` and `end`.
