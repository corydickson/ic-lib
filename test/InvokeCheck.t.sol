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
        bytes memory data = abi.encodeWithSignature("transfer(address,address,uint256)", _from, _to, uint256(300));
        return data;
    }

    function createCondition() public returns (InvokeCheck.Condition memory) {
        bytes4 selector = bytes4(keccak256("transfer(address,address,uint256)"));
        address _from = makeAddr("from");
        address _to = makeAddr("to");

        InvokeCheck.Parameter[] memory params = new InvokeCheck.Parameter[](3);
        params[0] = InvokeCheck.Parameter(abi.encode(uint256(uint160(_from))), InvokeCheck.Types.ADDRESS);
        params[1] = InvokeCheck.Parameter(abi.encode(uint256(uint160(_to))), InvokeCheck.Types.ADDRESS);
        params[2] = InvokeCheck.Parameter(abi.encode(uint256(200)), InvokeCheck.Types.UINTM);

        InvokeCheck.Comparators[] memory comps = new InvokeCheck.Comparators[](3);
        comps[0] = InvokeCheck.Comparators(1); // EQ
        comps[1] = InvokeCheck.Comparators(1); // EQ
        comps[2] = InvokeCheck.Comparators(3); // GREATER_THAN

        return InvokeCheck.Condition(selector, params, comps);
    }

    function test_has4ByteSelectorTrue() public {
        bytes4 selector = bytes4(keccak256("transfer(address,address,uint256)"));
        bytes memory data = createCalldata();
        InvokeCheck.hasSelector(data, selector);
    }

    //forge-config: default.fuzz.runs = 1024
    //forge-config: default.fuzz.show-logs = true
    function testFuzz_has4ByteSelectorFalse(bytes4 selector) public {
        vm.assume(selector != bytes4(0xbeabacc8)); // ignore collision
        bytes memory data = createCalldata();

        vm.expectRevert();
        InvokeCheck.hasSelector(data, selector);
    }

    function test_satisfiesCondition() public {
        InvokeCheck.Condition memory cond = createCondition();
        bytes memory data = createCalldata();
        InvokeCheck.satisfiesCondition(data, cond);
    }
}
