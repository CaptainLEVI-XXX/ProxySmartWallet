// SPDX-License-Identifier: Commons-Clause-1.0
pragma solidity ^0.8.13;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IMain } from "src/interfaces/IMain.sol";

interface IWalletProxyFactory {
    function latestWalletImplementation() external view returns (address);
}

/**
 * @dev This contract wraps the proxy contract to allow for constructor-less creation to make address calculating easier/more expected.
 */
contract FactoryCreatedUUPSProxy is ERC1967Proxy {
    constructor() ERC1967Proxy(IWalletProxyFactory(msg.sender).latestWalletImplementation(), "") { }
}

contract WalletProxyFactory {
    bytes32 public constant proxyHash = keccak256(type(FactoryCreatedUUPSProxy).creationCode);
    bytes32 private constant PROOF_MESSAGE = keccak256("Approve wallet creation");

    mapping(address=>uint256) private amountByAddress;

    event ContractDeployed(address indexed contractAddress, bool indexed wasRedeployed);

    error WalletProxyDeployFailed();
    error WalletImplInvalid();

    /**
     * @dev Having this reference allows WalletProxy contracts to be created without requiring the
     *   implementation contract address constructor argument, which makes it easier to calculate the proxy wallet address
     */
    address public latestWalletImplementation;

    /**
     * @dev Initialize the contract. Sets the initial implementation address.
     * @param _walletImpl The address of the implementation contract to use for the WalletProxy.
     **/
    constructor(address _walletImpl) {
        if (_walletImpl == address(0)) {
            revert WalletImplInvalid();
        }

        latestWalletImplementation = _walletImpl;
    }

    receive() external payable{
        amountByAddress[tx.origin] =  amountByAddress[tx.origin] + msg.value;
    }

    /**
     * @dev Deploys a new WalletProxy contract based on the salt provided and the caller of the contract.
     * @param _userSalt The salt to use for the deterministic address calculation. Gets concatenated with the caller address.
     * @param _walletOwner Owner of the Smart Wallet .
     */
    function createProxy(bytes32 _userSalt, address _walletOwner) external returns (address createdContract_) {
       
        createdContract_ = _create(getSalt(_walletOwner, _userSalt));
        IMain(createdContract_).initialize(_walletOwner);
       
        if(amountByAddress[_walletOwner] > 0){
           
            uint256 valueSend = amountByAddress[_walletOwner];
            amountByAddress[_walletOwner] = 0;
            (bool success ,) = createdContract_.call{value : valueSend }("");
            require(success, "Transaction failed");

            emit ContractDeployed(createdContract_, true);

        }else{

            emit ContractDeployed(createdContract_, false);
        }
    }
     function getBalance(address _a) public view returns(uint256){
        return amountByAddress[_a];
    }


    /**
     * @dev Returns an address-combined salt for the deterministic address calculation.
     */
    function getSalt(address _user, bytes32 _userSalt) public pure returns (bytes32) {
        return keccak256(abi.encode(_user, _userSalt));
    }

    /**
     * @dev Calculates the expected address of a WalletProxy contract based on the salt provided without combining an address.
     */
    function calculateExpectedAddress(bytes32 _salt) public view returns (address expectedAddress_) {
        expectedAddress_ = Create2.computeAddress(_salt, proxyHash, address(this));
    }

    /**
     * @dev Calculates the expected address of a WalletProxy contract based on the salt provided and a given address.
     */
    function calculateExpectedAddress(
        address _user,
        bytes32 _userSalt
    ) public view returns (address expectedAddress_) {
        expectedAddress_ = calculateExpectedAddress(getSalt(_user, _userSalt));
    }

    /**
     * @dev Deploys a new WalletProxy contract based on the salt provided and the caller of the contract.
     * @param _salt The salt to use for the deterministic address calculation.
     */
    function _create(bytes32 _salt) public returns (address createdContract_) {
        createdContract_ = address(new FactoryCreatedUUPSProxy{ salt: _salt }());
        // If the latestWalletImplementation proxy fails to deploy, it will return address(0)
        if (createdContract_ == address(0)) {
            revert WalletProxyDeployFailed();
        }
    }
}
