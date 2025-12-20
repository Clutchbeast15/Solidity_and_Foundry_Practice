// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script} from "forge-std/Script.sol";
import {ERC20Token} from "../src/ERC20Token.sol";

contract DeployERC20 is Script {
    function run() external {
        vm.startBroadcast();

        new ERC20Token(
            "MyToken", // name
            "MTK", // symbol
            18 // decimals
        );

        vm.stopBroadcast();
    }
}
