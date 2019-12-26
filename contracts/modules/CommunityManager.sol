pragma solidity ^0.5.4;
import "../wallet/BaseWallet.sol";
import "./common/BaseModule.sol";
import "./common/RelayerModule.sol";
import "./common/OnlyOwnerModule.sol";

contract CommunityManager is BaseModule, RelayerModule, OnlyOwnerModule {
  bytes32 constant NAME = "CommunityManager";

  event Debug(uint256 indexed n);

  constructor(
    ModuleRegistry _registry
  )
    BaseModule(_registry, NAME)
    public
  {
  }

  function joinCommunity(
    BaseWallet _wallet,
    address _community
  )
    external
    onlyWalletOwner(_wallet)
  {
    emit Debug(200);
    _wallet.invoke(_community, 0, abi.encodeWithSignature("join()"));
    emit Debug(201);
  }
}
