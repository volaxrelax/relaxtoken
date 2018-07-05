# Summary
---
A two tiered token standard for non-fungible assets which tokenises both ownership rights and rival rental rights.

# Purpose
---
This is an inspired by the [ERC-809 standard](https://github.com/ethereum/EIPs/issues/809) (Renting Standard for Rival, Non-Fungible Tokens), which is in turn an extension for the ERC-721 non-fungible token standard.

While the ERC-809 standard caters for rental rights, it does not tokenise them. This standard aims to tokenise such rental rights and thus allow the rental rights to be easily exchanged between different parties.

# Specification
---

## Tier 1 Token - Ownership Rights - ERC-721 compatible

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

## Tier 2 Token - Rental Rights

### mintRental

    function mintRental(uint256 tokenId, uint256 startIndex, uint256 stopIndex, address renter) external returns (bool success)

The owner of the token `tokenId` mints rental tokens and assigns them to `renter`. The number of tokens minted is equal to `stopIndex - startIndex + 1`.

`startIndex` and `stopIndex`

The rental tokens are stored in a double mapping such as

    mapping(uint256 -> mapping(uint256 -> address)) reservations
