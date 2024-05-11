// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {Test} from "forge-std/Test.sol";
import {UniswapV3Factory} from "@uniswap/v3-core/contracts/UniswapV3Factory.sol";
import {SwapRouter} from "@uniswap/v3-periphery/contracts/SwapRouter.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {SimpleSwap} from "src/SimpleSwap.sol";

contract SwapTest is Test {
    SimpleSwap simpleSwap;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setUp() external {
        UniswapV3Factory factory = new UniswapV3Factory();
        SwapRouter swapRouter = new SwapRouter(address(factory), WETH9);
        ISwapRouter iSwapRouter = ISwapRouter(address(swapRouter));
        simpleSwap = new SimpleSwap(iSwapRouter);
    }

    function testSimpleSwapDeploy() external {
        assert(address(simpleSwap) != address(0));
    }
}