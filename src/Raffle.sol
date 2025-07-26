// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

// Type declarations

// State variables

// Events

// Errors

// Modifiers

// Functions

/**
 * @title Raffle contract
 * @author Guthrie
 * @notice This contract is for creating a simple raffle
 * @dev Implements Chainlink VRFv2.5 and Automation v2.1
 */
contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /** Errors */
    error Raffle_NotEnoughMoney();
    error Raffle_NotOpen();
    error Raffle_TransferFailed();
    error Raffle_UpkeepNotNeeded(address, uint256, uint256);

    /** Type declarations */
    enum RaffleState {
        OPEN,
        WINNER_PICKING
    }

    /** State Variables */
    uint256 private immutable _entranceFee;
    uint256 private immutable _interval;
    uint256 private immutable _subscriptionId;
    bytes32 private immutable _keyHash;

    uint256 private _lastTimestamp;
    address payable[] private _players;
    address payable private _lastWinner;
    RaffleState private _raffleState = RaffleState.OPEN;

    /** Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed player, uint256 prize);

    /** Functions */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        uint256 subscriptionId,
        bytes32 keyHash,
        address vrfCoordinator
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        _entranceFee = entranceFee;
        _interval = interval;
        _subscriptionId = subscriptionId;
        _keyHash = keyHash;
        _lastTimestamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // Checks
        // require(block.timestamp - _lastTimestamp < _interval, Raffle_NotOpen());
        require(_raffleState == RaffleState.OPEN, Raffle_NotOpen());
        require(msg.value >= _entranceFee, Raffle_NotEnoughMoney());

        // Effects
        _players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        public
        override
        returns (bool upkeepNeeded, bytes memory /* performData*/)
    {
        bool isValidTime = block.timestamp - _lastTimestamp >= _interval;
        bool isOpen = _raffleState == RaffleState.OPEN;
        bool hasPlayer = _players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = isValidTime && isOpen && hasPlayer && hasBalance;

        // Effects
        if (isValidTime && isOpen && !hasPlayer) {
            _lastTimestamp = block.timestamp;
        }
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData*/) external override {
        // Checks
        (bool upkeepNeeded, ) = this.checkUpkeep("");
        require(
            upkeepNeeded,
            Raffle_UpkeepNotNeeded(
                address(this),
                _players.length,
                uint256(_raffleState)
            )
        );

        // Effects
        _raffleState = RaffleState.WINNER_PICKING;
        uint32 numWords = 1;
        uint32 callbackGasLimit = 500_000;
        uint16 requestConfirmations = 3;
        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: _keyHash,
                subId: _subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        // Interactions
        s_vrfCoordinator.requestRandomWords(req);
    }

    function fulfillRandomWords(
        uint256 /*requestId */,
        uint256[] calldata randomWords
    ) internal override {
        // Make sure that no one can enter raffle before this line.

        // Effects
        uint256 winnerIdx = randomWords[0] % _players.length;
        address payable winner = _players[winnerIdx];
        _players = new address payable[](0);
        _lastTimestamp = block.timestamp;
        _raffleState = RaffleState.OPEN;
        _lastWinner = winner;

        emit WinnerPicked(winner, address(this).balance);

        // Interactions
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }
    }

    /** Getter Functions */
    function getEntranceFee() external view returns (uint256) {
        return _entranceFee;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return _players[index];
    }

    function getRaffleState() external view returns (RaffleState) {
        return _raffleState;
    }

    function getLastTimestamp() external view returns (uint256) {
        return _lastTimestamp;
    }

    function getLastWinner() external view returns (address) {
        return _lastWinner;
    }
}
