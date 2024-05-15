// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {PoolFixture} from "./fixtures/PoolFixture.sol";
import {TransactionRequest} from "@zkFi/test/helpers/TransactionRequest.sol";
import {ZTransaction} from "@zkFi/src/libraries/ZTransaction.sol";
import {ZkFi} from "@zkFi/test/helpers/ZkFi.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {SimpleSwap} from "src/SimpleSwap.sol";
import {IWETH9} from "src/IWETH9.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IConvertor} from "@zkFi/src/interfaces/IConvertor.sol";

contract SimpleSwapTest is Test, PoolFixture {
    SimpleSwap simpleSwap;
    IWETH9 public constant iWETH9 =
        IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant UNISWAP_V3_SWAPROUTER_ON_ETHEREUM =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    uint256 public constant SWAP_AMT = 2 ether;
    address public user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint24[] inAssetIds;
    uint256[] inValues;

    // modifier zkFiSetup() {
    //     pool.setProxy(address(simpleSwap), true);
    //     vm.startPrank(user);
    //     _mockDeposit(); // deposits funds from PoolFixture to pool using ZTrnx
    //     vm.stopPrank();
    //     _;
    // }

    function setUp() external {
        PoolFixture._initFixture();
        // Factory -> Router -> SimpleSwap -> Pool
        ISwapRouter iSwapRouter = ISwapRouter(
            UNISWAP_V3_SWAPROUTER_ON_ETHEREUM
        );
        simpleSwap = new SimpleSwap(iSwapRouter, address(pool));

        // getting WETH9
        vm.prank(user);
        console.log("User ETH bal:", user.balance);
        iWETH9.deposit{value: INITIAL_SUPPLY}();
    }

    function testSimpleSwapDeploy() external view {
        assert(address(simpleSwap) != address(0));
    }

    function testDirectSwapWithUniswap() external {
        vm.startPrank(user);
        iWETH9.approve(address(simpleSwap), SWAP_AMT); // approving WETH9 to SimpleSwap contract before swap
        uint256 amtOut = simpleSwap.swapWETHForDAI(SWAP_AMT);
        vm.stopPrank();

        console.log("Amt Out:", amtOut);
        assert(amtOut > 0);
    }

    function testSwapThroughZkFi() external /* zkFiSetup */ {
        uint256 poolDAIBalBeforeConvert = IERC20(DAI).balanceOf(address(pool));
        uint24 wETHAssetId = _getAssetId(WETH9);
        uint24 DAIAssetId = _getAssetId(DAI);
        uint256 convertValue = SWAP_AMT;

        // preparing payload to SimpleSwap
        inAssetIds.push(wETHAssetId);
        inValues.push(convertValue);
        bytes memory payload = abi.encode(DAIAssetId, 0, address(convertor));

        vm.startPrank(user);
        iWETH9.approve(address(pool), INITIAL_SUPPLY);
        iWETH9.transfer(address(pool), INITIAL_SUPPLY);
        vm.stopPrank();

        vm.startPrank(address(pool));
        iWETH9.approve(address(convertor), convertValue);
        /// @dev For test setup simplicity, directly calling Convertor::convert(..) from Pool instead of calling Pool::transact(ztx) Ref Line 100 - 104
        // InAssets will move user -> pool -> convertor -> uniswap
        // OutAssets will move from uniswap -> convertor (beneficiery/receipient) -> pool (assetManager)
        (, uint256[] memory outValues) = IConvertor(address(convertor))
            .convert({
                target: address(simpleSwap),
                inAssetIds: inAssetIds,
                inValues: inValues,
                targetPayload: payload
            });
        vm.stopPrank();

        vm.prank(address(pool));
        IERC20(DAI).transferFrom(
            address(convertor),
            address(pool),
            outValues[0]
        );

        // TODO: Mature test setup to support ZTransaction
        // TransactionRequest memory convertReq = _createConvertReq(wETHAssetId, convertValue);
        // convertReq.to = abi.encode(address(pool)); // Not sure
        // ZTransaction memory convertZTx = zkfi.getZTx(convertReq);
        // pool.transact(convertZTx);

        // Asserts
        uint256 poolDAIBalPostConvert = IERC20(DAI).balanceOf(address(pool));
        assert(poolDAIBalPostConvert > poolDAIBalBeforeConvert);
    }
}
