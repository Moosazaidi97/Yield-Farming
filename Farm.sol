// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract YieldFarm {

    struct UserInfo {
        uint256 amount;     // staked tokens
        uint256 rewardDebt; // reward tracking
    }

    struct PoolInfo {
        IERC20 token;           // token to stake
        uint256 allocPoint;     // pool weight
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    IERC20 public rewardToken;
    uint256 public rewardPerBlock;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint;

    constructor(IERC20 _rewardToken, uint256 _rewardPerBlock) {
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
    }

    // Add new pool
    function addPool(uint256 _allocPoint, IERC20 _token) public {
        totalAllocPoint += _allocPoint;

        poolInfo.push(PoolInfo({
            token: _token,
            allocPoint: _allocPoint,
            lastRewardBlock: block.number,
            accRewardPerShare: 0
        }));
    }

    // Update pool rewards
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.number <= pool.lastRewardBlock) return;

        uint256 supply = pool.token.balanceOf(address(this));
        if (supply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 blocks = block.number - pool.lastRewardBlock;
        uint256 reward = (blocks * rewardPerBlock * pool.allocPoint) / totalAllocPoint;

        pool.accRewardPerShare += (reward * 1e12) / supply;
        pool.lastRewardBlock = block.number;
    }

    // Deposit
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accRewardPerShare / 1e12) - user.rewardDebt;
            rewardToken.transfer(msg.sender, pending);
        }

        pool.token.transferFrom(msg.sender, address(this), _amount);
        user.amount += _amount;

        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e12;
    }

    // Withdraw
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "Not enough");

        updatePool(_pid);

        uint256 pending = (user.amount * pool.accRewardPerShare / 1e12) - user.rewardDebt;
        rewardToken.transfer(msg.sender, pending);

        user.amount -= _amount;
        pool.token.transfer(msg.sender, _amount);

        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e12;
    }

    // View pending rewards
    function pendingReward(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 acc = pool.accRewardPerShare;
        uint256 supply = pool.token.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && supply != 0) {
            uint256 blocks = block.number - pool.lastRewardBlock;
            uint256 reward = (blocks * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
            acc += (reward * 1e12) / supply;
        }

        return (user.amount * acc / 1e12) - user.rewardDebt;
    }
}