// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {MockToken} from "../../src/mocks/ERC20/MockToken.sol";
import {QuestManager} from "../../src/backup/QuestManager.sol";
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

    modifier _createQuestWithUSDC(uint256 numWinners, uint256 rewardPool) {
        vm.startBroadcast(owner);
        usdc.approve(address(questManager), rewardPool);
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

    modifier _createQuestWithWMATIC(uint256 numWinners, uint256 rewardPool) {
        vm.startBroadcast(owner);
        wmatic.approve(address(questManager), rewardPool);

        questManager.createQuest(
            "1a",
            "Test Quest",
            block.timestamp,
            block.timestamp + 15 days + 10 minutes,
            address(wmatic),
            rewardPool,
            QuestManager.RewardMethod(0),
            QuestManager.RewardType(0),
            numWinners
        );
        _;
    }

    modifier _createQuestWithWETH(uint256 numWinners, uint256 rewardPool) {
        vm.startBroadcast(owner);
        weth.approve(address(questManager), rewardPool);

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

    modifier _createQuestWithJUST(uint256 numWinners, uint256 rewardPool) {
        vm.startBroadcast(owner);
        vm.assume(rewardPool >= 1 && rewardPool <= 100);
        vm.assume(numWinners > 0);
        just.approve(address(questManager), rewardPool);

        questManager.createQuest(
            "1a",
            "Test Quest",
            block.timestamp,
            block.timestamp + 15 days + 10 minutes,
            address(just),
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

    // function testFuzz_rewardDistributionForGreaterThan18DecimalToken(uint256 winners, uint256 rewardPool)
    //     public
    //     _createQuestWithJUST(winners, rewardPool)
    // {
    //     // console.log("just balance = ", just.balanceOf(address(owner)));
    //     uint256 result = questManager.calcuateTokenReward( "1a");
    //     console.log("reward > 18 decimal token = ", result);
    // }

    function test_rewardDistributionForGreaterThan18DecimalToken() public {
        vm.startBroadcast(owner);

        just.approve(address(questManager), 1e24);

        questManager.createQuest(
            "1a",
            "Test Quest",
            block.timestamp,
            block.timestamp + 15 days + 10 minutes,
            address(just),
            1e24,
            QuestManager.RewardMethod(0),
            QuestManager.RewardType(0),
            3
        );
        // console.log("just balance = ", just.balanceOf(address(owner)));
        uint256 result = questManager.calcuateTokenReward("1a");
        console.log("reward > 18 decimal token = ", result);
        vm.stopBroadcast();
    }

    function test_duplicateQuest() public {
        vm.startBroadcast(owner);
        console.log("weth balance of owner ", weth.balanceOf(address(owner)));
        weth.approve(address(questManager), 10e18);
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
        weth.approve(address(questManager), 1e18);
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

        assert(weth.balanceOf(address(questManager)) == 1e18);

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
        weth.approve(address(questManager), 1e18);
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

        uint256 balanceBeforeUser1 = weth.balanceOf(user1);
        uint256 balanceBeforeUser2 = weth.balanceOf(user2);
        uint256 balanceBeforeUser3 = weth.balanceOf(user3);

        vm.warp(block.timestamp + 16 days);
        uint256 rewards = questManager.calcuateTokenReward("4a");
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user1));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user2));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user3));

        console.log("weth balance of user1 ", weth.balanceOf(user1) - balanceBeforeUser1);
        console.log("weth balance of user2 ", weth.balanceOf(user2) - balanceBeforeUser2);
        console.log("weth balance of user3 ", weth.balanceOf(user3) - balanceBeforeUser3);

        assert(weth.balanceOf(user1) - balanceBeforeUser1 == rewards);
        assert(weth.balanceOf(user2) - balanceBeforeUser2 == rewards);
        assert(weth.balanceOf(user3) - balanceBeforeUser3 == rewards);

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
        usdc.approve(address(questManager), 1e6);
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

        uint256 balanceBeforeUser1 = usdc.balanceOf(user1);
        uint256 balanceBeforeUser2 = usdc.balanceOf(user2);
        uint256 balanceBeforeUser3 = usdc.balanceOf(user3);

        vm.warp(block.timestamp + 16 days);
        uint256 rewards = questManager.calcuateTokenReward("4a");
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user1));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user2));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user3));

        console.log("usdc balance of user1 ", usdc.balanceOf(user1) - balanceBeforeUser1);
        console.log("usdc balance of user2 ", usdc.balanceOf(user2) - balanceBeforeUser2);
        console.log("usdc balance of user3 ", usdc.balanceOf(user3) - balanceBeforeUser3);

        assert(usdc.balanceOf(user1) - balanceBeforeUser1 == rewards);
        assert(usdc.balanceOf(user2) - balanceBeforeUser2 == rewards);
        assert(usdc.balanceOf(user3) - balanceBeforeUser3 == rewards);

        vm.stopBroadcast();
    }

    function test_lockAndClaimERC20WithGreaterThan18Decimals() public {
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

        uint256 balanceBeforeUser1 = just.balanceOf(user1);
        uint256 balanceBeforeUser2 = just.balanceOf(user2);
        uint256 balanceBeforeUser3 = just.balanceOf(user3);

        vm.warp(block.timestamp + 16 days);
        uint256 rewards = questManager.calcuateTokenReward("4a");
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user1));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user2));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user3));

        console.log("just balance of user1 ", just.balanceOf(user1) - balanceBeforeUser1);
        console.log("just balance of user2 ", just.balanceOf(user2) - balanceBeforeUser2);
        console.log("just balance of user3 ", just.balanceOf(user3) - balanceBeforeUser3);

        assert(just.balanceOf(user1) - balanceBeforeUser1 == rewards);
        assert(just.balanceOf(user2) - balanceBeforeUser2 == rewards);
        assert(just.balanceOf(user3) - balanceBeforeUser3 == rewards);

        vm.stopBroadcast();
    }

    function test_revertIfAllWinnersClaimed() public {
        vm.startBroadcast(owner);
        weth.approve(address(questManager), 1e18);
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
        vm.warp(block.timestamp + 16 days);
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user1));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user2));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user3));

        vm.expectRevert("All rewards claimed");
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user4));

        vm.stopBroadcast();
    }

    function test_questNotCreated() public {
        vm.startBroadcast(owner);
        weth.approve(address(questManager), 1e18);
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
        vm.warp(block.timestamp + 16 days);
        vm.expectRevert("Quest not found");
        questManager.claimRewardsOnBehalfOfWinner("5a", payable(user1));

        vm.stopBroadcast();
    }

    function test_updateAdminByOwner() public {
        vm.startBroadcast(owner);
        questManager.addAdmin(admin1);
        vm.stopBroadcast();
    }

    function test_updateAdminByNonOwner() public {
        vm.startBroadcast(user1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user1));
        questManager.addAdmin(admin1);
        vm.stopBroadcast();
    }

    function test_claimRewardsByAdmin() public {
        vm.startBroadcast(owner);
        questManager.addAdmin(admin1);
        vm.stopBroadcast();

        vm.startBroadcast(admin1);
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

        uint256 balanceBeforeUser1 = just.balanceOf(user1);
        uint256 balanceBeforeUser2 = just.balanceOf(user2);
        uint256 balanceBeforeUser3 = just.balanceOf(user3);

        vm.warp(block.timestamp + 16 days);
        uint256 rewards = questManager.calcuateTokenReward("4a");
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user1));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user2));
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user3));

        console.log("just balance of user1 ", just.balanceOf(user1) - balanceBeforeUser1);
        console.log("just balance of user2 ", just.balanceOf(user2) - balanceBeforeUser2);
        console.log("just balance of user3 ", just.balanceOf(user3) - balanceBeforeUser3);

        assert(just.balanceOf(user1) - balanceBeforeUser1 == rewards);
        assert(just.balanceOf(user2) - balanceBeforeUser2 == rewards);
        assert(just.balanceOf(user3) - balanceBeforeUser3 == rewards);

        vm.stopBroadcast();
    }

    function test_multipleClaimForSingleWinner() public {
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

        vm.warp(block.timestamp + 16 days);
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user1));
        vm.expectRevert("Reward already claimed");
        questManager.claimRewardsOnBehalfOfWinner("4a", payable(user1));

        vm.stopBroadcast();
    }

    function test_invalidQuestTime() public {
        vm.startBroadcast(owner);
        just.approve(address(questManager), 1e24);

        vm.expectRevert("Invalid Quest Time");
        questManager.createQuest(
            "4a",
            "Test Quest",
            block.timestamp + 1 days,
            block.timestamp,
            address(just),
            1e24,
            QuestManager.RewardMethod(0),
            QuestManager.RewardType(0),
            3
        );

        vm.stopBroadcast();
    }
}
