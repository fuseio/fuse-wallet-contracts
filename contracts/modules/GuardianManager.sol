pragma solidity ^0.5.4;
import "../wallet/BaseWallet.sol";
import "../utils/GuardianUtils.sol";
import "../storage/GuardianStorage.sol";
import "./common/BaseModule.sol";
import "./common/RelayerModule.sol";

/**
 * @title GuardianManager
 * @dev Module to manage the guardians of wallets.
 * Guardians are accounts (EOA or contracts) that are authorized to perform specific 
 * security operations on wallets such as toggle a safety lock, start a recovery procedure,
 * or confirm transactions. Addition or revokation of guardians is initiated by the owner 
 * of a wallet and must be confirmed after a security period (e.g. 24 hours).
 * The list of guardians for a wallet is stored on a saparate
 * contract to facilitate its use by other modules.
 * @author Julien Niset - <julien@argent.im>
 * @author Olivier Van Den Biggelaar - <olivier@argent.im>
 */
contract GuardianManager is BaseModule, RelayerModule {

    bytes32 constant NAME = "GuardianManager";

    bytes4 constant internal CONFIRM_ADDITION_PREFIX = bytes4(keccak256("confirmGuardianAddition(address,address)"));
    bytes4 constant internal CONFIRM_REVOKATION_PREFIX = bytes4(keccak256("confirmGuardianRevokation(address,address)"));

    // the address of the Guardian storage 
    GuardianStorage public guardianStorage;

    // *************** Events *************************** //
    event GuardianAdded(address indexed wallet, address indexed guardian);
    event GuardianRevoked(address indexed wallet, address indexed guardian);
    
    // *************** Modifiers ************************ //

    /**
     * @dev Throws if the wallet is not locked.
     */
    modifier onlyWhenLocked(BaseWallet _wallet) {
        // solium-disable-next-line security/no-block-members
        require(guardianStorage.isLocked(_wallet), "GM: wallet must be locked");
        _;
    }

    /**
     * @dev Throws if the wallet is locked.
     */
    modifier onlyWhenUnlocked(BaseWallet _wallet) {
        // solium-disable-next-line security/no-block-members
        require(!guardianStorage.isLocked(_wallet), "GM: wallet must be unlocked");
        _;
    }

    // *************** Constructor ********************** //

    constructor(
        ModuleRegistry _registry,
        GuardianStorage _guardianStorage
    )
        BaseModule(_registry, NAME)
        public
    {
        guardianStorage = _guardianStorage;
    }

    // *************** External Functions ********************* //

    /**
     * @dev Lets the owner add a guardian to its wallet.
     * The first guardian is added immediately. All following additions must be confirmed
     * by calling the confirmGuardianAddition() method.
     * @param _wallet The target wallet.
     * @param _guardian The guardian to add.
     */
    function addGuardian(BaseWallet _wallet, address _guardian) external onlyWalletOwner(_wallet) onlyWhenUnlocked(_wallet) {
        require(!isOwner(_wallet, _guardian), "GM: target guardian cannot be owner");
        require(!isGuardian(_wallet, _guardian), "GM: target is already a guardian");
        // Guardians must either be an EOA or a contract with an owner()
        // method that returns an address with a 5000 gas stipend.
        // Note that this test is not meant to be strict and can be bypassed by custom malicious contracts.
        // solium-disable-next-line security/no-low-level-calls
        (bool success,) = _guardian.call.gas(5000)(abi.encodeWithSignature("owner()"));
        require(success, "GM: guardian must be EOA or implement owner()");
        guardianStorage.addGuardian(_wallet, _guardian);
        emit GuardianAdded(address(_wallet), _guardian);
    }

    /**
     * @dev Lets the owner revoke a guardian from its wallet.
     * Revokation must be confirmed by calling the confirmGuardianRevokation() method.
     * @param _wallet The target wallet.
     * @param _guardian The guardian to revoke.
     */
    function revokeGuardian(BaseWallet _wallet, address _guardian) external onlyWalletOwner(_wallet) {
        require(isGuardian(_wallet, _guardian), "GM: must be an existing guardian");
        bytes32 id = keccak256(abi.encodePacked(address(_wallet), _guardian, "revokation"));
        guardianStorage.revokeGuardian(_wallet, _guardian);
        emit GuardianRevoked(address(_wallet), _guardian);
    }

    /**
     * @dev Checks if an address is a guardian for a wallet.
     * @param _wallet The target wallet.
     * @param _guardian The address to check.
     * @return true if the address if a guardian for the wallet.
     */
    function isGuardian(BaseWallet _wallet, address _guardian) public view returns (bool _isGuardian) {
        (_isGuardian, ) = GuardianUtils.isGuardian(guardianStorage.getGuardians(_wallet), _guardian);
    }

    /**
     * @dev Counts the number of active guardians for a wallet.
     * @param _wallet The target wallet.
     * @return the number of active guardians for a wallet.
     */
    function guardianCount(BaseWallet _wallet) external view returns (uint256 _count) {
        return guardianStorage.guardianCount(_wallet);
    }

    /**
     * @dev Get the active guardians for a wallet.
     * @param _wallet The target wallet.
     * @return the active guardians for a wallet.
     */
    function getGuardians(BaseWallet _wallet) external view returns (address[] memory _guardians) {
        return guardianStorage.getGuardians(_wallet);
    }

    // *************** Implementation of RelayerModule methods ********************* //

    // Overrides to use the incremental nonce and save some gas
    function checkAndUpdateUniqueness(BaseWallet _wallet, uint256 _nonce, bytes32 /* _signHash */) internal returns (bool) {
        return checkAndUpdateNonce(_wallet, _nonce);
    }

    function validateSignatures(
        BaseWallet _wallet,
        bytes memory /* _data */,
        bytes32 _signHash,
        bytes memory _signatures
    )
        internal
        view
        returns (bool)
    {
        address signer = recoverSigner(_signHash, _signatures, 0);
        return isOwner(_wallet, signer); // "GM: signer must be owner"
    }

    function getRequiredSignatures(BaseWallet /* _wallet */, bytes memory _data) internal view returns (uint256) {
        bytes4 methodId = functionPrefix(_data);
        if (methodId == CONFIRM_ADDITION_PREFIX || methodId == CONFIRM_REVOKATION_PREFIX) {
            return 0;
        }
        return 1;
    }
}