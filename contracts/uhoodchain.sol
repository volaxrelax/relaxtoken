pragma solidity ^0.4.23

// ----------------------------------------------------------------------------
// Uhodchain Dapp
// 
// https://github.com/vincentshangjin/uhoodchain
// Based on Uhood.App Project https://github.com/bokkypoobah/Uhood
// 
// the Uhoodchain Dapp Project - 2018. The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// ClubToken Interface = ERC20 + symbol + location + decimals + mint + burn
// + approveAndCall
// ----------------------------------------------------------------------------
contract UhoodTokenInterface is ERC20Interface {
    function symbol() public view returns (string);
    function location() public view returns (string);
    function decimals() public view returns (uint8);
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success);
    function mint(address tokenOwner, uint tokens) public returns (bool success);
    function burn(address tokenOwner, uint tokens) public returns (bool success);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


// ----------------------------------------------------------------------------
// UhoodToken
// ----------------------------------------------------------------------------
contract UhoodToken is UhoodTokenInterface, Owned {
    using SafeMath for uint;

    string _symbol;
    string _location;
    uint8 _decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor(string symbol, string location, uint8 decimals) public {
        _symbol = symbol;
        _location = location;
        _decimals = decimals;
    }
    function symbol() public view returns (string) {
        return _symbol;
    }
    function location() public view returns (string) {
        return _location;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    function mint(address tokenOwner, uint tokens) public onlyOwner returns (bool success) {
        balances[tokenOwner] = balances[tokenOwner].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }
    function burn(address tokenOwner, uint tokens) public onlyOwner returns (bool success) {
        if (tokens > balances[tokenOwner]) {
            tokens = balances[tokenOwner];
        }
        _totalSupply = _totalSupply.sub(tokens);
        balances[tokenOwner] = 0;
        emit Transfer(tokenOwner, address(0), tokens);
        return true;
    }
    function () public payable {
        revert();
    }
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}


// ----------------------------------------------------------------------------
// Property Data Structure
// ----------------------------------------------------------------------------
library Properties {
    struct Property {
        address owner;
        bool exists;
        uint index;
        string location;
    }
    struct Data {
        bool initialised;
        mapping(address => Property) entries;
        address[] index;
    }

    event PropertyAdded(address indexed OwnerAddress, string location, uint totalAfter);
    event PropertyRemoved(address indexed OwnerAddress, string location, uint totalAfter);
    event PropertyLocationUpdated(address indexed OwnerAddress, string oldLocation, string newLocation);

    function init(Data storage self) public {
        require(!self.initialised);
        self.initialised = true;
    }
    function isProperty(Data storage self, address OwnerAddress) public view returns (bool) {
        return self.entries[OwnerAddress].exists;
    }
    function add(Data storage self, address OwnerAddress, string PropertyLocation) public {
        require(!self.entries[OwnerAddress].exists);
        self.index.push(OwnerAddress);
        self.entries[OwnerAddress] = Property(true, self.index.length - 1, PropertyLocation);
        emit PropertyAdded(OwnerAddress, PropertyLocation, self.index.length);
    }
    function remove(Data storage self, address OwnerAddress) public {
        require(self.entries[OwnerAddress].exists);
        uint removeIndex = self.entries[OwnerAddress].index;
        emit PropertyRemoved(OwnerAddress, self.entries[OwnerAddress].location, self.index.length - 1);
        uint lastIndex = self.index.length - 1;
        address lastIndexAddress = self.index[lastIndex];
        self.index[removeIndex] = lastIndexAddress;
        self.entries[lastIndexAddress].index = removeIndex;
        delete self.entries[OwnerAddress];
        if (self.index.length > 0) {
            self.index.length--;
        }
    }
    function setLocation(Data storage self, address OwnerAddress, string PropertyLocation) public {
        Property storage Property = self.entries[OwnerAddress];
        require(Property.exists);
        emit PropertyLocationUpdated(OwnerAddress, Property.location, PropertyLocation);
        Property.location = PropertyLocation;
    }
    function length(Data storage self) public view returns (uint) {
        return self.index.length;
    }
}

// ----------------------------------------------------------------------------
// Uhood
// ----------------------------------------------------------------------------
contract Uhood {
    using SafeMath for uint;
    using Properties for Properties.Data;
    // using Proposals for Proposals.Data;

    // string public name;

    UhoodTokenInterface public token;
    Properties.Data Properties;
    // Proposals.Data public proposals;
    bool public initialised;

    uint public tokensForNewProperties;

    uint public quorum = 80;
    uint public quorumDecayPerWeek = 10;
    uint public requiredMajority = 70;


    // Must be copied here to be added to the ABI
    event MemberAdded(address indexed memberAddress, string name, uint totalAfter);
    event MemberRemoved(address indexed memberAddress, string name, uint totalAfter);
    event MemberNameUpdated(address indexed memberAddress, string oldName, string newName);

    event NewProposal(uint indexed proposalId, Proposals.ProposalType indexed proposalType, address indexed proposer); 
    event Voted(uint indexed proposalId, address indexed voter, bool vote, uint votedYes, uint votedNo);
    event VoteResult(uint indexed proposalId, bool pass, uint votes, uint quorumPercent, uint PropertiesLength, uint yesPercent, uint requiredMajority);
    event TokenUpdated(address indexed oldToken, address indexed newToken);
    event TokensForNewPropertiesUpdated(uint oldTokens, uint newTokens);
    event EtherDeposited(address indexed sender, uint amount);
    event EtherTransferred(uint indexed proposalId, address indexed sender, address indexed recipient, uint amount);


    modifier onlyMember {
        require(Properties.isMember(msg.sender));
        _;
    }

    constructor(string clubName, address clubEthToken, uint _tokensForNewProperties) public {
        Properties.init();
        name = clubName;
        token = ClubEthTokenInterface(clubEthToken);
        tokensForNewProperties = _tokensForNewProperties;
    }
    function init(address memberAddress, string memberName) public {
        require(!initialised);
        initialised = true;
        Properties.add(memberAddress, memberName);
        token.mint(memberAddress, tokensForNewProperties);
    }
    function setMemberName(string memberName) public {
        Properties.setName(msg.sender, memberName);
    }
    function proposeAddMember(string memberName, address memberAddress) public onlyMember returns (uint proposalId) {
        proposalId = proposals.proposeAddMember(memberName, memberAddress);
        vote(proposalId, true);
    }
    function proposeRemoveMember(string description, address memberAddress) public onlyMember returns (uint proposalId) {
        proposalId = proposals.proposeRemoveMember(description, memberAddress);
        vote(proposalId, true);
    }
    function proposeMintTokens(string description, address tokenOwner, uint amount) public onlyMember returns (uint proposalId) {
        proposalId = proposals.proposeMintTokens(description, tokenOwner, amount);
        vote(proposalId, true);
    }
    function proposeBurnTokens(string description, address tokenOwner, uint amount) public onlyMember returns (uint proposalId) {
        proposalId = proposals.proposeBurnTokens(description, tokenOwner, amount);
        vote(proposalId, true);
    }
    function proposeEtherTransfer(string description, address recipient, uint amount) public onlyMember returns (uint proposalId) {
        proposalId = proposals.proposeEtherTransfer(description, recipient, amount);
        vote(proposalId, true);
    }
    function voteNo(uint proposalId) public onlyMember {
        vote(proposalId, false);
    }
    function voteYes(uint proposalId) public onlyMember {
        vote(proposalId, true);
    }
    function vote(uint proposalId, bool yesNo) internal {
        proposals.vote(proposalId, yesNo, Properties.length(), getQuorum(proposals.getInitiated(proposalId), now), requiredMajority);
        Proposals.ProposalType proposalType = proposals.getProposalType(proposalId);
        if (proposals.toExecute(proposalId)) {
            string memory description = proposals.getDescription(proposalId);
            address address1  = proposals.getAddress1(proposalId);
            uint amount = proposals.getAmount(proposalId);
            if (proposalType == Proposals.ProposalType.AddMember) {
                Properties.add(address1, description);
                token.mint(address1, tokensForNewProperties);
            } else if (proposalType == Proposals.ProposalType.RemoveMember) {
                Properties.remove(address1);
                token.burn(address1, uint(-1));
            } else if (proposalType == Proposals.ProposalType.MintTokens) {
                token.mint(address1, amount);
            } else if (proposalType == Proposals.ProposalType.BurnTokens) {
                token.burn(address1, amount);
            } else if (proposalType == Proposals.ProposalType.EtherTransfer) {
                address1.transfer(amount);
                emit EtherTransferred(proposalId, msg.sender, address1, amount);
            }
            proposals.close(proposalId);
        }
    }

    function getVotingStatus(uint proposalId) public view returns (bool, bool, uint, uint){
        return proposals.getVotingStatus(proposalId, Properties.length(), getQuorum(proposals.getInitiated(proposalId), now), requiredMajority);
    }


    /*
    function setToken(address clubToken) internal {
        emit TokenUpdated(address(token), clubToken);
        token = ClubTokenInterface(clubToken);
    }
    function setTokensForNewProperties(uint _tokensForNewProperties) internal {
        emit TokensForNewPropertiesUpdated(tokensForNewProperties, _tokensForNewProperties);
        tokensForNewProperties = _tokensForNewProperties;
    }
    function addMember(address memberAddress, string memberName) internal {
        Properties.add(memberAddress, memberName);
        token.mint(memberAddress, tokensForNewProperties);
    }
    function removeMember(address memberAddress) internal {
        Properties.remove(memberAddress);
    }
    */

    function numberOfProperties() public view returns (uint) {
        return Properties.length();
    }
    function getProperties() public view returns (address[]) {
        return Properties.index;
    }
    function getMemberData(address memberAddress) public view returns (bool _exists, uint _index, string _name) {
        Properties.Member memory member = Properties.entries[memberAddress];
        return (member.exists, member.index, member.name);
    }
    function getMemberByIndex(uint _index) public view returns (address _member) {
        return Properties.index[_index];
    }

    function getQuorum(uint proposalTime, uint currentTime) public view returns (uint) {
        if (quorum > currentTime.sub(proposalTime).mul(quorumDecayPerWeek).div(1 weeks)) {
            return quorum.sub(currentTime.sub(proposalTime).mul(quorumDecayPerWeek).div(1 weeks));
        } else {
            return 0;
        }
    }
    function numberOfProposals() public view returns (uint) {
        return proposals.length();
    }
    function getProposal(uint proposalId) public view returns (uint _proposalType, address _proposer, string _description, address _address1, address _address2, uint _amount, uint _votedNo, uint _votedYes, uint _initiated, uint _closed) {
        Proposals.Proposal memory proposal = proposals.proposals[proposalId];
        _proposalType = uint(proposal.proposalType);
        _proposer = proposal.proposer;
        _description = proposal.description;
        _address1 = proposal.address1;
        _address2 = proposal.address2;
        _amount = proposal.amount;
        _votedNo = proposal.votedNo;
        _votedYes = proposal.votedYes;
        _initiated = proposal.initiated;
        _closed = proposal.closed;
    }
    function () public payable {
        emit EtherDeposited(msg.sender, msg.value);
    }
}


// ----------------------------------------------------------------------------
// ClubEth Factory
// ----------------------------------------------------------------------------
contract ClubEthFactory is Owned {

    mapping(address => bool) _verify;
    ClubEth[] public deployedClubs;
    ClubEthTokenInterface[] public deployedTokens;

    event ClubEthListing(address indexed clubAddress, string clubEthName,
        address indexed tokenAddress, string tokenSymbol, string tokenName, uint8 tokenDecimals,
        address indexed memberName, uint tokensForNewProperties);

    function verify(address addr) public view returns (bool valid) {
        valid = _verify[addr];
    }
    function deployClubEthContract(
        string clubName,
        string tokenSymbol,
        string tokenName,
        uint8 tokenDecimals,
        string memberName,
        uint tokensForNewProperties
    ) public returns (ClubEth club, ClubEthToken token) {
        token = new ClubEthToken(tokenSymbol, tokenName, tokenDecimals);
        _verify[address(token)] = true;
        deployedTokens.push(token);
        club = new ClubEth(clubName, address(token), tokensForNewProperties);
        token.transferOwnershipImmediately(address(club));
        club.init(msg.sender, memberName);
        _verify[address(club)] = true;
        deployedClubs.push(club);
        emit ClubEthListing(address(club), clubName, address(token), tokenSymbol, tokenName, tokenDecimals, msg.sender, tokensForNewProperties);
    }
    function numberOfDeployedClubs() public view returns (uint) {
        return deployedClubs.length;
    }
    function numberOfDeployedTokens() public view returns (uint) {
        return deployedTokens.length;
    }
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    function () public payable {
        revert();
    }
}