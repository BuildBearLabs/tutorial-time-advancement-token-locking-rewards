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

interface IWETH {
    function grantRole(bytes32 role, address account) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
}

contract QuestManagerTest is Test {
    uint256 polygonMainnetFork;

    // Test accounts from base mainnet

    address owner = address(0xae072206b8a7e686DD27F98d0082ab2d4AC8b87b);
    address admin1 = address(0xbF8BC84394708efB2C934eff0107F9AFB9dEC816);
    address admin2 = address(0x632B8d30C545b899f457c326A7Abd58a6E887211);
    address user1 = address(0x6e5Ff11C8f53F85Ed7A495817fea8449203C27c2);
    address user2 = address(0xBc6AdD937Aa423D5Ab073f963C774738D222d7eE);
    address user3 = address(0x00F1C7697E851284a2CbF1CAE0f5a963eD686aFF);
    address user4 = address(0xE0Ca02E16Bf131f6c92Dd2F0C798538a7E11F9b4);

    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address usdc = address(0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359);

    QuestManager questManager;

    function setUp() public {
        polygonMainnetFork = vm.createFork("https://polygon-bor-rpc.publicnode.com");
        vm.selectFork(polygonMainnetFork);

        string[] memory tokenNames = new string[](4);
        tokenNames[0] = "WETH";
        tokenNames[1] = "USDC";

        address[] memory tokenAddresses = new address[](4);
        tokenAddresses[0] = address(weth);
        tokenAddresses[1] = address(usdc);

        vm.startBroadcast(address(0x00));
        IWETH(weth).hasRole(bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), address(0));
        IWETH(weth).grantRole(bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), address(0));

        vm.deal(owner, 100 ether);

        IERC20(weth).mint(owner, 10);
        IERC20(weth).mint(admin1, 10);
        IERC20(weth).mint(admin2, 10);
        IERC20(weth).mint(user1, 10);
        IERC20(weth).mint(user2, 10);
        IERC20(weth).mint(user3, 10);
        IERC20(weth).mint(user4, 10);
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
