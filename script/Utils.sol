// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { CREATE3Factory } from "lib/create3-factory/src/CREATE3Factory.sol";
import { BeaconProxyFactory } from "src/BeaconProxyFactory.sol";

/**
 * @dev A quick and dirty address organizer/network helper for foundry scripts. Nothing fancy here.
 */
contract Utils is Script {
    uint256 deployerPrivateKey;
    address deployer;

    // The create factory for the {ADD_DEPLOYER_ADDRESS_HERE} deployer
    CREATE3Factory internal _createFactory = CREATE3Factory(address(0xFc6a1C661b25f0B3613F86d16cc2F82f44D3612A)); // TODO: add address when deployed

    bytes32 internal _factorySalt = keccak256(bytes("FactoryDeployer1"));

    bytes32 internal _testWalletSalt = keccak256(bytes("TestWalletTestnet1"));

    // generated using the _createFactory + "FactoryDeployer1" salt for 0x.... deployer
    address internal _factoryAddress = address(0); // TODO: add address when deployed

    BeaconProxyFactory internal _factory = BeaconProxyFactory(payable(_factoryAddress));

    constructor() {
        if (isSepolia()) {
            deployerPrivateKey = vm.envUint("DEV_PRIVATE_KEY");
        }else{
            console2.log("Unsupported chain for script:", block.chainid);
            revert("unknown chain id");
        }
        deployer = vm.addr(deployerPrivateKey);
    }

    function isSepolia() public view returns (bool) {
        return block.chainid == 11155111;
    }

    function isLocalhost() public view returns (bool) {
        return block.chainid == 31337;
    }
}
