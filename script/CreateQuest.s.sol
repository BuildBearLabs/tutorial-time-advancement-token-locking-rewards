// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {QuestManager} from "../src/QuestManager.sol";
import {console2} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract CreateQuest is Script {
    using stdJson for string;

    function run() external {
        // load json from broadcast file
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/broadcast/SignedQuestManager.Deploy.s.sol/1/run-latest.json");
        string memory json = vm.readFile(path);

        // extract QuestManager address
        address questManagerAddr = json.readAddress(".transactions[1].contractAddress");
        console2.log("QuestManager at:", questManagerAddr);

        QuestManager questManager = QuestManager(payable(questManagerAddr));

        // params
        string memory questId = "customQuest-01";
        string memory title = "BuildBear Demo Quest";
        uint256 startTime = block.timestamp;
        uint256 endTime = block.timestamp + 3 days;
        address rewardToken = address(0); // native
        uint256 rewardPool = 3 ether;
        QuestManager.RewardMethod method = QuestManager.RewardMethod.FCFS;
        QuestManager.RewardType rewardType = QuestManager.RewardType.NATIVE;
        uint256 winners = 3;

        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        questManager.createQuest{value: rewardPool}(
            questId, title, startTime, endTime, rewardToken, rewardPool, method, rewardType, winners
        );
        vm.stopBroadcast();

        console2.log("Quest created:", questId);
    }
}
