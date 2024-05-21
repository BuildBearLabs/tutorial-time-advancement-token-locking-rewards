// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {console2} from "forge-std/console2.sol";
import {MockToken} from "../../src/mocks/ERC20/MockToken.sol";
import {QuestManager} from "../../src/QuestManager.sol";

contract DeploySignedQuestManager is Script {
    MockToken weth;
    MockToken usdc;
    QuestManager questManager;

    function run() public {
        HelperConfig helperConfig = new HelperConfig();

        (uint256 deployerKey) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        weth = new MockToken("Wrapped Ether", "WETH", 18);
        usdc = new MockToken("USD Coin", "USDC", 6);

        // string[] memory tokenNames = new string[](4);
        // tokenNames[0] = "WETH";
        // tokenNames[2] = "USDC";
        address[] memory tokenAddresses = new address[](2);
        tokenAddresses[0] = address(weth);
        tokenAddresses[1] = address(usdc);

        questManager = new QuestManager(address(0xC49A9B998e41522B39Ab7de8a90663071E3b8a53), tokenAddresses);

        console2.log("WETH deployed at : ", address(weth));
        console2.log("USDC deployed at : ", address(usdc));
        console2.log("verification contract : ", address(questManager.i_verificaitonContract()));
        console2.log("questManager deployed at : ", address(questManager));
        vm.stopBroadcast();
    }
}
