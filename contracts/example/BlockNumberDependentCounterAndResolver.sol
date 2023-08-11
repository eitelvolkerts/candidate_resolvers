pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract BlockNumberDependentCounter is Ownable{
    string public name;
    uint256 public counter;
    mapping(uint256=>address) public addresses;
    struct incrementReturnData {
        uint256 oldCounter;
        uint256 newCounter;
        address cDataPassed;
        uint256 timeOfExec;
    }
    event Incremented(uint256 indexed oldCounter, uint256 indexed newCounter, address indexed cDataPassed, uint256 timeOfExec);
    event CounterSet(uint indexed oldCounter, uint indexed newCounter);
    event ItIsTime(uint indexed counter, uint indexed blocknumber, bytes indexed cdata);
    event ItIsNotTime(uint indexed counter, uint indexed blocknumber);

    constructor (string memory name_){
        name = name_;
        counter = 0;
    }

    function incrementWithCalldata(address dataPassed) public returns (incrementReturnData memory){
        uint256 counter_ = counter + 1;
        addresses[counter] = dataPassed;
        emit Incremented(counter, counter_, dataPassed, block.timestamp);
        incrementReturnData memory retData = incrementReturnData(counter, counter_, dataPassed, block.timestamp);
        counter = counter_;
        return retData;
    }

    function setCounter(uint _counter) public onlyOwner returns (uint newCounter){
        emit CounterSet(counter, _counter);
        counter = _counter;
        return counter;
    }

    function isItTimeYet() public returns (bool shouldExecute, bytes memory cdata_) {
        //emit gotCval(cval);
        //if (cval%5 == 0){
        //    //emit ok(true);
        //    return (true, cdata);
        //}
        cdata_ = abi.encodeWithSelector(this.incrementWithCalldata.selector, tx.origin);
        if (((block.number%10 == 0)&&(counter%5 == 0))||(counter%5 != 0)){
            emit ItIsTime(counter, block.number, cdata_);
            return (true, cdata_);
        }
        else {
            emit ItIsNotTime(counter, block.number);
            return (false, cdata_);
        }
    }
}