// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {RaffleEnter, RaffleGetEntranceFee, RaffleGetPlayer, RaffleGetRaffleState, RaffleCheckUpkeep, RaffleGetLastTimestamp} from "script/Interactions.s.sol";
import {DeployRaffle, DeployConfig} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";

contract InteractionsTest is Test {
    DeployConfig private _deployConfig;
    Raffle private _raffle;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (_raffle, _deployConfig) = deployRaffle.run();
    }

    function test_EnterRaffle() external {
        new RaffleEnter().enter(address(_raffle), _deployConfig.entranceFee);

        assert(address(_raffle).balance == _deployConfig.entranceFee);
    }

    function test_GetEntranceFee() external {
        uint256 entranceFee = new RaffleGetEntranceFee().getEntranceFee(
            address(_raffle)
        );

        assert(entranceFee == _deployConfig.entranceFee);
    }

    function test_GetPlayer() external {
        new RaffleEnter().enter(address(_raffle), _deployConfig.entranceFee);

        address player = new RaffleGetPlayer().getPlayer(address(_raffle), 0);

        assert(msg.sender == player);
    }

    function test_GetRaffleState() external {
        uint256 raffleState = new RaffleGetRaffleState().getRaffleState(
            address(_raffle)
        );

        assert(raffleState == 0);
    }

    function test_CheckUpkepp() external {
        (bool needed, ) = new RaffleCheckUpkeep().checkUpkeep(address(_raffle));

        assert(needed == false);
    }

    function test_GetLastTimestamp() external {
        uint256 startingTs = block.timestamp;
        uint256 ts = new RaffleGetLastTimestamp().getLastTimestamp(
            address(_raffle)
        );

        assert(startingTs <= ts);
    }
}
