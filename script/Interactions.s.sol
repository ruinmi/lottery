// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Raffle} from "src/Raffle.sol";

contract RaffleEnter is Script {
    uint256 private _bet_amount = 0.01 ether;

    function run() external {
        if (block.chainid == 31337) {
            _bet_amount = 1 ether;
        }
        enter(
            DevOpsTools.get_most_recent_deployment("Raffle", block.chainid),
            _bet_amount
        );
    }

    function enter(address raffleAddr, uint256 amount) public {
        Raffle raffle = Raffle(raffleAddr);
        vm.startBroadcast();
        raffle.enterRaffle{value: amount}();
        vm.stopBroadcast();
    }
}

contract RaffleCheckUpkeep is Script {
    function run() external returns (bool) {
        (bool needed, ) = checkUpkeep(
            DevOpsTools.get_most_recent_deployment("Raffle", block.chainid)
        );
        return needed;
    }

    function checkUpkeep(
        address raffleAddr
    ) public returns (bool, bytes memory) {
        Raffle raffle = Raffle(raffleAddr);
        return raffle.checkUpkeep("");
    }
}

contract RaffleGetEntranceFee is Script {
    function run() external view returns (uint256) {
        return
            getEntranceFee(
                DevOpsTools.get_most_recent_deployment("Raffle", block.chainid)
            );
    }

    function getEntranceFee(address raffleAddr) public view returns (uint256) {
        Raffle raffle = Raffle(raffleAddr);
        return raffle.getEntranceFee();
    }
}

contract RaffleGetPlayer is Script {
    uint256 private constant PLAYER_IDX = 0;

    function run() external view returns (address) {
        return
            getPlayer(
                DevOpsTools.get_most_recent_deployment("Raffle", block.chainid),
                PLAYER_IDX
            );
    }

    function getPlayer(
        address raffleAddr,
        uint256 idx
    ) public view returns (address) {
        Raffle raffle = Raffle(raffleAddr);
        return raffle.getPlayer(idx);
    }
}

contract RaffleGetRaffleState is Script {
    function run() external view returns (uint256) {
        return
            getRaffleState(
                DevOpsTools.get_most_recent_deployment("Raffle", block.chainid)
            );
    }

    function getRaffleState(address raffleAddr) public view returns (uint256) {
        Raffle raffle = Raffle(raffleAddr);
        return uint256(raffle.getRaffleState());
    }
}

contract RaffleGetLastTimestamp is Script {
    function run() external view returns (uint256) {
        return
            getLastTimestamp(
                DevOpsTools.get_most_recent_deployment("Raffle", block.chainid)
            );
    }

    function getLastTimestamp(
        address raffleAddr
    ) public view returns (uint256) {
        Raffle raffle = Raffle(raffleAddr);
        return raffle.getLastTimestamp();
    }
}

contract RaffleGetLastWinner is Script {
    function run() external view returns (address) {
        return
            getLastWinner(
                DevOpsTools.get_most_recent_deployment("Raffle", block.chainid)
            );
    }

    function getLastWinner(address raffleAddr) public view returns (address) {
        Raffle raffle = Raffle(raffleAddr);
        return raffle.getLastWinner();
    }
}
