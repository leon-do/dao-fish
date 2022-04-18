// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/governance/IGovernor.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MyToken is ERC20, Ownable, ERC20Permit, ERC20Votes, ReentrancyGuard {
    // governor contract
    address private governorAddress;

    // Amount of tokens users can take from
    uint256 private pool  = 123;

    // Fixed rate of growth for pool ie: 101%
    uint256 immutable public poolRate = 101;

    // Fixed reward for breeding
    uint immutable public breedReward = 123;

    // State of latest proposal
    struct Proposal {
        uint256 id;
        uint256 amt;
        uint256 min;
        uint256 exp;
        bool    sex;
    }
    Proposal private proposal;

    // State of the user
    struct User {
        bool    ban;
        uint256 nap;
    }
    mapping (address => User) private user;

    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        _mint(msg.sender, 100 * 10 ** decimals());
    }

    // Set governor contract on deploy
    function setGovernorAddress(address _governorAddress) public onlyOwner {
        require(governorAddress == 0x0000000000000000000000000000000000000000, "Governor address has been set");
        governorAddress = _governorAddress;
    }

    // Governor executes proposal
    function setProposal(uint256 proposalId, uint256 claimAmount, uint256 minBalance, uint256 expiration) public onlyOwner {
        require(block.number < proposal.exp, "Current proposal still active");
        require(claimAmount < pool, "Proposed amount exceeds pool amount");
        proposal = Proposal(proposalId, claimAmount, minBalance, expiration, true);
    }

    // Voters can claim tokens
    function claim() public nonReentrant {
        require(pool > 0 , "Pool is empty. Please restock");
        require(user[msg.sender].ban == false, "You are banned from claiming");
        require(user[msg.sender].nap > block.number, "Claiming too early");
        require(balanceOf(msg.sender) > proposal.min, "Must have a minimum balance to claim");
        IGovernor governor = IGovernor(governorAddress);
        require(governor.hasVoted(proposal.id, msg.sender), "Only voters can claim");
        // user must wait till next proposal to claim
        user[msg.sender].nap = proposal.exp;
        // subtract from pool
        pool = pool - proposal.amt;
        // transfer to user
        transferFrom(address(this), msg.sender, proposal.amt);
    }

    // Transfer tokens back to pool
    function restock(uint256 _value) public nonReentrant {
        transferFrom(msg.sender, address(this), _value);
        pool = pool + _value;
    }

    // Call to increase pool size + recieve reward
    function breed() public nonReentrant {
        require(proposal.sex == true, "Has already bred");
        proposal.sex = false;
        pool = pool * poolRate;
        // pool = pool + (pool * poolRate)
        uint256 babies = SafeMath.mul(pool, poolRate);
        pool = SafeMath.add(pool, babies);
        // reward user for breeding
        transferFrom(msg.sender, address(this), breedReward);
    }

    // Getters
    function getGovernorAddress() public view returns(address) {
        return governorAddress;
    }
    function getPool() public view returns(uint256) {
        return pool;
    }
    function getProposalId() public view returns(uint256) {
        return proposal.id;
    }
    function getProposalAmt() public view returns(uint256) {
        return proposal.amt;
    }
    function getProposalMin() public view returns (uint256) {
        return proposal.min;
    }
    function getProposalExp() public view returns(uint256) {
        return proposal.exp;
    }
    function getUserBan(address _address) public view returns (bool) {
        return user[_address].ban;
    }
    function getUserNap(address _address) public view returns (uint256) {
        return user[_address].nap;
    }



    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
