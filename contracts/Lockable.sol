pragma solidity ^0.6.0;


contract Lockable {

    mapping (address => bool) internal locked_;

    function isLocked(address _account) public view returns (bool) {
        return locked_[_account];
    }

    function lock(address _account) internal returns (bool) {
        if (locked_[_account]) return false;
        locked_[_account] = true;
        return true;
    }

    function unlock(address _account) internal returns (bool) {
        if (!locked_[_account]) return false;
        locked_[_account] = false;
        return true;
    }
}

