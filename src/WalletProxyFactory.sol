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

    struct walletInfo{
        uint256 amountDeposited;
        mapping(address=>bool) isActiveAddress;
    }
    mapping(address=>walletInfo) public ownerToWalletInfo;

    event ContractDeployed(address indexed contractAddress, bool indexed wasSigned);

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
     */
    constructor(address _walletImpl) {
        if (_walletImpl == address(0)) {
            revert WalletImplInvalid();
        }

        latestWalletImplementation = _walletImpl;
    }

    receive() external payable{}

    /**
     * @dev Deploys a new WalletProxy contract based on the salt provided and the caller of the contract.
     * @param _userSalt The salt to use for the deterministic address calculation. Gets concatenated with the caller address.
     */
    function createProxy(bytes32 _userSalt, address _walletOwner) external returns (address createdContract_) {
        createdContract_ = _create(getSalt(_walletOwner, _userSalt));

        IMain(createdContract_).initialize(_walletOwner);
        // storing the deployed wallet Information in struct Datatype;
        walletInfo storage wallet = ownerToWalletInfo[_walletOwner];
        wallet.isActiveAddress[createdContract_] = true;
        // ownerToWalletInfo[_walletOwner]=wallet;

        emit ContractDeployed(createdContract_, false);
    }


    /**
     * @dev Deploys a new WalletProxy contract based on the salt provided and the caller of the contract.
     * @param _userSalt The salt to use for the deterministic address calculation. Gets concatenated with the caller address.
     */
    function destroyAndReDeployWallet(address _walletOwner,bytes32 _userSalt) public payable{
        walletInfo storage wallet = ownerToWalletInfo[_walletOwner];
        require(wallet.isActiveAddress[msg.sender],"Not a valid Owner of any of the deployed contract");  
        wallet.amountDeposited = wallet.amountDeposited + msg.value;
        wallet.isActiveAddress[msg.sender] = false;
        
        address createdContract  = _create(getSalt(_walletOwner, _userSalt));
        wallet.isActiveAddress[createdContract] =true;

        uint256 valueSend = wallet.amountDeposited;
        wallet.amountDeposited = 0;
        (bool success ,) = createdContract.call{value : valueSend }("");
        require(success, "Transaction failed");
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
