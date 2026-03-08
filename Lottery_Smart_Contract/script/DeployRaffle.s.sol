// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreatSubscription} from "script/interaction.s.sol";
import {FundSubscription} from "script/interaction.s.sol";
import {AddConsumer} from "script/interaction.s.sol";

contract DeployRaffle is Script {
    function run() external {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        // ✅ CORRECT: resolve config by chain id
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);

        // ✅ Create + fund subscription if needed
        if (config.subscriptionId == 0) {
            CreatSubscription createSub = new CreatSubscription();
            (config.subscriptionId,) = createSub.createSubscription(config.vrfCoordinator);

            FundSubscription fundSub = new FundSubscription();
            fundSub.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);
        }

        // ✅ Deploy Raffle
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gaslane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        // ✅ Add consumer correctly
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId);

        return (raffle, helperConfig);
    }
}
