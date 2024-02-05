//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title ETHEmpower Token Pool Interface
 * @author Uttam Singh
 */
interface ITokenPool {

    event Staked(address indexed token, address indexed supporter, uint256 amount);

   
    event Unstaked(address indexed token, address indexed supporter, uint256 amount);

    
    event Claimed(address indexed token, uint256 amount);

    
    function beneficiary() external view returns (address);

    function stake(
        address token,
        address supporter,
        uint256 amount
    ) external;

   
    function unstake(address token) external returns (uint256);

    function claim(address token) external returns (uint256);

    function claimable(address token) external view returns (uint256);

    function staked(address token) external view returns (uint256);
}