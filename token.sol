// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Litas Token Contract
/// @notice This contract implements a basic ERC20 token (via OpenZeppelin),
///         with additional functionality for burning and staking.
contract Litas is ERC20, ReentrancyGuard {

    /// @notice Represents a single stake made by a user
    /// @dev Each stake stores the amount of tokens staked, a start time, an end time, 
    ///      and a flag indicating if the stake was already claimed.
    struct Stake {
        uint256 amount;     // The amount of tokens staked
        uint256 startTime;  // The timestamp when the stake was created
        uint256 endTime;    // The timestamp when the stake becomes claimable
        bool claimed;       // True if the stake was claimed, false otherwise
    }

    /// @notice Maps each address to an array of their stakes
    /// @dev Each user can have multiple stakes
    mapping(address => Stake[]) public stakes;

    /// @notice Emitted when tokens are burned
    /// @param burner The address of the user who burned the tokens
    /// @param amount The amount of tokens that were burned
    event TokensBurned(address indexed burner, uint256 amount);

    /// @notice Emitted when tokens are staked
    /// @param staker The address of the user who staked the tokens
    /// @param amount The amount of tokens that were staked
    /// @param duration The duration (in days) for which tokens were staked
    /// @param startTime The timestamp when the stake was created
    event TokensStaked(address indexed staker, uint256 amount, uint256 duration, uint256 startTime);

    /// @notice Emitted when staked tokens are claimed
    /// @param staker The address of the user who claimed the tokens
    /// @param amount The amount of tokens that were claimed
    /// @param stakeIndex The index of the stake in the user's stakes array
    event TokensClaimed(address indexed staker, uint256 amount, uint256 stakeIndex);

    /// @notice Initializes the contract by minting an initial supply to a specified owner
    /// @param name The ERC20 name of the token
    /// @param symbol The ERC20 symbol of the token
    /// @param initialSupply The initial supply of tokens (without decimals)
    /// @param initialOwner The address which will receive the initial supply
    constructor(
        string memory name, 
        string memory symbol, 
        uint256 initialSupply, 
        address initialOwner
    ) 
        ERC20(name, symbol) 
    {
        // Mint the initial supply (scaled by ERC20 decimals) to the provided owner address
        _mint(initialOwner, initialSupply * 10**decimals());
    }

    /// @notice Burns a specified amount of tokens from the caller's balance
    /// @dev Emits a {TokensBurned} event
    /// @param amount The amount of tokens to burn
    function burn(uint256 amount) public {
        // Use OpenZeppelin's _burn to burn the tokens from msg.sender
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /// @notice Allows a user to stake a specified amount of tokens for a given duration
    /// @dev Transfers the tokens from the user's balance to this contract,
    ///      records the stake, and emits a {TokensStaked} event
    /// @param amount The amount of tokens to stake
    /// @param durationInDays The duration (in days) for which the tokens will be locked
    function stake(uint256 amount, uint256 durationInDays) public nonReentrant {
        require(amount > 0, "Cannot stake 0 tokens");
        require(balanceOf(msg.sender) >= amount, "Insufficient token balance");

        // Transfer the tokens from the user to this contract
        _transfer(msg.sender, address(this), amount);

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + (durationInDays * 1 days);

        // Create a new stake and push it into the user's stakes array
        stakes[msg.sender].push(Stake({
            amount: amount,
            startTime: startTime,
            endTime: endTime,
            claimed: false
        }));

        emit TokensStaked(msg.sender, amount, durationInDays, startTime);
    }

    /// @notice Allows a user to claim their staked tokens after the lock period has ended
    /// @dev Transfers the staked tokens back to the user if the stake is valid and unlocked
    /// @param stakeIndex The index of the stake in the user's stakes array
    function claimStakedTokens(uint256 stakeIndex) public nonReentrant {
        // Ensure the stake index is valid
        require(stakeIndex < stakes[msg.sender].length, "Invalid stake index");

        Stake storage stakeData = stakes[msg.sender][stakeIndex];

        // Check that the stake hasn't already been claimed
        require(!stakeData.claimed, "Stake already claimed");
        // Check that the staking period has ended
        require(block.timestamp >= stakeData.endTime, "Stake is still locked");

        // Mark the stake as claimed
        stakeData.claimed = true;

        // Transfer the staked tokens back to the user
        _transfer(address(this), msg.sender, stakeData.amount);

        emit TokensClaimed(msg.sender, stakeData.amount, stakeIndex);
    }

    /// @notice Retrieves details about a specific stake for a user
    /// @dev Returns multiple fields: amount, start time, end time, and claimed status
    /// @param user The address of the user
    /// @param stakeIndex The index of the stake in the user's stakes array
    /// @return amount The staked amount
    /// @return startTime The timestamp when the stake was created
    /// @return endTime The timestamp when the stake becomes claimable
    /// @return claimed True if the stake was already claimed, false otherwise
    function getStakeDetails(address user, uint256 stakeIndex)
        public
        view
        returns (uint256 amount, uint256 startTime, uint256 endTime, bool claimed)
    {
        // Ensure the stake index is valid
        require(stakeIndex < stakes[user].length, "Invalid stake index");

        Stake memory stakeData = stakes[user][stakeIndex];
        return (
            stakeData.amount,
            stakeData.startTime,
            stakeData.endTime,
            stakeData.claimed
        );
    }
}
