// SPDX-License-Identifier: Commons-Clause-1.0
pragma solidity ^0.8.13;

import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { MainStorage } from "./MainStorage.sol";
import { IMain } from "src/interfaces/IMain.sol";
import {BeaconProxyFactory} from "src/BeaconProxyFactory.sol";

contract Main is
    IMain,
    UUPSUpgradeable,
    Initializable
   
{
    address public admin;

    receive() external payable virtual { }

    /**
     * @dev Initialize the contract.
     * @param _admin The address of the controller to add.
     **/
    function initialize(address _admin) external initializer {
        admin = _admin;
    }

    modifier onlyOwner(){
        require(msg.sender == admin,"You are Not admin");
        _; 
    }
     /**
     *
     * @dev Get the current Balance of the Smart wallet.
     */

    function getbalance() external view returns(uint256){

        return address(this).balance;

    }
     /**
     *
     * @dev Send the Funds to a user.
     * @param _amount amount admin want to transfer.
     * @param _receiver receiver of the Funds.
     */

    function sendFunds(uint256 _amount, address _receiver) external payable onlyOwner{
       
        require(_amount<=address(this).balance, " Wallet doest not have enough balance");
        (bool success, ) = _receiver.call{ value: _amount }("");
        require(success, "Transction failed");

    }
     /**
     *
     * @dev Destroy the wallet before depositing the amount to BEaconProxy contract. 
     * @param _factoryAddress The address of the new logic contract for the proxy.
     * @param _userSalt Optional calldata to invoke against the implementation contract after upgrading.
     */

    function destroyWallet(BeaconProxyFactory _factoryAddress, bytes32 _userSalt) external onlyOwner payable{
        _factoryAddress.destroyAndReDeployWallet(msg.sender,_userSalt);
        address payable factoryAddress  = payable(address(_factoryAddress));
        selfdestruct(factoryAddress);
    }

    // /**
    //  *
    //  * @dev Upgrade the implementation of the wallet contract. Must be called from the wallet's proxy and only when
    //  *      there is sufficient controlling signatures to meet the threshold.
    //  * @param newImplementation The address of the new logic contract for the proxy.
    //  * @param data Optional calldata to invoke against the implementation contract after upgrading.
    //  */
    // function upgradeToAndCall(
    //     address newImplementation,
    //     bytes calldata data
    // )
    //     external 
    //     payable
    //     virtual
    //     onlyProxy
    // {
    //     MainStorage.layout().canUpgrade = true;
    //     upgradeToAndCall(newImplementation, data);
    //     // Should already be set but just to be safe
    //     MainStorage.layout().canUpgrade = false;
    // }

    function _authorizeUpgrade(address) internal override {
        if (!MainStorage.layout().canUpgrade) {
            revert MainStorage.UnauthorizedUpgrade();
        }
        MainStorage.layout().canUpgrade = false;
    }
}
