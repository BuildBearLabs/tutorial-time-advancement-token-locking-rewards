// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {QuestManager} from "../src/QuestManager.sol";
import {console2} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract ClaimRewardsScript is Script {
    using stdJson for string;

    function run() external {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/broadcast/SignedQuestManager.Deploy.s.sol/1/run-latest.json");
        string memory json = vm.readFile(path);

        address questManagerAddr = json.readAddress(".transactions[1].contractAddress");
        console2.log("QuestManager at:", questManagerAddr);

        QuestManager questManager = QuestManager(payable(questManagerAddr));
        uint256 winnerKey = vm.envUint("WINNER_PRIVATE_KEY");
        uint256 signerKey = vm.envUint("PRIVATE_KEY");

        // --- parameters ---
        string memory questId = "customQuest-01";
        address winner = vm.addr(winnerKey);
        address signer = vm.addr(signerKey); // must be owner or admin

        uint256 reward = questManager.calcuateTokenReward(questId);

        // sign message

        bytes32 message =
            questManager.i_verificaitonContract().getMessageHash(questId, winner, reward, "Signed for claim");
        bytes32 ethSignedMessageHash = questManager.i_verificaitonContract().getEthSignedMessageHash(message);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // broadcast as winner to claim
        vm.startBroadcast(winnerKey);
        questManager.claimRewards(signer, signature, "Signed for claim", questId, payable(winner));
        vm.stopBroadcast();

        console2.log("Rewards claimed by", winner);
    }
}
