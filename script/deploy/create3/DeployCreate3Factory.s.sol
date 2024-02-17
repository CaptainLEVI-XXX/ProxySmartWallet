// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { CREATE3Factory } from "lib/create3-factory/src/CREATE3Factory.sol";

import { Utils } from "script/Utils.sol";

/**
 * @dev Deploys a new CREATE3Factory contract.
 */
contract DeployScript is Script, Utils {
    function run() public returns (CREATE3Factory factory) {
        vm.startBroadcast(deployerPrivateKey);

        factory = new CREATE3Factory();

        vm.stopBroadcast();
    }
}

//forge script script/deploy/create3/DeployCreate3Factory.s.sol --fork-url https://sepolia.infura.io/v3/0ba109fff3bd45b19289ee08e0ed03de --broadcast
