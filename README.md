# uhoodchain
The official Github repo of RELAX token


# Testing scenario
- [x] Deploy smart contracts
- [x] Owner takes all 500M RELAX tokens (0.1 USD each)
- [x] Owner sends 20000 token to owner 1, 2 and renter 1, 2

## Listing
- [x] Owner 1 lists property 1 with property data, sending 100 token to the smart contract as a listing fee
- [x] Can get all the property info
- [x] Owner 2 lists property 2
- [x] Owner 2 transfers property 2 to owner 1
- [x] Owner 1 removes property 2
- [x] Owner 1 updates initial available date
- [x] Owner 1 updates other property data

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

##  Rental agreement issuance and exchange - ERC-1201 (ERC-721 compatible)
- [x] Represent property ownership as a standard ERC-721 non-fungible token, and also the first tier token within ERC-1201
- [ ] Represnet property rental rights as the second tier token
- [x] Renter 1 confirms the intention to rent the property and approves the smart contract to charge the bond amount
- [x] Owner 1 mints rental tokens to renter 1 and charges renter 1 the bond which is held by the smart contract
- [x] Renter 1 approves owner 2 (random person) to transfer the rental tokens
- [x] Owner 1 authorises renter 1 to transfer to preapproved addresses
- [x] Owner 1 adds renter 2 and owner 2 to preapproved addresses
- [x] Renter 2 confirms the intention to rent the property and approves the smart contract to charge the bond amount
- [x] Owner 2 transfers the rental tokens from renter 1 to renter 2
- [x] Renter 2 cancels the lease agreement (i.e. burns the rental tokens)

## Resources
https://github.com/ethereum/EIPs/issues/1201
https://github.com/ethereum/EIPs/issues/809
https://github.com/saurfang/erc809-billboard
