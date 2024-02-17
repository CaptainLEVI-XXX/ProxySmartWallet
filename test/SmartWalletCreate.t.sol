// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { TestBase } from "./utils/TestBase.sol";

import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import { BeaconProxyFactory } from "src/BeaconProxyFactory.sol";
import { Main, IMain } from "src/wallet/Main.sol";

import "forge-std/console.sol";

contract MainImpl is Main {
    function isNew() public pure returns (bool) {
        return false;
    }
}

contract MainImplNew is Main {
    function isNew() public pure returns (bool) {
        return true;
    }
}

contract BeaconUpgradesTest is TestBase {
    BeaconProxyFactory _factory;
    Main _wallet1;
    Main _wallet2;
    bytes32 _wallet1Salt = keccak256(bytes("_wallet1"));
    bytes32 _wallet2Salt = keccak256(bytes("_wallet2"));
    UpgradeableBeacon _beacon;
    uint256 amount = 1 ether;

    function setUp() public {
        _factory = new BeaconProxyFactory(address(new Main()));
        _wallet1 = Main(payable(_factory.createProxy(_wallet1Salt,msg.sender)));
        _wallet2 = Main(payable(_factory.createProxy(_wallet2Salt,address(2))));
        _beacon = UpgradeableBeacon(_factory.beacon());
    }

    function testSendEth() public {
        (bool success, ) = address(_wallet1).call{value :amount}("");
        require(success,"Transaction failed");
        assertEq(1 ether, address(_wallet1).balance);

    }

    function testSendEthFromWallet1ToWallet2() public {
        deal(address(_wallet1),5 ether);
        assertEq(5 ether, address(_wallet1).balance);
        vm.prank(msg.sender);
        _wallet1.sendFunds(2 ether, payable(_wallet2)); 
        assertEq(2 ether, address(_wallet2).balance);
        assertEq(3 ether, address(_wallet1).balance);
        vm.prank(address(2));
        _wallet2.sendFunds(1 ether, payable(_wallet1));
        assertEq(1 ether, address(_wallet2).balance);
        assertEq(4 ether, address(_wallet1).balance);
    }

    function testBalanceofWallet() public {
        assertEq(0,address(_wallet2).balance);
    }

    // function testChangeBeaconUpdatesSingleProxy() public {
    //     assertFalse(_wallet1.isNew());
    //     MainImplNew _newImpl = new MainImplNew();
    //     _beacon.upgradeTo(address(_newImpl));
    //     assertTrue(_wallet1.isNew());
    // }

    // function testChangingBeaconUpdatesManyProxies() public {
    //     assertFalse(_wallet1.isNew());
    //     assertFalse(_wallet2.isNew());
    //     MainImplNew _newImpl = new MainImplNew();
    //     _beacon.upgradeTo(address(_newImpl));
    //     assertTrue(_wallet1.isNew());
    //     assertTrue(_wallet2.isNew());
    // }
}
