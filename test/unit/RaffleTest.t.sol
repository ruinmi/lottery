// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {DeployConfig} from "script/HelperScript.s.sol";
import {Raffle} from "src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

// Arrange
// Act
// Assert

contract RaffleTest is Test {
    Raffle public raffle;
    DeployConfig deployConfig;
    uint256 constant ENTRANCE_FEE = 1 ether;
    address PLAYER;

    modifier enterAndWarp() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        vm.warp(block.timestamp + deployConfig.interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, deployConfig) = deployRaffle.run();

        PLAYER = makeAddr("player");
        vm.deal(PLAYER, 20 ether);
    }

    function test_EnterRaffle() external {
        uint256 startingBalance = address(raffle).balance;
        vm.prank(PLAYER);

        raffle.enterRaffle{value: ENTRANCE_FEE}();

        assert(raffle.getPlayer(0) == PLAYER);
        assert(address(raffle).balance == startingBalance + ENTRANCE_FEE);

        vm.expectRevert(Raffle.Raffle_NotEnoughMoney.selector);
        raffle.enterRaffle();
    }

    function test_RaffleInitInOpenState() external view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function test_Emit() external {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle.RaffleEntered(PLAYER);

        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }

    function test_CannotEnterRaffleWhilePickingWinner() external enterAndWarp {
        raffle.performUpkeep("");

        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle_NotOpen.selector);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }

    function test_CheckUpkeepResetTimestamp() external {
        vm.warp(block.timestamp + deployConfig.interval * 2);
        vm.roll(block.number + 1);
        uint256 previousTimestamp = raffle.getLastTimestamp();
        (bool needed, ) = raffle.checkUpkeep("");
        uint256 timestamp = raffle.getLastTimestamp();

        console.log(previousTimestamp, timestamp);
        assertEq(needed, false);
        assert(timestamp > previousTimestamp);
    }

    function test_GetEntranceFee() external view {
        assertEq(deployConfig.entranceFee, raffle.getEntranceFee());
    }

    function test_PerformUpkeepFailedWhenCheckUpkeepReturnFalse() external {
        uint256 numOfPlayers = 0;
        uint256 raffleState = 0;

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpkeepNotNeeded.selector,
                address(raffle),
                numOfPlayers,
                raffleState
            )
        );
        raffle.performUpkeep("");

        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        numOfPlayers = 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpkeepNotNeeded.selector,
                address(raffle),
                numOfPlayers,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    function test_PerformUpkeepEmit() external enterAndWarp {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        uint256 subId = uint256(entries[0].topics[2]);

        assert(subId == deployConfig.subscriptionId);
    }

    function test_GetLastWinner() external enterAndWarp {
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(
            deployConfig.vrfCoordinator
        );
        vm.recordLogs();
        raffle.performUpkeep("");
        (uint256 reqId, , , , , ) = abi.decode(
            vm.getRecordedLogs()[0].data,
            (uint256, uint256, uint16, uint32, uint32, bytes)
        );
        coordinator.fulfillRandomWords(reqId, address(raffle));

        address lastWinner = raffle.getLastWinner();

        assert(address(PLAYER) == lastWinner);
    }

    function test_FulfillRandomWordsFailedWithoutRequestRandomWords(
        uint256 reqId
    ) external skipFork {
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(
            deployConfig.vrfCoordinator
        );

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        coordinator.fulfillRandomWords(reqId, address(raffle));
    }

    function test_PickAndFundWinner() external skipFork {
        // Arrange
        address expectedWinner = address(6);
        for (uint160 i = 1; i < 9; i++) {
            hoax(address(i), ENTRANCE_FEE);
            raffle.enterRaffle{value: ENTRANCE_FEE}();
        }
        vm.warp(block.timestamp + deployConfig.interval + 1);
        vm.roll(block.number + 1);
        vm.recordLogs();
        raffle.performUpkeep("");

        (uint256 reqId, , , , , ) = abi.decode(
            vm.getRecordedLogs()[0].data,
            (uint256, uint256, uint16, uint32, uint32, bytes)
        );
        uint256 startBalance = address(1).balance;

        // Act
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(
            deployConfig.vrfCoordinator
        );
        vm.recordLogs();
        coordinator.fulfillRandomWords(reqId, address(raffle));

        // Assert
        Vm.Log[] memory entriesPicked = vm.getRecordedLogs();
        address winner = address(uint160(uint256(entriesPicked[0].topics[1])));
        uint256 prize = abi.decode(entriesPicked[0].data, (uint256));

        assert(winner == expectedWinner);
        assert(address(raffle).balance == 0);
        assert(prize == ENTRANCE_FEE * 8);
        assert(winner.balance == startBalance + prize);
    }
}
