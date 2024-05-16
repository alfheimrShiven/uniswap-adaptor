// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Pool} from "@zkFi/src/core/Pool.sol";
import {Verifier22} from "@zkFi/src/verifiers/Verifier22.sol";
import {VerifierInfo} from "@zkFi/src/libraries/DataTypes.sol";
import {Verifier} from "@zkFi/src/core/Verifier.sol";
import {Convertor} from "@zkFi/src/core/Convertor.sol";
import {Asset, AssetType} from "@zkFi/src/libraries/DataTypes.sol";
import {ZTransaction} from "@zkFi/src/libraries/ZTransaction.sol";
import {IWETH9} from "src/IWETH9.sol";

contract PoolFixture {
    Verifier public verifier;
    Convertor public convertor;
    Pool public pool;

    uint256 public treeDepth = 24;
    address public entryPoint;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public constant INITIAL_SUPPLY = 5 ether;

    Asset public assetDAI;
    Asset public assetWETH9;

    function _initFixture() internal {
        // BaseFixture._initFixture();
        Verifier22 v22 = new Verifier22();
        uint256[] memory ids = new uint256[](1);

        // deploying zkFi verifier
        VerifierInfo[] memory vInfos = new VerifierInfo[](1);
        ids[0] = 2 * 10 + 2;
        vInfos[0] = VerifierInfo({
            addr: address(v22),
            selector: v22.verifyProof.selector
        });
        verifier = new Verifier(ids, vInfos);

        // deploying zkFi convertor
        convertor = new Convertor();
        entryPoint = address(0); // TODO: ??

        pool = new Pool(address(entryPoint));

        // Assets
        assetDAI = Asset({
            assetType: AssetType.ERC20,
            assetAddress: DAI,
            isSupported: true
        });

        assetWETH9 = Asset({
            assetType: AssetType.ERC20,
            assetAddress: WETH9,
            isSupported: true
        });

        AssetType[] memory assetTypes = new AssetType[](2);
        assetTypes[0] = AssetType.ERC20;
        assetTypes[1] = AssetType.ERC20;

        address[] memory assetAddresses = new address[](2);
        assetAddresses[0] = DAI;
        assetAddresses[1] = WETH9;

        pool.initialize(
            treeDepth,
            address(verifier),
            address(convertor),
            assetTypes,
            assetAddresses
        );
    }

    function _getAssetId(address assetAddress) internal view returns (uint24) {
        return pool.getAssetId(assetAddress);
    }
}
