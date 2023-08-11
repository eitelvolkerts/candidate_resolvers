pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../contracts/example/BlockNumberDependentCounterAndResolver.sol";


contract BlockNumberDependentCounterTest is Test {
    BlockNumberDependentCounter public counter;
    event Incremented(uint256 indexed oldCounter, uint256 indexed newCounter, address indexed cDataPassed, uint256 timeOfExec);
    event CounterSet(uint indexed oldCounter, uint indexed newCounter);
    event ItIsTime(uint indexed counter, uint indexed blocknumber, bytes indexed cdata);
    event ItIsNotTime(uint indexed counter, uint indexed blocknumber);
    struct incrementReturnData {
        uint256 oldCounter;
        uint256 newCounter;
        address cDataPassed;
        uint256 timeOfExec;
    }

    function setUp() public {
        vm.prank(address(0x1234567812345678123456781234567812345678));
        counter = new BlockNumberDependentCounter("whatever");
    }

    function test_SetCounter() public {
        vm.startPrank(address(0x1234567812345678123456781234567812345678));
        vm.expectEmit(true, true, false, false, address(counter));
        emit CounterSet(counter.counter(), 0);
        uint nCounter = counter.setCounter(0);
        vm.stopPrank();
        assertEq(nCounter, counter.counter());

    }

    function testFail_SetCounterNonOwner() public {
        vm.prank(address(0x1111111111111111111111111111111111111111));
        uint nCounter = counter.setCounter(0);
    }

    function test_Owner() public{
        assertEq(counter.owner(), address(0x1234567812345678123456781234567812345678));
    }

    function test_BlockDivisibleByTenAndCounterDivisibleByFive() public {
        vm.prank(address(0x1234567812345678123456781234567812345678));
        uint nCounter = counter.setCounter(5);
        bytes memory expectedCdata = abi.encodeWithSelector(counter.incrementWithCalldata.selector, address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38));
        //the weird 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 address is because prank does not change the tx.origin
        vm.roll(100);
        vm.startPrank(address(0x1111111111111111111111111111111111111111));
        vm.expectEmit(true, true, true, false, address(counter));
        emit ItIsTime(5, 100, expectedCdata);
        (bool execFlag, bytes memory retCdata) = counter.isItTimeYet();
        vm.stopPrank();
        assertEq(execFlag, true);
        assertEq(retCdata, expectedCdata);

    }

    function test_CounterNotDivisibleByFive() public {
        vm.prank(address(0x1234567812345678123456781234567812345678));
        uint nCounter = counter.setCounter(4);
        bytes memory expectedCdata = abi.encodeWithSelector(counter.incrementWithCalldata.selector, address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38));
        vm.roll(101);
        vm.startPrank(address(0x1111111111111111111111111111111111111111));
        vm.expectEmit(true, true, false, false, address(counter));
        emit ItIsTime(4, 101, expectedCdata);
        (bool execFlag, bytes memory retCdata) = counter.isItTimeYet();
        vm.stopPrank();
        assertEq(execFlag, true);
        assertEq(retCdata, expectedCdata);

    }

    function test_BlockNotDivisibleByTenAndCounterDivisibleByFive() public {
        vm.prank(address(0x1234567812345678123456781234567812345678));
        uint nCounter = counter.setCounter(5);
        bytes memory expectedCdata = abi.encodeWithSelector(counter.incrementWithCalldata.selector, address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38));
        vm.roll(101);
        vm.startPrank(address(0x1111111111111111111111111111111111111111));
        vm.expectEmit(true, true, false, false, address(counter));
        emit ItIsNotTime(5, 101);
        (bool execFlag, bytes memory retCdata) = counter.isItTimeYet();
        vm.stopPrank();
        assertEq(execFlag, false);
        assertEq(retCdata, expectedCdata);

    }

    function test_IncrementWithCalldata() public {
        vm.prank(address(0x1234567812345678123456781234567812345678));
        uint nCounter = counter.setCounter(5);
        vm.expectEmit(true, true, true, true, address(counter));
        emit Incremented(5, 6, address(0x1111111111111111111111111111111111111111), block.timestamp);
        BlockNumberDependentCounter.incrementReturnData memory receivedReturnData = counter.incrementWithCalldata(address(0x1111111111111111111111111111111111111111));
        assertEq(receivedReturnData.oldCounter, 5);
        assertEq(receivedReturnData.newCounter, 6);
        assertEq(receivedReturnData.cDataPassed, address(0x1111111111111111111111111111111111111111));
        assertEq(receivedReturnData.timeOfExec, block.timestamp);
    }
}
