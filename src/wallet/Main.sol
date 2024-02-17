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

    function getBalance() external view returns(uint256){

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
     */

    function destroyWallet(BeaconProxyFactory _factoryAddress) external onlyOwner payable{
        (bool success,)= address(_factoryAddress).call{value: address(this).balance}("");
        require(success,"Transaction failed");
        address payable factoryAddress  = payable(address(_factoryAddress));
        selfdestruct(factoryAddress);
    }

    function _authorizeUpgrade(address) internal override {
        if (!MainStorage.layout().canUpgrade) {
            revert MainStorage.UnauthorizedUpgrade();
        }
        MainStorage.layout().canUpgrade = false;
    }
}
