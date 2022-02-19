//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "./EIP712Types.sol";

contract LOB {
    /// Create a new XBR market for a member. The member must be XBR network member, must have signed the
    /// transaction data, and will become owner of the new market.
    ///
    /// Note: This version uses pre-signed data where the actual blockchain transaction is
    /// submitted by a gateway paying the respective gas (in ETH) for the blockchain transaction.
    ///
    function open_lob_for(address member, uint256 created, bytes16 marketId, address coin,
        string memory terms, string memory meta, address maker, uint256 providerSecurity, uint256 consumerSecurity,
        uint256 marketFee, bytes memory signature) public {
    }

    function close_lob() public {
    }
}
