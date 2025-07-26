// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperScript, DeployConfig} from "script/HelperScript.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, DeployConfig memory) {
        DeployConfig memory deployConfig = new HelperScript().getConfig();
        vm.startBroadcast(deployConfig.account);
        Raffle raffle = new Raffle(
            deployConfig.entranceFee,
            deployConfig.interval,
            deployConfig.subscriptionId,
            deployConfig.keyHash,
            deployConfig.vrfCoordinator
        );

        VRFCoordinatorV2_5Mock(deployConfig.vrfCoordinator).addConsumer(
            deployConfig.subscriptionId,
            address(raffle)
        );
        vm.stopBroadcast();

        return (raffle, deployConfig);
    }
}
