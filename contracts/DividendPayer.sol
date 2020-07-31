pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";


abstract contract DividendPayer {
    using SafeMath for uint256;
    using Address for address payable;

    struct DividendBalance {
        uint256 balance;
        uint256 fromTotal;
    }

    struct TokenBalance {
        uint256 balance;
        uint256 fromTotal;
    }

    mapping (address => DividendBalance) internal dividendBalance_;
    uint256 private adjustedDividends_;
    uint256 private baseTotal_;

    mapping (address => TokenBalance) internal tokenBalance_;
    ERC20 private token_;
    uint256 private adjustedTokenDividends_;
    uint256 private tokenBaseTotal_;
    uint256 private tokensSent_;
    uint256 private tokensDeposited_;

    
    function distributableTotal() virtual public returns (uint256);

    function holdingsOf(address _account) virtual public view returns (uint256);

    function depositDividend() public payable returns (bool) {
        _depositDividend(msg.value);
    }

    function withdrawBalance() public returns (uint256) {
        uint value = _withdrawFor(msg.sender);
        return value;
    }

    function withdrawTokens() public returns (uint256) {
        uint value = _withdrawTokensFor(msg.sender);
        return value;
    }

    function outstandingBalanceFor(address _account) public view returns (uint256) {
        if (adjustedDividends_ == 0) return 0;
        uint addition = adjustedDividends_
            .sub(dividendBalance_[_account].fromTotal)
            .mul(holdingsOf(_account))
            .div(baseTotal_);
        return dividendBalance_[_account].balance.add(addition);
    }

    function outstandingTokenBalanceFor(address _account) public view returns (uint256) {
        if (adjustedTokenDividends_ == 0) return 0;
        uint addition = adjustedTokenDividends_
            .sub(tokenBalance_[_account].fromTotal)
            .mul(holdingsOf(_account))
            .div(tokenBaseTotal_);
        return tokenBalance_[_account].balance.add(addition);
    }

    function _depositDividend(uint256 _value) internal {
        require(distributableTotal() > 0, "DividendPayer: no tokens to distribute to");

        if (baseTotal_ == 0) {
            baseTotal_ = distributableTotal();
        }

        uint adjustedValue;
        if (distributableTotal() == baseTotal_) {
            adjustedValue = _value;
        } else {
            adjustedValue = _value.mul(baseTotal_).div(distributableTotal());
        }
        adjustedDividends_ = adjustedDividends_.add(adjustedValue);
    }

    function _depositTokens() internal {
        require(distributableTotal() > 0, "DividendPayer: no tokens to distribute to");

        if (tokenBaseTotal_ == 0) {
            tokenBaseTotal_ == distributableTotal();
        }
        uint nTokens = token_.balanceOf(address(this))
            .add(tokensSent_)
            .sub(tokensDeposited_);
        uint adjustedValue;
        if (distributableTotal() == tokenBaseTotal_) {
            adjustedValue = nTokens;
        } else {
            adjustedValue = nTokens.mul(tokenBaseTotal_)
                .div(distributableTotal());
        }
        adjustedTokenDividends_ = adjustedTokenDividends_.add(adjustedValue);
        tokensDeposited_ = tokensDeposited_.add(nTokens);
    }

    function _withdrawFor(address payable _account) internal returns (uint256) {
        uint balance = _updateBalance(_account);
        if (balance > 0) {
            dividendBalance_[_account].balance = 0;
            _account.sendValue(balance);
        }
        return balance;
    }

    function _withdrawTokensFor(address _account) internal returns (uint256) {
        uint tokenBalance = _updateTokenBalance(_account);
        if (tokenBalance > 0) {
            tokenBalance_[_account].balance = 0;
            token_.transfer(_account, tokenBalance);
            tokensSent_ = tokensSent_.add(tokenBalance);
        }
        return tokenBalance;
    }

    function _updateBalance(address _account) internal returns (uint256) {
        uint balance = outstandingBalanceFor(_account);
        if (dividendBalance_[_account].fromTotal < adjustedDividends_) {
            dividendBalance_[_account].balance = balance;
            dividendBalance_[_account].fromTotal = adjustedDividends_;
        }
        return balance;
    }

    function _updateTokenBalance(address _account) internal returns (uint256) {
        uint balance = outstandingBalanceFor(_account);
        if (tokenBalance_[_account].fromTotal < adjustedTokenDividends_) {
            tokenBalance_[_account].balance = balance;
            tokenBalance_[_account].fromTotal = adjustedTokenDividends_;
        }
        return balance;
    }
}
