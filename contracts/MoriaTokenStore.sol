pragma solidity ^0.6.0;

import "./DividendTokenStore.sol";
import "./DividendPayer.sol";
import "./Lockable.sol";

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/access/Ownable.sol';


contract MoriaTokenStore is DividendTokenStore, DividendPayer, Ownable, Lockable {
    using SafeMath for uint256;

    mapping (address => uint256) public holdings_;
    uint256 public totalSupply_;
    uint256 public distributableSupply_;
    uint256 public period_;

    function totalSupply() override public view returns (uint256) {
        return totalSupply_;
    }

    function distributableTotal() override public returns (uint256) {
        return distributableSupply_;
    }

    function holdingsOf(address _account) override public view returns (uint256) {
        if(isLocked(_account)) {
            return 0;
        }
        return(holdings_[_account]);
    }

    function addLock(address _locked) override public onlyOwner returns (bool) {
        require(lock(_locked));
        distributableSupply_ = distributableSupply_.sub(holdings_[_locked]);
        emit Locked(_locked, period_);
    }

    function revokeLock(address _unlocked) override public onlyOwner returns (bool) {
        require(unlock(_unlocked));
        distributableSupply_ = distributableSupply_.add(holdings_[_unlocked]);
        emit Unlocked(_unlocked, period_);
    }
  
    function balanceOf(address _owner) override public view returns (uint256) {
        return holdings_[_owner];
    }

    function transfer(address _from, address _to, uint256 _value) override onlyOwner public returns (bool) {
        require(_to != address(0));
        require(_value <= holdings_[_from]);
        if(isLocked(_from) && !isLocked(_to)) {
            distributableSupply_ = distributableSupply_.add(holdings_[_to]);
        } else if(!isLocked(_from) && isLocked(_to)) {
            distributableSupply_ = distributableSupply_.sub(holdings_[_to]);
        }

        holdings_[_from] = holdings_[_from].sub(_value);
        holdings_[_to] = holdings_[_to].add(_value);
        _updateBalance(_from);
        _updateBalance(_to);
        _updateTokenBalance(_from);
        _updateTokenBalance(_to);
    }

    function payIn() override public onlyOwner payable returns (bool) {
        period_ = period_.add(1);
        emit Paid(msg.sender, period_.sub(1), msg.value);
    }
  
    function claimDividends() override public returns (uint256) {
        uint amount = _withdrawFor(msg.sender);
        emit Claimed(msg.sender, period_, amount);
    }
  
    function claimDividendsFor(address payable _address) override public onlyOwner returns (uint256) {
        uint amount = _withdrawFor(_address);
        emit Claimed(msg.sender, period_, amount);
    }
  
    event Paid(address indexed _sender, uint256 indexed _period, uint256 amount);

    event Claimed(address indexed _recipient, uint256 indexed _period, uint256 _amount);

    event Locked(address indexed _locked, uint256 indexed _at);

    event Unlocked(address indexed _unlocked, uint256 indexed _at);
}
