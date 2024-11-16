// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {InvokeCheck} from "../src/InvokeCheck.sol";

contract InvokeCheckTest is Test {
    bytes4[] public fixtureSelector = [
        bytes4(0x9f5f7c7f),
        bytes4(0xc42cd8cf),
        bytes4(0x1df47aad),
        bytes4(0x2ac9bf09),
        bytes4(0x379607f5),
        bytes4(0x598647f8),
        bytes4(0xd6febde8),
        bytes4(0xd05c78da),
        bytes4(0xc41a360a),
        bytes4(0x82afd23b)
    ];

    function setUp() public {}

    function createCalldata() public returns (bytes memory) {
        address _from = makeAddr("from");
        address _to = makeAddr("to");
        bytes memory data = abi.encodeWithSignature("transfer(address,address,uint256)", _from, _to, uint256(10));
        return data;
    }

    function test_has4ByteSelectorTrue() public {
        bytes4 selector = bytes4(keccak256("transfer(address,address,uint256)"));
        bytes memory data = createCalldata();
        InvokeCheck.has_selector(data, selector);
    }

    //forge-config: default.fuzz.runs = 1024
    //forge-config: default.fuzz.show-logs = true
    function testFuzz_has4ByteSelectorFalse(bytes4 selector) public {
        vm.assume(selector != bytes4(0xbeabacc8)); // ignore collision
        bytes memory data = createCalldata();

        vm.expectRevert();
        InvokeCheck.has_selector(data, selector);
    }

}
