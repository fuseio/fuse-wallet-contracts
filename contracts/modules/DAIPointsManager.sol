pragma solidity ^0.5.4;
import "../wallet/BaseWallet.sol";
import "./common/BaseModule.sol";
import "./common/RelayerModule.sol";
import "./common/OnlyOwnerModule.sol";

contract DAIPointsManager is BaseModule, RelayerModule, OnlyOwnerModule {
  bytes32 constant NAME = "DAIPointsManager";
  address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address constant DAI_POINTS = 0x782c578B5BC3b9A1B6E1E54f839B610Ac7036bA0;

  constructor(
    ModuleRegistry _registry
  )
    BaseModule(_registry, NAME)
    public
  {
  }

  function getDAIPoints(
    BaseWallet _wallet,
    uint256 _amount
  )
    external
    onlyWalletOwner(_wallet)
  {
    _wallet.invoke(DAI, 0, abi.encodeWithSignature("approve(address,uint256)", DAI_POINTS, _amount));
    _wallet.invoke(DAI_POINTS, 0, abi.encodeWithSignature("getDAIPoints(uint256)", _amount));
  }

  function getDAIPointsToAddress(
    BaseWallet _wallet,
    uint256 _amount,
    address _recipient
  )
    external
    onlyWalletOwner(_wallet)
  {
    _wallet.invoke(DAI, 0, abi.encodeWithSignature("approve(address,uint256)", DAI_POINTS, _amount));
    _wallet.invoke(DAI_POINTS, 0, abi.encodeWithSignature("getDAIPointsToAddress(uint256,address)", _amount, _recipient));
  }
}
