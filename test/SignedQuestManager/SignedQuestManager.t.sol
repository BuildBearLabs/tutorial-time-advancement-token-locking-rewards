// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {MockToken} from "../../src/mocks/ERC20/MockToken.sol";
import {QuestManager} from "../../src/QuestManager.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";

contract QuestManagerTest is Test {
    address owner = makeAddr("owner");
    address admin1 = makeAddr("admin1");
    address admin2 = makeAddr("admin2");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");

    MockToken weth = new MockToken("WETH", "WETH", 18);
    MockToken wmatic = new MockToken("WMATIC", "WMATIC", 18);
    MockToken usdc = new MockToken("USDC", "USDC", 6);
    MockToken just = new MockToken("JUST", "JUST", 24);

    QuestManager questManager;

    function setUp() public {
        string[] memory tokenNames = new string[](4);
        tokenNames[0] = "WETH";
        tokenNames[1] = "WMATIC";
        tokenNames[2] = "USDC";
        tokenNames[3] = "JUST";
        address[] memory tokenAddresses = new address[](4);
        tokenAddresses[0] = address(weth);
        tokenAddresses[1] = address(wmatic);
        tokenAddresses[2] = address(usdc);
        tokenAddresses[3] = address(just);

        vm.deal(owner, 100 ether);
        // vm.deal(admin1, 100 ether);
        // vm.deal(admin2, 100 ether);
        // vm.deal(user1, 100 ether);
        // vm.deal(user2, 100 ether);
        // vm.deal(user3, 100 ether);
        // vm.deal(user4, 100 ether);

        vm.startBroadcast(owner);
        questManager = new QuestManager(owner, tokenAddresses);
        questManager.transferOwnership(owner);

        weth.mint(owner, 10);
        weth.mint(admin1, 10);
        weth.mint(admin2, 10);
        weth.mint(user1, 10);
        weth.mint(user2, 10);
        weth.mint(user3, 10);
        weth.mint(user4, 10);

        usdc.mint(owner, 1000);
        usdc.mint(admin1, 1000);
        usdc.mint(admin2, 1000);
        usdc.mint(user1, 1000);
        usdc.mint(user2, 1000);
        usdc.mint(user3, 10);
        usdc.mint(user4, 10);

        wmatic.mint(owner, 1000);
        wmatic.mint(admin1, 1000);
        wmatic.mint(admin2, 1000);
        wmatic.mint(user1, 1000);
        wmatic.mint(user2, 1000);
        wmatic.mint(user3, 10);
        wmatic.mint(user4, 10);

        just.mint(owner, 100);
        just.mint(admin1, 100);
        just.mint(admin2, 100);
        just.mint(user1, 100);
        just.mint(user2, 100);
        just.mint(user3, 10);
        just.mint(user4, 10);

        vm.stopBroadcast();

        console.log("address of owner ", address(owner));
        console.log("address of admin1 ", address(admin1));
        console.log("address of admin2 ", address(admin2));
        console.log("address of user1 ", address(user1));
        console.log("address of user2 ", address(user2));
        console.log("address of user3 ", address(user3));
        console.log("address of user4 ", address(user4));
    }

    function test_claimRewardsSignedByNonAdminNonOwner() public {
        (, uint256 key) = makeAddrAndKey("owner");

        vm.startBroadcast(owner);
        just.approve(address(questManager), 1e24);
        questManager.createQuest(
            "4a",
            "Test Quest",
            block.timestamp,
            block.timestamp + 1 days,
            address(just),
            1e24,
            QuestManager.RewardMethod(0),
            QuestManager.RewardType(0),
            3
        );

        // Steps to sign claimRewards Message

        uint256 rewards = questManager.calcuateTokenReward("4a");

        bytes32 message = questManager.i_verificaitonContract().getMessageHash("4a", user1, rewards, "");
        bytes32 signedMessageHash = questManager.i_verificaitonContract().getEthSignedMessageHash(message);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, signedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.stopBroadcast();

        vm.startBroadcast(user1);

        uint256 balanceBeforeUser1 = just.balanceOf(user1);

        vm.warp(block.timestamp + 16 days);

        questManager.claimRewards(owner, signature, "", "4a", payable(user1));

        console.log("just balance of user1 ", just.balanceOf(user1) - balanceBeforeUser1);

        assert(just.balanceOf(user1) - balanceBeforeUser1 == rewards);
        vm.stopBroadcast();
    }

    function test_claimRewardsSignedByOwner() public {
        (, uint256 key) = makeAddrAndKey("user2");

        vm.startBroadcast(user2);
        just.approve(address(questManager), 1e24);
        questManager.createQuest(
            "4a",
            "Test Quest",
            block.timestamp,
            block.timestamp + 1 days,
            address(just),
            1e24,
            QuestManager.RewardMethod(0),
            QuestManager.RewardType(0),
            3
        );

        // Steps to sign claimRewards Message

        uint256 rewards = questManager.calcuateTokenReward("4a");

        bytes32 message = questManager.i_verificaitonContract().getMessageHash("4a", user1, rewards, "");
        bytes32 signedMessageHash = questManager.i_verificaitonContract().getEthSignedMessageHash(message);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, signedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.stopBroadcast();

        vm.startBroadcast(user1);
        vm.warp(block.timestamp + 16 days);
        vm.expectRevert("Claim Not Signed by Admin / Owner");
        questManager.claimRewards(owner, signature, "", "4a", payable(user1));

        vm.stopBroadcast();
    }

    function test_createCustomQuest() public {
        // 6648f67fbab2293153b9b798, Test with NATIVE , 1716057660000, 1717872060000, 0x0000000000000000000000000000000000000000, 1, 1, 1, 3)

        vm.startBroadcast(owner);
        questManager.createQuest{value: 1e18}(
            "6648f67fbab2293153b9b798",
            "Test with NATIVE",
            1716057660000,
            1717872060000,
            0x0000000000000000000000000000000000000000,
            1e18,
            QuestManager.RewardMethod(1),
            QuestManager.RewardType(1),
            3
        );
        vm.stopBroadcast();
    }

    function test_createCustomQuestERC20() public {
        // 6648f67fbab2293153b9b798, Test with NATIVE , 1716057660000, 1717872060000, 0x0000000000000000000000000000000000000000, 1, 1, 1, 3)

        vm.startBroadcast(owner);
        usdc.approve(address(questManager), 1e6);
        questManager.createQuest(
            "6648f67fbab2293153b9b798",
            "Test with NATIVE",
            1716057660000,
            1717872060000,
            address(usdc),
            1,
            QuestManager.RewardMethod(1),
            QuestManager.RewardType(0),
            3
        );
        vm.stopBroadcast();
    }

    function test_claimRewardsSignedByOwnerWithDBData() public {
        (, uint256 key) = makeAddrAndKey("owner");
        vm.startBroadcast(owner);
        weth.mint(owner, 100);
        vm.stopBroadcast();

        vm.startBroadcast(owner);
        weth.approve(address(questManager), 5e16);
        questManager.createQuest(
            "664afb3aa1ca7805e2c6b0ac",
            "Test Quest",
            block.timestamp,
            block.timestamp + 1 days,
            address(weth),
            5e16,
            QuestManager.RewardMethod(1),
            QuestManager.RewardType(0),
            5
        );

        // Steps to sign claimRewards Message

        uint256 rewards = questManager.calcuateTokenReward("664afb3aa1ca7805e2c6b0ac");

        bytes32 message = questManager.i_verificaitonContract().getMessageHash(
            "664afb3aa1ca7805e2c6b0ac", 0xA72e562f24515C060F36A2DA07e0442899D39d2c, rewards, "Signed By : owner"
        );

        bytes32 signedMessageHash = questManager.i_verificaitonContract().getEthSignedMessageHash(message);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, signedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        (bool isValid, address signer) = questManager.i_verificaitonContract().verify(
            owner,
            "664afb3aa1ca7805e2c6b0ac",
            0xA72e562f24515C060F36A2DA07e0442899D39d2c,
            rewards,
            "Signed By : owner",
            signature
        );
        console.log(isValid, signer);

        vm.stopBroadcast();

        vm.startBroadcast(0xA72e562f24515C060F36A2DA07e0442899D39d2c);
        vm.warp(block.timestamp + 16 days);
        // vm.expectRevert("Claim Not Signed by Admin / Owner");
        questManager.claimRewards(
            owner,
            signature,
            "Signed By : owner",
            "664afb3aa1ca7805e2c6b0ac",
            payable(0xA72e562f24515C060F36A2DA07e0442899D39d2c)
        );

        vm.stopBroadcast();
    }
}
