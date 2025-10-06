// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VerifySignature} from "./utils/VerifySignature.sol";

/**
 * @title QuestManager with Signature Verification
 * @author 0xJustUzair
 * @notice THIS CONTRACT IS EXTENSION OF DEMO CONTRACT WITH SIGNATURE VERIFICATION
 */
contract QuestManager is Ownable {
    /*
    @dev - adding indexed param will change the value of the field
    */
    event QuestManager__EventCreated(string _id);
    event QuestManager__FundsLocked(string _id, address indexed token, uint256 amount);
    event QuestManager__RewardClaimed(string _id, address indexed winner, uint256 amount);
    /*---------------Custom Types -----------------*/

    enum RewardType {
        ERC20, // default ERC20
        NATIVE
    }

    enum RewardMethod {
        FCFS, // default FCFS
        LUCKY_DRAW
    }

    /*
    @params - id: unique identifier for the quest from db
    @params - title: title of the quest
    @params - startTimestamp: start time of the quest
    @params - endTimestamp: end time of the quest
    @params - rewardToken: address of the reward token
    @params - rewardTokenPool: total reward pool / amount of reward tokens
    @params - rewardMethod: method of rewarding the users
    @params - rewardType: type of reward token
    @params - winners: number of winners for the quest

    */
    struct Quest {
        string id;
        string title;
        uint256 startTimestamp;
        uint256 endTimestamp;
        address rewardToken;
        uint256 rewardTokenPool;
        RewardMethod rewardMethod;
        RewardType rewardType;
        uint256 winners;
    }

    /*---------------Storage Variables -----------------*/

    using Strings for string;

    VerifySignature public immutable i_verificaitonContract;
    Quest[] public quests;
    // keep track of user to quests mapping
    mapping(address user => Quest[]) public userQuests;
    // keep track of questId to Quest mapping
    mapping(string id => Quest) public questById;
    // isAllowedToken is used to whitelist the tokens
    mapping(address token => bool isWhiteListed) public isAllowedToken;
    // keep track of if the user is an admin
    mapping(address user => bool isAdmin) public admin;
    // keep track of the allowed total winners for the quest
    mapping(string id => uint256 currentWinners) public currentTotalWinners;
    // keep track of if the user is the quest winner
    mapping(string questId => mapping(address winner => bool isWinner)) public isQuestWinner;
    // keep track of winners for quests
    mapping(string questId => address[] winners) public questWinners;

    modifier _onlyAdminOrOwner() {
        require(msg.sender == owner() || admin[msg.sender], "Not admin/owner");
        _;
    }

    constructor(address _owner, address[] memory _allowedTokenAddresses) Ownable(_owner) {
        uint256 len = _allowedTokenAddresses.length;
        for (uint256 i = 0; i < len;) {
            isAllowedToken[_allowedTokenAddresses[i]] = true;
            unchecked {
                ++i;
            }
        }
        isAllowedToken[address(0)] = true;
        i_verificaitonContract = new VerifySignature();
    }

    function addAdmin(address user) external onlyOwner {
        admin[user] = true;
    }

    function removeAdmin(address user) external onlyOwner {
        admin[user] = false;
    }

    function createQuest(
        string memory _id,
        string memory _title,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _rewardToken,
        uint256 _rewardTokenPool,
        RewardMethod _rewardMethod,
        RewardType _rewardType,
        uint256 _winners
    ) public payable {
        require((questById[_id].id.equal("")), "Quest already exists");
        require(isAllowedToken[_rewardToken], "Token not allowed");
        require(bytes(_title).length > 0, "Title is empty");
        require(_endTimestamp > _startTimestamp, "Invalid Quest Time");
        require(_rewardTokenPool > 0, "Reward amount is 0");

        Quest memory quest = Quest({
            id: _id,
            title: _title,
            startTimestamp: _startTimestamp,
            endTimestamp: _endTimestamp,
            rewardToken: _rewardToken,
            rewardTokenPool: _rewardTokenPool,
            rewardMethod: _rewardMethod,
            rewardType: _rewardType,
            winners: _winners
        });

        quests.push(quest);
        userQuests[msg.sender].push(quest);
        questById[_id] = quest;

        _lockFunds(quest.id, quest.rewardToken);

        emit QuestManager__EventCreated(_id);
    }

    function _lockFunds(string memory _id, address token) internal {
        Quest memory quest = questById[_id];
        uint256 amount = quest.rewardTokenPool;
        require(amount > 0, "Amount is 0");
        if (address(token) == address(0) || quest.rewardType == RewardType.NATIVE) {
            // logic to lock
            require(msg.value == amount, "Native Deposit failed");
        } else {
            require(isAllowedToken[quest.rewardToken], "Token is not allowed");
            bool result = IERC20(token).transferFrom(msg.sender, address(this), amount);
            require(result, "ERC20 Deposit failed");
        }
        emit QuestManager__FundsLocked(_id, token, amount);
    }

    // @TODO REMOVE ADMIN

    function claimRewards(
        address _signer,
        bytes memory signature,
        string memory _message,
        string memory _id,
        address payable winner
    ) external {
        // logic to claim rewards on behalf of user
        Quest memory quest = questById[_id];
        require(quest.id.equal(_id), "Quest not found");
        require(!isQuestWinner[quest.id][address(winner)], "Reward already claimed");
        require(block.timestamp >= quest.endTimestamp, "Quest not ended yet");
        require(quest.winners > currentTotalWinners[_id], "All rewards claimed");
        uint256 reward = calcuateTokenReward(_id);

        (bool status, address signer) =
            i_verificaitonContract.verify(_signer, _id, address(winner), reward, _message, signature);
        require(status && (signer == owner() || admin[signer]), "Claim Not Signed by Admin / Owner");

        if (quest.rewardType == RewardType.NATIVE) {
            // logic to claim rewards for Native
            (bool success,) = payable(winner).call{value: reward}("");
            require(success, "Native Claim failed");
        } else {
            // logic to claim rewards for ERC20
            IERC20(quest.rewardToken).balanceOf(address(this));
            IERC20(quest.rewardToken).approve(address(winner), reward);
            bool success = IERC20(quest.rewardToken).transfer(winner, reward);
            require(success, "ERC20 Claim failed");
        }

        isQuestWinner[quest.id][address(winner)] = true;
        questWinners[quest.id].push(address(winner));
        unchecked {
            ++currentTotalWinners[_id];
        }
        emit QuestManager__RewardClaimed(_id, address(winner), reward);
    }

    function calcuateTokenReward(string memory _questId) public view returns (uint256) {
        Quest memory quest = questById[_questId];
        require(!quest.id.equal(""), "No Quest Found");
        uint256 rewardPool = quest.rewardTokenPool;
        require(rewardPool > 0, "Reward Pool is 0");
        uint256 numWinners = quest.winners;
        require(numWinners > 0, "No Winners");
        uint256 result = (rewardPool / numWinners);
        return result;
    }

    function getQuests() external view returns (Quest[] memory) {
        return quests;
    }

    function getUserQuests(address user) external view returns (Quest[] memory) {
        return userQuests[user];
    }

    function getQuestWinners(string memory _questId) external view returns (address[] memory) {
        return questWinners[_questId];
    }

    function checkIfUserIsWinner(string memory _questId, address user) external view returns (bool) {
        return isQuestWinner[_questId][user];
    }

    function getCurrentTotalWinners(string memory _questId) external view returns (uint256) {
        return currentTotalWinners[_questId];
    }

    function getPendingNumWinnersForQuest(string memory _questId) external view returns (uint256) {
        Quest memory quest = questById[_questId];
        return quest.winners - currentTotalWinners[_questId];
    }

    // Receive native tokens to lock funds
    fallback() external payable {}

    receive() external payable {}
}
