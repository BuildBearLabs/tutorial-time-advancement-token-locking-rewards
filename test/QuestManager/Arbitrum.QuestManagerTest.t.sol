// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {MockToken} from "../../src/mocks/ERC20/MockToken.sol";
import {QuestManager} from "../../src/backup/QuestManager.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";

// @TODO : Pending tests

interface IUSDC {
    function balanceOf(address account) external view returns (uint256);
    function mint(address to, uint256 amount) external;
    function configureMinter(address minter, uint256 minterAllowedAmount) external;
    function masterMinter() external view returns (address);
}

contract QuestManagerTest is Test {
    uint256 arbitrumMainnetFork;

    // Test accounts from base mainnet

    address owner = address(0xa92B0C8d2724FC02203C004174f94f05A27796f3);
    address admin1 = address(0xd5BCd7a3223095b3695a8bF2888028C4A11f2600);
    address admin2 = address(0x684CA4c94CC7eF3C6CB31B89a8d56D59Fef4f1c9);
    address user1 = address(0xA626Bd40A8c88F59A4CF9b1821A7bD71faD96285);
    address user2 = address(0xb3C0a00738f42EcA68796575D97bce532f58d4f0);
    address user3 = address(0x46b80B087a76ac7fcf5776032aAEaddf9a8336d7);
    address user4 = address(0xf072bBF692c9BCe64745D8c282d6B107054dA3Ba);

    address weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address usdc = address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);

    QuestManager questManager;

    function setUp() public {
        arbitrumMainnetFork = vm.createFork("https://base.meowrpc.com");
        vm.selectFork(arbitrumMainnetFork);

        string[] memory tokenNames = new string[](4);
        tokenNames[0] = "WETH";
        tokenNames[1] = "USDC";

        address[] memory tokenAddresses = new address[](4);
        tokenAddresses[0] = address(weth);
        tokenAddresses[1] = address(usdc);

        vm.startBroadcast(address(0));
        vm.deal(owner, 100 ether);

        IERC20(weth).mint(owner, 1);
        IERC20(weth).mint(admin1, 1);
        IERC20(weth).mint(admin2, 1);
        IERC20(weth).mint(user1, 1);
        IERC20(weth).mint(user2, 1);
        IERC20(weth).mint(user3, 1);
        IERC20(weth).mint(user4, 1);
        vm.stopBroadcast();

        vm.prank(IUSDC(usdc).masterMinter());
        IUSDC(usdc).configureMinter(address(this), type(uint256).max);

        vm.startBroadcast(address(this));

        IERC20(usdc).mint(owner, 1000);
        IERC20(usdc).mint(admin1, 1000);
        IERC20(usdc).mint(admin2, 1000);
        IERC20(usdc).mint(user1, 1000);
        IERC20(usdc).mint(user2, 1000);
        IERC20(usdc).mint(user3, 1000);
        IERC20(usdc).mint(user4, 1000);
        vm.stopBroadcast();

        vm.startBroadcast(owner);
        questManager = new QuestManager(owner, tokenAddresses);
        questManager.transferOwnership(owner);

        vm.stopBroadcast();
        console.log("----------------------------------------------------------");
        console.log("----- Forked Base Mainnet ----- Chainid : ", block.chainid);
        console.log("----------------------------------------------------------");

        console.log("address of owner ", address(owner));
        console.log("address of admin1 ", address(admin1));
        console.log("address of admin2 ", address(admin2));
        console.log("address of user1 ", address(user1));
        console.log("address of user2 ", address(user2));
        console.log("address of user3 ", address(user3));
        console.log("address of user4 ", address(user4));
    }

    modifier _createQuestWithUSDC(uint256 numWinners, uint256 rewardPool) {
        vm.startBroadcast(owner);
        IERC20(usdc).approve(address(questManager), rewardPool);
        questManager.createQuest(
            "1a",
            "Test Quest",
            block.timestamp,
            block.timestamp + 15 days + 10 minutes,
            address(usdc),
            rewardPool,
            QuestManager.RewardMethod(0),
            QuestManager.RewardType(0),
            numWinners
        );
        _;
    }

    modifier _createQuestWithWETH(uint256 numWinners, uint256 rewardPool) {
        vm.startBroadcast(owner);
        IERC20(weth).approve(address(questManager), rewardPool);

        questManager.createQuest(
            "1a",
            "Test Quest",
            block.timestamp,
            block.timestamp + 15 days + 10 minutes,
            address(weth),
            rewardPool,
            QuestManager.RewardMethod(0),
            QuestManager.RewardType(0),
            numWinners
        );
        _;
    }

    function test_rewardDistributionForLessThan18DecimalToken() public _createQuestWithUSDC(3, 1e6) {
        uint256 result = questManager.calcuateTokenReward("1a");
        console.log("reward < 18 decimal token= ", result);
    }

    function test_rewardDistributionFor18DecimalToken() public _createQuestWithWETH(3, 1e18) {
        uint256 result = questManager.calcuateTokenReward("1a");
        console.log("reward 18 decimal token = ", result);
    }

    function test_duplicateQuest() public {
        vm.startBroadcast(owner);
        console.log("weth balance of owner ", IERC20(weth).balanceOf(address(owner)));
        IERC20(weth).approve(address(questManager), 10e18);
        questManager.createQuest(
            "4a",
            "Test Quest",
            block.timestamp,
            block.timestamp + 15 days + 10 minutes,
            address(weth),
            10e18,
            QuestManager.RewardMethod(0),
            QuestManager.RewardType(0),
            2
        );
        vm.expectRevert("Quest already exists");

        questManager.createQuest(
            "4a",
            "Test Quest",
            block.timestamp,
            block.timestamp + 15 days + 10 minutes,
            address(weth),
            10e18,
            QuestManager.RewardMethod(0),
            QuestManager.RewardType(0),
            2
        );
        vm.stopBroadcast();
    }

    function test_lock() public {
        vm.startBroadcast(owner);
        IERC20(weth).approve(address(questManager), 1e18);
        vm.expectEmit();
        emit QuestManager.QuestManager__FundsLocked("4a", address(weth), 1e18);
        vm.expectEmit();
        emit QuestManager.QuestManager__EventCreated("4a");

        questManager.createQuest(
            "4a",
            "Test Quest",
            block.timestamp,
            block.timestamp + 15 days + 10 minutes,
            address(weth),
            1e18,
            QuestManager.RewardMethod(0),
            QuestManager.RewardType(0),
            3
        );

        assert(IERC20(weth).balanceOf(address(questManager)) == 1e18);

        vm.stopBroadcast();
    }

    function test_lockNative() public {
        vm.startBroadcast(owner);

        questManager.createQuest{value: 1e18}(
            "4a",
            "Test Quest",
            block.timestamp,
            block.timestamp + 1 days,
            address(0),
            1e18,
            QuestManager.RewardMethod(0),
            QuestManager.RewardType(1),
            3
        );

        vm.stopBroadcast();
    }

    function test_lockAndClaimERC20With18Decimals() public {
        vm.startBroadcast(owner);
        IERC20(weth).approve(address(questManager), 1e18);
        questManager.createQuest(
            "4a",
            "Test Quest",
            block.timestamp,
            block.timestamp + 1 days,
            address(weth),
            1e18,
            QuestManager.RewardMethod(0),
            QuestManager.RewardType(0),
            3
        );

        uint256 balanceBeforeUser1 = IERC20(weth).balanceOf(user1);
        uint256 balanceBeforeUser2 = IERC20(weth).balanceOf(user2);
        uint256 balanceBeforeUser3 = IERC20(weth).balanceOf(user3);

        vm.warp(block.timestamp + 16 days);
        uint256 rewards = questManager.calcuateTokenReward("4a");
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user1));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user2));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user3));

        console.log("weth balance of user1 ", IERC20(weth).balanceOf(user1) - balanceBeforeUser1);
        console.log("weth balance of user2 ", IERC20(weth).balanceOf(user2) - balanceBeforeUser2);
        console.log("weth balance of user3 ", IERC20(weth).balanceOf(user3) - balanceBeforeUser3);

        assert(IERC20(weth).balanceOf(user1) - balanceBeforeUser1 == rewards);
        assert(IERC20(weth).balanceOf(user2) - balanceBeforeUser2 == rewards);
        assert(IERC20(weth).balanceOf(user3) - balanceBeforeUser3 == rewards);

        vm.stopBroadcast();
    }

    function test_lockAndClaimNative() public {
        vm.startBroadcast(owner);
        console.log("balance of owner ", address(owner).balance);
        questManager.createQuest{value: 1e18}(
            "4a",
            "Test Quest",
            block.timestamp,
            block.timestamp + 1 days,
            address(0),
            1e18,
            QuestManager.RewardMethod(0),
            QuestManager.RewardType(1),
            3
        );

        uint256 balanceBeforeUser1 = address(user1).balance;
        uint256 balanceBeforeUser2 = address(user2).balance;
        uint256 balanceBeforeUser3 = address(user3).balance;

        vm.warp(block.timestamp + 16 days);

        uint256 rewards = questManager.calcuateTokenReward("4a");
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user1));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user2));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user3));

        console.log("Native ETH balance of user1 ", address(user1).balance - balanceBeforeUser1);
        console.log("Native ETH balance of user2 ", address(user2).balance - balanceBeforeUser2);
        console.log("Native ETH balance of user3 ", address(user3).balance - balanceBeforeUser3);

        assert(address(user1).balance - balanceBeforeUser1 == rewards);
        assert(address(user2).balance - balanceBeforeUser2 == rewards);
        assert(address(user3).balance - balanceBeforeUser3 == rewards);

        vm.stopBroadcast();
    }

    function test_lockAndClaimERC20WithLessThan18Decimals() public {
        vm.startBroadcast(owner);
        IERC20(usdc).approve(address(questManager), 1e6);
        questManager.createQuest(
            "4a",
            "Test Quest",
            block.timestamp,
            block.timestamp + 1 days,
            address(usdc),
            1e6,
            QuestManager.RewardMethod(0),
            QuestManager.RewardType(0),
            3
        );

        uint256 balanceBeforeUser1 = IERC20(usdc).balanceOf(user1);
        uint256 balanceBeforeUser2 = IERC20(usdc).balanceOf(user2);
        uint256 balanceBeforeUser3 = IERC20(usdc).balanceOf(user3);

        vm.warp(block.timestamp + 16 days);
        uint256 rewards = questManager.calcuateTokenReward("4a");
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user1));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user2));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user3));

        console.log("usdc balance of user1 ", IERC20(usdc).balanceOf(user1) - balanceBeforeUser1);
        console.log("usdc balance of user2 ", IERC20(usdc).balanceOf(user2) - balanceBeforeUser2);
        console.log("usdc balance of user3 ", IERC20(usdc).balanceOf(user3) - balanceBeforeUser3);

        assert(IERC20(usdc).balanceOf(user1) - balanceBeforeUser1 == rewards);
        assert(IERC20(usdc).balanceOf(user2) - balanceBeforeUser2 == rewards);
        assert(IERC20(usdc).balanceOf(user3) - balanceBeforeUser3 == rewards);

        vm.stopBroadcast();
    }
}
