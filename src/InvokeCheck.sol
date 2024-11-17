// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library InvokeCheck {
    enum Comparators {
        EMPTY, // Do nothing
        EQUAL,
        LESS_THAN,
        GREATER_THAN
    }

    enum Types {
        // Static Types
        UINTM, // 0 < M <= 256, M % 8 == 0
        INTM, // 0 < M <= 256, M % 8 == 0
        ADDRESS,
        BOOL,
        FIXEDMXN, // 8 <= M <= 256, M % 8 == 0, and 0 < N <= 80
        UFIXEDMXN, // 8 <= M <= 256, M % 8 == 0, and 0 < N <= 80
        BYTESM, // 0 < M <= 32
        FUNCTION,
        // Dynamic Types
        BYTES,
        STRING,
        TYPES
    }

    struct Parameter {
        bytes value; // The value to be checked at calldata position
        Types paramType; // The type of the parameter
    }

    struct Condition {
        bytes4 selector; // 4-byte function selector
        Parameter[] params; // List of all the parameters
        Comparators[] comps; // List of how they should be compared
    }

    /**
     * @notice Checks if arbitrary calldata has a 4-byte function selector
     * @param data The calldata to be compared
     * @param selector The 4-byte function selector e.g. bytes4(keccak256(foobar(uint)))
     */
    function hasSelector(bytes calldata data, bytes4 selector) public pure {
        assembly {
            // mask all bytes after the first 4
            let func := or(calldataload(data.offset), 0xffffffffffffffffffffffffffffffffffffffff)
            selector := or(selector, 0xffffffffffffffffffffffffffffffffffffffff)

            let valid := eq(func, selector)
            if iszero(valid) { revert(0, 0) }
        }
    }

    function checkUint(bytes memory paramData, bytes memory param, Comparators comp) internal pure {
        bytes memory v;
        assembly {
            // flip the bits for the encoded value
            // see: https://github.com/k06a/bitcoin-spv/blob/4513aea2336d84a635daecaa124a4b63ee74b212/solidity/contracts/BTCUtils.sol
            v := param
            v :=
                or(
                    and(shr(8, v), 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF),
                    shl(8, and(v, 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF))
                )
            v :=
                or(
                    and(shr(16, v), 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF),
                    shl(16, and(v, 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF))
                )
            v :=
                or(
                    and(shr(32, v), 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF),
                    shl(32, and(v, 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF))
                )
            v :=
                or(
                    and(shr(64, v), 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF),
                    shl(64, and(v, 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF))
                )
            v := or(shr(128, v), shl(128, v))

            let valid
            switch comp
            case 1 { valid := eq(paramData, v) }
            case 2 { valid := lt(v, paramData) }
            case 3 { valid := gt(v, paramData) }
            if iszero(valid) { revert(0, 0) }
        }
    }

    function checkParam(bytes memory paramData, Parameter memory limit, Comparators comp) internal pure {
        if (limit.paramType == Types.UINTM) {
            checkUint(paramData, limit.value, comp);
        }

        /*
               || params[i].paramType == Types.INTM
               || params[i].paramType == Types.ADDRESS
               || params[i].paramType == Types.BOOL
               || params[i].paramType == Types.FIXEDMXN
               || params[i].paramType == Types.UFIXEDMXN
               || params[i].paramType == Types.BYTESM
              ) {
              */
    }

    function validateParams(bytes calldata data, Parameter[] memory params, Comparators[] memory comps) internal pure {
        uint256 startIdx = 4;
        uint256 endIdx = startIdx;
        for (uint8 i = 0; i < params.length; i++) {
            // Handle static types
            if (
                params[i].paramType == Types.UINTM || params[i].paramType == Types.INTM
                    || params[i].paramType == Types.ADDRESS || params[i].paramType == Types.BOOL
                    || params[i].paramType == Types.FIXEDMXN || params[i].paramType == Types.UFIXEDMXN
                    || params[i].paramType == Types.BYTESM
            ) {
                endIdx = endIdx + 32;
            } else { // Handle dynamic types
                    // checkPrefix
            }

            checkParam(data[startIdx:endIdx], params[i], comps[i]);
            startIdx = endIdx;

            // notes:
            // if it's a static type we can just take the length of the provided parameter value and update the index
            // get it's type and do the correct type of check
            // if not, we have to check the prefix of the calldata param and make sure it matches the prefix of the condition param
            // if it matches we compare the values
            // get it's type and do the correct type of check to see if it's equal only(?)
            // if not, we revert
        }
    }

    function satisfiesCondition(bytes calldata data, Condition memory cond) public pure {
        require(cond.params.length == cond.comps.length); // Ensure there's a comparator for each param
        hasSelector(data, cond.selector);
        validateParams(data, cond.params, cond.comps);
    }
}
