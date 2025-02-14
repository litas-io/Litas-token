// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Litas is ERC20, ReentrancyGuard {

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool claimed;
    }

    mapping(address => Stake[]) public stakes;

    event TokensBurned(address indexed burner, uint256 amount);
    event TokensStaked(address indexed staker, uint256 amount, uint256 duration, uint256 startTime);
    event TokensClaimed(address indexed staker, uint256 amount, uint256 stakeIndex);

    constructor(string memory name, string memory symbol, uint256 initialSupply, address initialOwner) ERC20(name, symbol) {
        _mint(initialOwner, initialSupply * 10**decimals());
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    function stake(uint256 amount, uint256 durationInDays) public nonReentrant {
        require(amount > 0, "Cannot stake 0 tokens");
        require(balanceOf(msg.sender) >= amount, "Insufficient token balance");

        // Transfer the tokens to the contract
        _transfer(msg.sender, address(this), amount);

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + (durationInDays * 1 days);

        // Record the stake
        stakes[msg.sender].push(Stake(amount, startTime, endTime, false));

        emit TokensStaked(msg.sender, amount, durationInDays, startTime);
    }

    function claimStakedTokens(uint256 stakeIndex) public nonReentrant {
        require(stakeIndex < stakes[msg.sender].length, "Invalid stake index");
        Stake storage stakeData = stakes[msg.sender][stakeIndex];
        require(!stakeData.claimed, "Stake already claimed");
        require(block.timestamp >= stakeData.endTime, "Stake is still locked");

        stakeData.claimed = true;
        _transfer(address(this), msg.sender, stakeData.amount);

        emit TokensClaimed(msg.sender, stakeData.amount, stakeIndex);
    }

    function getStakeDetails(address user, uint256 stakeIndex) public view returns (uint256, uint256, uint256, bool) {
        require(stakeIndex < stakes[user].length, "Invalid stake index");
        Stake memory stakeData = stakes[user][stakeIndex];
        return (stakeData.amount, stakeData.startTime, stakeData.endTime, stakeData.claimed);
    }
}
