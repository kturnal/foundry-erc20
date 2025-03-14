// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract ManualToken {

    mapping(address => uint256) private s_balances;

    // This could have been ' string public name = "ManualToken"; '
    // since Solidity creates public getter functions when compiled 
    // for any publicly acccessible storage variables.
    function name() public pure returns (string memory) {
        return "Manual Token";
    }

    function totalSupply() public pure returns (uint256) {
        return 100 ether; // 100000000000000000000
    }

    // needed for simplicity since we declared 100 ether as our supply.
    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return s_balances[_owner];
    }

    function transfer(address _to, uint256 _amount) public {
        address _from = msg.sender;
        uint256 previousBalance = balanceOf(_from) + balanceOf(_to);
        s_balances[_from] -= _amount;
        s_balances[_to] += _amount;

        require(balanceOf(msg.sender) + balanceOf(_to) == previousBalance);
    }
}