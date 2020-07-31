pragma solidity ^0.6
.0;

import 'openzeppelin-solidity/contracts/utils/Pausable.sol';

contract DividendTokenStore is Pausable {

    function totalSupply() virtual public view returns (uint256) {}

    function addLock(address _locked) virtual public returns (bool) {}

    function revokeLock(address _unlocked) virtual public returns (bool) {}
  
    function balanceOf(address _owner) virtual public view returns (uint256) {}

  function transfer(address _from, address _to, uint256 _value) virtual public returns (bool) {}
  
  receive () external payable {
    payIn();
  }

  function payIn() virtual public payable returns (bool) {}
  
  function claimDividends() virtual public returns (uint256) {}
  
  function claimDividendsFor(address payable _address) virtual public returns (uint256) {}
  
  event Paid(address indexed _sender, uint256 indexed _period, uint256 amount);

  event Claimed(address indexed _recipient, uint256 indexed _period, uint256 _amount);

  event Locked(address indexed _locked, uint256 indexed _at);

  event Unlocked(address indexed _unlocked, uint256 indexed _at);
}
