# uhoodchain
The official Github repo of Uhood Chain

# testing scenario
- [x] Deploy contract
- [x] Owner takes all 500M token (0.1 USD each)
- [x] Airdrop 1M
- [x] Exchange 499M
- [x] 1M airdrop to owner transfers 200 tokens each
- [x] Renter buys 10000 token from the exchange using ETH

## listing
- [x] Admin (invite only)
- [x] Property owner 1, 2 (200 each)
- [x] Renter 1, 2 (10000 each)
- [x] Owner 1 lists property, send 100 token to the uhood smart contract, eth address, next available date, property location (can't be updated), property type (appartment, townhouse, house), layout(bedroom count, toilet count, garage count)
- [x] Can get all the info
- [x] Onwer can update the next available date
- [x] Only owner can update the info
- [x] Owner and delist the property

## Application [Implement these in front end/ centralised database only, not block chain]
- [ ] Renter 1,2
- [ ] Owner 1
- [ ] Renter 1 starts application form, provide offer price, applicant information (number of applicant, name, licence no., DOB), employment information (current job title, current employer, annual salary, reference contact, previous job title, previous employer, previous annual salary), rental history information (current rental address, current agency, current agency contact,current rental price, reason to leave, previous rental address, previous agency, previous agency contact)
- [ ] Renter 1's application information (Avatar name 'renter 1', offer price, entry date) will be updated to the listing (visible to public)
- [ ] Renter 2 starts application form, provide offer price, applicant information
- [ ] Renter 2's application information (Avatar name 'renter 1', offer price, entry date) will be updated to the listing (visible to public)
- [ ] Owner 1 have 14 days to approve an application
- [ ] Renter 1(the application winner) receives a confirmation
- [ ] Renter 1 and 2 can withdraw applications before Owner 1 makes a decision

##  Rental agreement issuance and exchange - ERC809 (721 compatible) https://github.com/ethereum/EIPs/issues/809
- [ ] Build ERC 809 token to represent rental agreements. It contains: property hash (mapped to listed properties), start date, end date, agreed rent, bond, rent payment frequency, inspection frequency, sublease rights
- [ ] Only property owner can issue ERC 809 tokens.
- [ ] For each property, the associated ERC 809 tokens cannot have overlapping time periods.
- [ ] Token holders can transfer ERC 809 tokens to a new tenant who takes over the remaining term

## Resources
https://github.com/saurfang/erc809-billboard
https://github.com/ethereum/EIPs/issues/809
