// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;
pragma abicoder v2;

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IConvertProxy} from "@zkFi/src/interfaces/IConvertProxy.sol";
import {Asset, AssetType} from "@zkFi/src/libraries/DataTypes.sol";

contract SimpleSwap is IConvertProxy {
    ISwapRouter public immutable swapRouter;
    address public immutable ZKFI_POOL;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint24 public constant feeTier = 3000;

    constructor(ISwapRouter _swapRouter, address pool_) {
        swapRouter = _swapRouter; // Uniswap V3 Swap router
        ZKFI_POOL = pool_; // zkFi Pool
    }

    /// @dev Will be called by the zkFi protocol to execute the CONVERT trxn
    function convert(
        uint24[] calldata inAssetIds,
        uint256[] calldata inValues,
        bytes calldata payload
    )
        external
        override
        payable
        returns (uint24[] memory outAssetIds, uint256[] memory outValues)
    {
        // getting asset details
        (bool success, bytes memory inAssetRes) = ZKFI_POOL.call(abi.encodeWithSignature("getAsset(uint24)", inAssetIds[0]));
        if(!success) {
            revert('Failled call to zkFi');
        }
        Asset memory inAsset = abi.decode(inAssetRes, (Asset));
        uint256 inValue = inValues[0];

        (uint24 outAssetId, uint256 minOut, address beneficiary) = abi.decode(
            payload,
            (uint24, uint256, address)
        );

         (bool status, bytes memory outAssetRes) = ZKFI_POOL.call(abi.encodeWithSignature("getAsset(uint24)", outAssetId));
         if(!status) {
            revert('Failled call to zkFi');
        }
        Asset memory outAsset = abi.decode(outAssetRes, (Asset));
        // Executing swap using UniswapV3
        uint256 tokenOutAmount = swapExactInputSingle({
            tokenIn: inAsset.assetAddress,
            tokenInAmt: inValue,
            tokenOut: outAsset.assetAddress,
            minOut: minOut,
            receipient: beneficiary // ZTransaction beneficiary
        });

        outAssetIds[0] = outAssetId;
        outValues[0] = tokenOutAmount;
        return (outAssetIds, outValues);
    }

    function swapExactInputSingle(
        address tokenIn,
        uint256 tokenInAmt,
        address tokenOut,
        uint256 minOut,
        address receipient
    ) public returns (uint256 amountOut) {
        // Transfer the specified amount of tokenIn to this adapter contract.
        /// @dev The tokens should be approved by sender before transfer
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            tokenInAmt
        );

        // Approve the Uniswap router to spend tokenIn received by the sender.
        TransferHelper.safeApprove(tokenIn, address(swapRouter), tokenInAmt);

        // Note: To use this example, you should explicitly set slippage limits, omitting for simplicity
        uint160 priceLimit = /* Calculate price limit */ 0;

        // Create the params that will be used to execute the swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: feeTier,
                recipient: receipient, // zkFi Pool
                deadline: block.timestamp,
                amountIn: tokenInAmt,
                amountOutMinimum: minOut,
                sqrtPriceLimitX96: priceLimit
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    /// @dev For reference. To be removed.
    function swapWETHForDAI(
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        // Transfer the specified amount of WETH9 to this contract.
        /// @dev The tokens should be approved by sender before transfer
        TransferHelper.safeTransferFrom(
            WETH9,
            msg.sender,
            address(this),
            amountIn
        );

        // Approve the router to spend WETH9 received by the sender.
        TransferHelper.safeApprove(WETH9, address(swapRouter), amountIn);

        // Note: To use this example, you should explicitly set slippage limits, omitting for simplicity
        uint256 minOut = /* Calculate min output */ 0;
        uint160 priceLimit = /* Calculate price limit */ 0;

        // Create the params that will be used to execute the swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: DAI,
                fee: feeTier,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: minOut,
                sqrtPriceLimitX96: priceLimit
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }
}
