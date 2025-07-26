// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

struct DeployConfig {
    uint256 subscriptionId;
    bytes32 keyHash;
    address vrfCoordinator;
    uint256 entranceFee;
    uint256 interval;
    address account;
}

contract HelperScript is Script {
    uint96 BASE_FEE = 100000000000000000;
    uint96 GAS_PRICE = 1000000000;
    int256 WEI_PER_UNIT_LINK = 5100000000000000;
    uint256 SUB_LINK_AMOUNT = 100000000000000000000; // 100 LINK

    address LOCAL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function getConfig() external returns (DeployConfig memory config) {
        if (block.chainid == 11155111) {
            // Sepolia
            config = getSepoliaConfig();
        } else if (block.chainid == 1) {
            // Mainnet
            config = getMainnetConfig();
        } else {
            // Local
            config = getLocalConfig();
        }
        return config;
    }

    function getSepoliaConfig() private pure returns (DeployConfig memory) {
        return
            DeployConfig({
                subscriptionId: 12814486929142725393229811669122259502591729219768396775393081737442593506491,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                entranceFee: 1e14,
                interval: 60,
                account: 0x198d3CBa89DF37870778453685DC53421D7E0786
            });
    }

    function getLocalConfig() private returns (DeployConfig memory) {
        vm.startBroadcast(LOCAL_DEFAULT_ACCOUNT);
        VRFCoordinatorV2_5Mock coordinator = new VRFCoordinatorV2_5Mock(
            BASE_FEE,
            GAS_PRICE,
            WEI_PER_UNIT_LINK
        );
        uint256 subId = coordinator.createSubscription();
        coordinator.fundSubscription(subId, SUB_LINK_AMOUNT);
        vm.stopBroadcast();

        return
            DeployConfig({
                subscriptionId: subId,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                vrfCoordinator: address(coordinator),
                entranceFee: 1e18,
                interval: 20,
                account: LOCAL_DEFAULT_ACCOUNT
            });
    }

    function getMainnetConfig() private pure returns (DeployConfig memory) {}
}
