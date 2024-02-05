//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IWETHGateway} from "./dep/aave.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import {BeneficiaryPool} from "./BeneficiaryPool.sol";


contract ETHEmpower {
    event PoolDeployed(address indexed beneficiary, address indexed deployer, address pool);

    address private immutable beneficiaryPoolLib;
    address public immutable aavePool;
    IWETHGateway public immutable wethgw;
    IERC20 public immutable token;

    // beneficiary => BeneficiaryPool
    mapping(address => BeneficiaryPool) public beneficiaryPools;

    constructor(
        address _pool,
        address wethGateway,
        address aWETH
    ) {
        aavePool = _pool;
        wethgw = IWETHGateway(wethGateway);
        token = IERC20(aWETH);

        BeneficiaryPool bp = new BeneficiaryPool();
        // init it so no one else can (RIP Parity Multisig)
        bp.init(address(this), msg.sender);
        beneficiaryPoolLib = address(bp);
    }

    function deployPool(address beneficiary) external returns (address) {
        BeneficiaryPool bpool = BeneficiaryPool(Clones.clone(beneficiaryPoolLib));
        bpool.init(address(this), beneficiary);
        beneficiaryPools[beneficiary] = bpool;

        emit PoolDeployed(beneficiary, msg.sender, address(bpool));
        return address(bpool);
    }

    // claimable returns the total earned ether by the provided beneficiary.
    // It is the accrued interest on all staked ether.
    // It can be withdrawn by the beneficiary with claim.
    function claimable(address beneficiary) public view returns (uint256) {
        BeneficiaryPool bpool = beneficiaryPools[beneficiary];
        if (address(bpool) == address(0)) {
            return 0;
        }
        return bpool.claimable();
    }

    // staked returns the total staked ether on behalf of the beneficiary.
    function staked(address beneficiary) public view returns (uint256) {
        BeneficiaryPool bpool = beneficiaryPools[beneficiary];
        if (address(bpool) == address(0)) {
            return 0;
        }
        return bpool.staked();
    }

    // returns the total staked ether by the supporter and the timeout until
    // which the stake is locked.
    function supporterStaked(address supporter, address beneficiary)
        public
        view
        returns (uint256, uint256)
    {
        BeneficiaryPool bpool = beneficiaryPools[beneficiary];
        if (address(bpool) == address(0)) {
            return (0, 0);
        }
        return (bpool.stakes(supporter), bpool.lockTimeout(supporter));
    }
}

