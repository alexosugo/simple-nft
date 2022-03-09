// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  event Stake(address indexed staker, uint256 amount);

  mapping (address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  bool public openToWithdraw;

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    require(msg.value > 0, "Not enough to stake");

    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  } 

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public notCompleted {
    require(timeLeft() == 0, "Please wait for deadline to elapse");

    if(address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance} ();
      openToWithdraw = false;
    } else {
      openToWithdraw = true;
    }
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `withdraw(address payable)` function lets users withdraw their balance
  function withdraw(address _payable) public notCompleted {
    // require(balances[_payable] > 0, "You don't have enough to withdraw");
    require(openToWithdraw == true, "Not open for withdrawal");
    uint256 userBalance = balances[_payable];
      balances[_payable] = 0;
      (bool sent,) = _payable.call{value: userBalance}("");
    require(sent, "Failed to send user balance back to the user");
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if(block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }

  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "Staking already completed");
    _;
  }

}
