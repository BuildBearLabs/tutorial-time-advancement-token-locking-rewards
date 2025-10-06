// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {console2} from "forge-std/console2.sol";
import {QuestManager} from "../src/QuestManager.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {MainnetConstants} from "../src/constants/MainnetConstants.sol";

contract MainnetDeploySignedQuestManager is Script {
    IERC20 weth;
    IERC20 usdc;
    IERC20 link;

    QuestManager questManager;
    MainnetConstants constants;

    function run() public {
        uint256 deployerKey;
        address deployer;
        string memory mnemonic = vm.envString("MNEMONIC");
        console2.log(mnemonic);
        (deployer, deployerKey) = deriveRememberKey(mnemonic, 0);

        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vm.startBroadcast(config.deployerKey);

        constants = new MainnetConstants();
        weth = IERC20(constants.WETH());
        link = IERC20(constants.LINK());
        usdc = IERC20(constants.USDC());
        // string[] memory tokenNames = new string[](4);
        // tokenNames[0] = "WETH";
        // tokenNames[2] = "USDC";
        address[] memory tokenAddresses = new address[](4);
        tokenAddresses[0] = address(weth);
        tokenAddresses[1] = address(usdc);
        tokenAddresses[2] = address(link);

        questManager = new QuestManager(address(vm.addr(config.deployerKey)), tokenAddresses);

        console2.log("WETH address : ", address(weth));
        console2.log("USDC address : ", address(usdc));
        console2.log("link address : ", address(link));
        console2.log("verification contract : ", address(questManager.i_verificaitonContract()));
        console2.log("questManager deployed at : ", address(questManager));
        vm.stopBroadcast();
    }
}
