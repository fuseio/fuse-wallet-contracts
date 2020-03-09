pragma solidity ^0.5.4;

library CommunityUtils {
  function hasRoles(address _communityAddress, address _account, bytes32 _entityRoles) internal view returns (bool) {
    (bool success, bytes memory result) = _communityAddress.staticcall(
      abi.encodeWithSignature('hasRoles(address,bytes32)', _account, _entityRoles));
    if(success && result[0] != 0x0) return true;
  }
}