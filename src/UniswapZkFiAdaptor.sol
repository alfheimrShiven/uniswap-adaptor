// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;
pragma abicoder v2;

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IConvertProxy} from "@zkFi/src/interfaces/IConvertProxy.sol";
import {Asset, AssetType} from "@zkFi/src/libraries/DataTypes.sol";

contract UniswapZkFiAdaptor is IConvertProxy {
    // Errors //
    error AssetNotSupportedByZkFi(uint256 assetId);
    error OnlySingleAssetSwapSupported();
    error InAssetValueShouldBeNonZero();
    error ZeroAddressError();

    ISwapRouter public immutable ISWAP_ROUTER;
    address public immutable ZKFI_POOL;
    uint24 public constant feeTier = 3000;

    constructor(address swapRouter_, address pool_) {
        ISWAP_ROUTER = ISwapRouter(swapRouter_); // Uniswap V3 Swap router
        ZKFI_POOL = pool_; // zkFi Pool
    }

    /// @dev Will be called by the zkFi Convertor.sol to execute the swap.
    function convert(
        uint24[] calldata inAssetIds,
        uint256[] calldata inValues,
        bytes calldata payload
    )
        external
        payable
        override
        returns (uint24[] memory outAssetIds, uint256[] memory outValues)
    {
        uint256 inValue;
        // Checks
        if (inAssetIds.length != 1 || inValues.length != 1) {
            revert OnlySingleAssetSwapSupported();
        }

        if (inValues[0] == 0) {
            revert InAssetValueShouldBeNonZero();
        } else {
            inValue = inValues[0];
        }

        // getting asset details
        // TODO: check if outAsset is supported by zkFi pool
        (bool success, bytes memory inAssetRes) = ZKFI_POOL.call(
            abi.encodeWithSignature("getAsset(uint24)", inAssetIds[0])
        );
        if (!success) {
            revert("Failed call to zkFi");
        }
        Asset memory inAsset = abi.decode(inAssetRes, (Asset));
        if (!inAsset.isSupported) {
            revert AssetNotSupportedByZkFi(inAssetIds[0]);
        }

        // decoding payload
        (
            uint24 outAssetId,
            address beneficiary,
            uint256 minOut,
            uint256 deadlineFromNow
        ) = abi.decode(payload, (uint24, address, uint256, uint256));

        if (beneficiary == address(0)) {
            revert ZeroAddressError();
        }

        // TODO: check if outAsset is supported by zkFi pool
        (bool status, bytes memory outAssetRes) = ZKFI_POOL.call(
            abi.encodeWithSignature("getAsset(uint24)", outAssetId)
        );
        if (!status) {
            revert("Failed call to zkFi");
        }

        Asset memory outAsset = abi.decode(outAssetRes, (Asset));
        if (!outAsset.isSupported) {
            revert AssetNotSupportedByZkFi(outAssetId);
        }

        // Executing swap using UniswapV3
        uint256 tokenOutAmount = swapExactInputSingle({
            tokenIn: inAsset.assetAddress,
            tokenInAmt: inValue,
            tokenOut: outAsset.assetAddress,
            minOut: minOut,
            receipient: beneficiary,
            deadlineFromNow: deadlineFromNow
        });

        // initialising out arrays
        outAssetIds = new uint24[](1);
        outValues = new uint256[](1);

        outAssetIds[0] = outAssetId;
        outValues[0] = tokenOutAmount;
        return (outAssetIds, outValues);
    }

    /// @param tokenIn The address of the token to be swapped
    /// @param tokenInAmt The amount of `tokenIn` tokens to swap
    /// @param tokenOut The address of the output token
    /// @param minOut The minimum amount of output token the user expects to get back. This is used for slippage protection
    /// @param receipient The address which will receive the output tokens. This will be the zkFi Convertor.sol contract.
    /// @param deadlineFromNow The time (in seconds) added to current block time which will provide the deadline of the transaction. If the swap takes longer than this, it will revert.
    function swapExactInputSingle(
        address tokenIn,
        uint256 tokenInAmt,
        address tokenOut,
        uint256 minOut,
        address receipient,
        uint256 deadlineFromNow
    ) public returns (uint256 amountOut) {
        // Checks
        uint256 transactionDeadline = block.timestamp + deadlineFromNow;

        // Transfer the specified amount of tokenIn to the zkFi convertor which will be calling this adaptor.
        /// @dev The tokens should be approved by the ZkFi pool before transfer
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender, // pool
            address(this), // Convertor.sol
            tokenInAmt
        );

        // ZkFi convertor to approve the Uniswap adaptor the inTokens received.
        TransferHelper.safeApprove(tokenIn, address(ISWAP_ROUTER), tokenInAmt);

        // Create the params that will be used to execute the swap
        /// @param sqrtPriceLimitX96 This is the sqrt of potential value decrease of outAsset relative to inAsset (uint160), that the trader is willing to ignore for the swap. We will be deactivating this protective measure for the MVP. We will only be deploying the slippage protection using `amountOutMinimum`
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: feeTier,
                recipient: receipient, // Convertor.sol
                deadline: transactionDeadline,
                amountIn: tokenInAmt,
                amountOutMinimum: minOut,
                sqrtPriceLimitX96: uint160(0)
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = ISWAP_ROUTER.exactInputSingle(params);
    }
}
