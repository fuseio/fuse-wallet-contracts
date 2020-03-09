pragma solidity ^0.5.4;
import "./TransferManager.sol";
import "../utils/CommunityUtils.sol";

contract CommunityTransferManager is TransferManager {
  bytes32 constant NAME = "CommunityTransferManager";

  uint256 public constant DECIMALS = 10 ** 18;

    // *************** Constructor ********************** //

    constructor(
      ModuleRegistry _registry,
      TransferStorage _transferStorage,
      GuardianStorage _guardianStorage,
      address _priceProvider,
      uint256 _securityPeriod,
      uint256 _securityWindow,
      uint256 _defaultLimit
    ) TransferManager(
      _registry, _transferStorage, _guardianStorage, _priceProvider, _securityPeriod, _securityWindow, _defaultLimit, LimitManager(address(0)))
      public
    {

    }
    // *************** External/Public Functions ********************* //

    /**
    * @dev lets the owner transfer tokens (ETH or ERC20) from a wallet.
    * @param _wallet The target wallet.
    * @param _token The address of the token to transfer.
    * @param _to The destination address
    * @param _amount The amoutn of token to transfer
    * @param _data The data for the transaction
    */
    function transferToken(
        BaseWallet _wallet,
        address _token,
        address _to,
        uint256 _amount,
        address _community,
        address _communityAdmin,
        address _networkAdmin,
        uint256 _cashbackPercentage,
        uint256 _adminFeePercentage,
        uint256 _networkFeePercentage,
        bytes32 _roleToCheck,
        bytes calldata _data
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
      if (CommunityUtils.hasRoles(_community, _to, _roleToCheck)) {
        uint256 cashback = _amount.sub(_amount.mul(DECIMALS - _cashbackPercentage).div(DECIMALS));
        uint256 adminFee = _amount.sub(_amount.mul(DECIMALS - _adminFeePercentage).div(DECIMALS));
        uint256 networkFee = _amount.sub(_amount.mul(DECIMALS - _networkFeePercentage).div(DECIMALS));

        doTransfer(_wallet, _token, _communityAdmin, adminFee, _data);
        doTransfer(_wallet, _token, _networkAdmin, networkFee, _data);
        doTransfer(_wallet, _token, _to, _amount - cashback - adminFee - networkFee, _data);
      } else {
        doTransfer(_wallet, _token, _communityAdmin, _amount, _data);
      }
    }
}