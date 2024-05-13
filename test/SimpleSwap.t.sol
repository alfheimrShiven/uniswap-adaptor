// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {UniswapV3Factory} from "@uniswap/v3-core/contracts/UniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {SwapRouter} from "@uniswap/v3-periphery/contracts/SwapRouter.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {SimpleSwap} from "src/SimpleSwap.sol";
import {IWETH9} from "src/IWETH9.sol";

contract SimpleSwapTest is Test {
    SimpleSwap simpleSwap;
    IWETH9 public constant iWETH9 = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant UNISWAP_V3_SWAPROUTER_ON_ETHEREUM = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() external {
        // Factory -> Router -> SimpleSwap -> Pool
        ISwapRouter iSwapRouter = ISwapRouter(UNISWAP_V3_SWAPROUTER_ON_ETHEREUM);
        simpleSwap = new SimpleSwap(iSwapRouter);

        // getting WETH9
        vm.prank(user);
        console.log('User ETH bal:', user.balance);
        iWETH9.deposit{value: 5}();
    }

    function testSimpleSwapDeploy() external view {
        assert(address(simpleSwap) != address(0));
    }

    function testSwap() external {
        vm.startPrank(user);
        iWETH9.approve(address(simpleSwap), 2); // approving WETH9 to SimpleSwap contract before swap
        uint256 amtOut = simpleSwap.swapWETHForDAI(2);
        vm.stopPrank();

        console.log("Amt Out:", amtOut);
        assert(amtOut > 0);
    }
}
