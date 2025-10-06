// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 deployerKey;
    }

    NetworkConfig public activeNetworkConfig;
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    error HelperConfig__InvalidChainId();

    constructor() {
        /* Activate Mainnet Configs */

        networkConfigs[1] = getEthMainnetConfig();
    }
    //////////////////////////////////////////////////////////////*/

    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if (networkConfigs[chainId].deployerKey != uint256(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }
    /**
     * Testnet Configs
     */

    function getPolygonAmoyConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY")});
    }

    function getOptimismSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY")});
    }

    function getBaseSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY")});
    }

    function getOrCreateAnvilConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: DEFAULT_ANVIL_PRIVATE_KEY});
    }

    function getEthSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY")});
    }

    function getArbitrumSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY")});
    }

    /**
     * Mainnet Configs
     */
    function getEthMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY")});
    }

    function getOptimismMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY")});
    }

    function getBaseMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY")});
    }

    function getPolygonMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY")});
    }

    function getArbitrumMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY")});
    }
}
