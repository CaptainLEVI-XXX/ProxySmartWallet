// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import { BeaconProxyFactory } from "src/BeaconProxyFactory.sol";
import { Main } from "src/wallet/Main.sol";

import { Utils } from "script/Utils.sol";

/**
 * @dev Deploys a new  Wallet Factory contract using the CREATE3Factory previously deployed.
 */
contract WalletFactoryDeployer is Script, Utils {
    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        console2.log("Deploying Factory to -->", _createFactory.getDeployed(deployer, _factorySalt));

        // Create a BeaconProxyFactory with the Main contract as the beacon implementation.
        // This will cause the deployed factory to only deploy Main contracts pointing to this initial
        // UpgradeableBeacon deployment.
        // Main is the wallet contract with all desired features attached.
        address newFactoryAddr = _createFactory.deploy(
            _factorySalt, abi.encodePacked(type(BeaconProxyFactory).creationCode, abi.encode(address(new Main())))
        );
        console2.log("Factory deployed -->", newFactoryAddr);
        console2.log("Factory beacon address -->", BeaconProxyFactory(payable(newFactoryAddr)).beacon());
        vm.stopBroadcast();
    }
}
