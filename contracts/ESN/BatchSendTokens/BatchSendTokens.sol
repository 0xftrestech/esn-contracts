// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Contract for sending any ERC20 tokens to lots of addresses in batches quickly and efficiently
/// @author The EraSwap Team
/// @notice Due to Ethereum block gas limitations, you can send about 200 in one transaction.
/// @dev For using, you can approve this contract for all the batches amount once and then send individual batches.
contract BatchSendTokens {
    /// @notice This function is more suitable when you have same amount to send to multiple addresses
    /// @param token - address of ERC20 token contract on which transfer transactions need to be sent
    /// @param addressArray - address to whom tokens will be sent
    /// @param amountToEachAddress - amount of tokens which will be sent to all addresses in addressArray
    /// @param totalAmount - amount of total tokens in one batch
    /// @dev Please note that you have to approve this contract as spender for the totalAmount tokens
    function sendErc20BySameAmount(
        IERC20 token,
        address[] memory addressArray,
        uint256 amountToEachAddress,
        uint256 totalAmount
    ) public {
        token.transferFrom(msg.sender, address(this), totalAmount);
        uint256 lengthOfArray = addressArray.length;
        for (uint256 i = 0; i < lengthOfArray; i++) {
            token.transfer(addressArray[i], amountToEachAddress);
        }
    }

    /// @notice This function is more suitable when you have different amounts to send to multiple addresses
    /// @param token - address of ERC20 token contract on which transfer transactions need to be sent
    /// @param addressArray - address to whom tokens will be sent
    /// @param amountArray - amount that will be sent to addressArray in order
    /// @param totalAmount - amount of total tokens in one batch
    /// @dev Please note that you have to approve this contract as spender for the totalAmount tokens
    function sendErc20ByDifferentAmount(
        IERC20 token,
        address[] memory addressArray,
        uint256[] memory amountArray,
        uint256 totalAmount
    ) public {
        token.transferFrom(msg.sender, address(this), totalAmount);
        uint256 lengthOfArray = addressArray.length;
        for (uint256 i = 0; i < lengthOfArray; i++) {
            token.transfer(addressArray[i], amountArray[i]);
        }
    }

    function sendNativeByDifferentAmount(
        address[] memory addressArray,
        uint256[] memory amountArray
    ) public payable {
        uint256 lengthOfArray = addressArray.length;
        for (uint256 i = 0; i < lengthOfArray; i++) {
            (bool _success, ) = addressArray[i].call{ value: amountArray[i] }("");
            require(_success, "BST: Native transfer failing");
        }

        if (address(this).balance > 0) {
            (bool _success, ) = msg.sender.call{ value: address(this).balance }("");
            require(_success, "BST: Native change return failing");
        }
    }
}
