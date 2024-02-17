// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

pragma solidity ^0.8.13;

import { TestBase } from "./utils/TestBase.sol";

import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import { BeaconProxyFactory } from "src/BeaconProxyFactory.sol";
import { Main, IMain } from "src/wallet/Main.sol";

import "forge-std/console.sol";

contract WalletAndFunds is TestBase {
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
        _beacon = UpgradeableBeacon(_factory.beacon());
    }


    function test_Checking_factoryBalanceAfterDestroyingWallet() public {
        vm.startPrank(msg.sender);
        deal(address(_wallet1),5 ether);
        _wallet1.destroyWallet(_factory);
        assertEq(address(_factory).balance, 5 ether);
        vm.stopPrank();
    }


    function test_checkAddressBYbalance() public{
        vm.startPrank(msg.sender);
        deal(address(_wallet1),5 ether);
        _wallet1.destroyWallet(_factory);
        assertEq(5 ether,address(_factory).balance);
        uint256 amounta = _factory.getBalance(address(msg.sender));
        assertEq(5 ether, amounta);
        assertEq(0 ether, _factory.getBalance(address(_wallet1)));
        vm.stopPrank();

    }

    function test_BalanceOfRedeployedAddress() public {
        vm.startPrank(msg.sender);
        deal(address(_wallet1),10 ether);
        _wallet1.destroyWallet(_factory);
        _wallet2 = Main(payable(_factory.createProxy(_wallet2Salt,msg.sender)));
        assertEq(10 ether, address(_wallet2).balance);
        vm.stopPrank();
    } 


}