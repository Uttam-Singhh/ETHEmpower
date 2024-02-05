//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITokenPool} from "./interfaces/ITokenPool.sol";
import {IAavePool, IAavePoolAddressesProvider} from "./dep/aave.sol";

contract TokenPool is ITokenPool {
  
    IAavePoolAddressesProvider public immutable aavePoolAddressesProvider;


    address public immutable beneficiary;

    
    mapping(address => mapping(address => uint256)) public stakes;

   
    mapping(address => uint256) internal totalStake;

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "only beneficiary");
        _;
    }

    constructor(address _aavePoolAddressesProvider, address _beneficiary) {
        aavePoolAddressesProvider = IAavePoolAddressesProvider(_aavePoolAddressesProvider);
        beneficiary = _beneficiary;
    }


    function approvePool(address token) public {
        require(
            IERC20(token).approve(address(aavePool()), type(uint256).max),
            "AavePool approval failed"
        );
    }

   
    function stake(
        address token,
        address supporter,
        uint256 amount
    ) public virtual {
        require(amount > 0, "zero amount");

        stakes[token][supporter] += amount;
        totalStake[token] += amount;

        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "token transfer failed"
        );
        // For the next step to succeed, approvePool must have been called once before.
        aavePool().supply(token, amount, address(this), 0);

        emit Staked(token, supporter, amount);
    }

    /// @inheritdoc ITokenPool
    function unstake(address token) public virtual returns (uint256) {
        address supporter = msg.sender;
        uint256 amount = stakes[token][supporter];
        require(amount > 0, "no supporter");

        stakes[token][supporter] = 0;
        totalStake[token] -= amount;

        withdraw(token, amount, supporter);

        emit Unstaked(token, supporter, amount);
        return amount;
    }

    /**
     * @inheritdoc ITokenPool
     * @dev Emits a Claimed event on success. Only callable by the beneficiary.
     */
    function claim(address token) public virtual onlyBeneficiary returns (uint256) {
        uint256 amount = claimable(token);
        withdraw(token, amount, beneficiary);

        emit Claimed(token, amount);
        return amount;
    }

    function withdraw(
        address token,
        uint256 amount,
        address receiver
    ) internal {
        aavePool().withdraw(token, amount, receiver);
    }

    /// @inheritdoc ITokenPool
    function claimable(address token) public view returns (uint256) {
        IERC20 aToken = IERC20(aavePool().getReserveData(token).aTokenAddress);
        return aToken.balanceOf(address(this)) - staked(token);
    }

    /// @inheritdoc ITokenPool
    function staked(address token) public view returns (uint256) {
        return totalStake[token];
    }

    function aavePool() internal view returns (IAavePool) {
        return IAavePool(aavePoolAddressesProvider.getPool());
    }
}

contract TokenPoolWithApproval is TokenPool {
    constructor(
        address _aavePoolAddressesProvider,
        address _beneficiary,
        address[] memory _approvedTokens
    ) TokenPool(_aavePoolAddressesProvider, _beneficiary) {
        for (uint256 i = 0; i < _approvedTokens.length; i++) approvePool(_approvedTokens[i]);
    }
}