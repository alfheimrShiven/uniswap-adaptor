// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {UniswapZkFiAdaptor} from "src/UniswapZkFiAdaptor.sol";

contract DeployUniswapZkFiAdaptor is Script {
    function run()
        external
        returns (UniswapZkFiAdaptor, HelperConfig)
    {
        HelperConfig config = new HelperConfig();

        (
            address zkFiPool,
            address uniswapRouter,
            uint256 deployerKey
        ) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        UniswapZkFiAdaptor adaptor = new UniswapZkFiAdaptor(uniswapRouter, zkFiPool);
        vm.stopBroadcast();

        return (adaptor, config);
    }
}
