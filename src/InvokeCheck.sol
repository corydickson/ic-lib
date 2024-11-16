// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
library InvokeCheck {
    /**
     * @notice Checks if arbitrary calldata has a 4-byte function selector
     * @param data The calldata to be compared
     * @param selector The 4-byte function selector e.g. bytes4(keccak256(foobar(uint)))
     */
    function has_selector(bytes calldata data, bytes4 selector) public pure {
        assembly {
            // mask all bytes after the first 4
            let func := or(calldataload(data.offset), 0xffffffffffffffffffffffffffffffffffffffff)
            selector := or(selector, 0xffffffffffffffffffffffffffffffffffffffff)

            let valid := eq(func, selector)
            if iszero(valid) { revert (0,0) }
        }
    }
}
