// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {PoolFixture} from "test/fixtures/PoolFixture.sol";

contract HelperConfig is Script, PoolFixture {

    struct NetworkConfig {
        address zkFiPool;
        address uniswapRouter;
        uint256 deployerKey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getETHSepoliaConfig();
        } else if (block.chainid == 11155420) {
            activeNetworkConfig = getOPSepoliaConfig();
        } else if (block.chainid == 80002) {
            activeNetworkConfig = getAmoyConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getETHSepoliaConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory ethSepoliaNetworkConfig = NetworkConfig({
            zkFiPool: vm.envAddress("ZKFI_POOL_ETH_SEPOLIA"),
            uniswapRouter: vm.envAddress("UNISWAP_ROUTER_ETH_SEPOLIA"),
            deployerKey: vm.envUint("ETH_SEPOLIA_PRIVATE_KEY")
        });
        return ethSepoliaNetworkConfig;
    }

     function getOPSepoliaConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory opSepoliaNetworkConfig = NetworkConfig({
            zkFiPool: vm.envAddress("ZKFI_POOL_OP_SEPOLIA"),
            uniswapRouter: vm.envAddress("UNISWAP_ROUTER_OP_SEPOLIA"),
            deployerKey: vm.envUint("OP_SEPOLIA_PRIVATE_KEY")
        });
        return opSepoliaNetworkConfig;
    }

    function getAmoyConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory amoyNetworkConfig = NetworkConfig({
            zkFiPool: vm.envAddress("ZKFI_POOL_AMOY"),
            uniswapRouter: vm.envAddress("UNISWAP_ROUTER_AMOY"),
            deployerKey: vm.envUint("AMOY_PRIVATE_KEY")
        });
        return amoyNetworkConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if(address(pool) == address(0)) {
        vm.startBroadcast();
        PoolFixture._initFixture();
        vm.stopBroadcast();
        }
        
        NetworkConfig memory anvilNetworkConfig = NetworkConfig({
            zkFiPool: address(pool),
            uniswapRouter: vm.envAddress("UNISWAP_ROUTER_MAINNET_FORK"),
            deployerKey: vm.envUint("ANVIL_PRIVATE_KEY")
        });
        return anvilNetworkConfig;
    }
}
