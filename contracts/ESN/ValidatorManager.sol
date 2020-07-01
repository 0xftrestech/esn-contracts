// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "../lib/SafeMath.sol";
import "./TimeAllyManager.sol";
import "./TimeAllyStaking.sol";

contract ValidatorManager {
    using SafeMath for uint256;

    struct ValidatorStaking {
        address validator;
        uint256 amount;
        Delegation[] delegators;
    }

    struct Delegation {
        address stakingContract;
        uint256 delegationIndex;
    }

    address public deployer;
    TimeAllyManager public timeally;

    mapping(uint256 => ValidatorStaking[]) validatorStakings;

    modifier onlyStakingContract() {
        require(timeally.isStakingContractValid(msg.sender), "ValM: Only stakes can call");
        _;
    }

    constructor() public {
        deployer = msg.sender;
    }

    function setInitialValues(address _timeally) public {
        require(msg.sender == deployer, "ValM: Only deployer can call");

        timeally = TimeAllyManager(payable(_timeally));
    }

    function addDelegation(uint256 _month, uint256 _stakerDelegationIndex)
        external
        onlyStakingContract
    {
        TimeAllyStaking stake = TimeAllyStaking(msg.sender);
        TimeAllyStaking.Delegation memory _delegation = stake.getDelegation(
            _month,
            _stakerDelegationIndex
        );
        uint256 _validatorIndex;

        for (; _validatorIndex < validatorStakings[_month].length; _validatorIndex++) {
            if (validatorStakings[_month][_validatorIndex].validator == _delegation.delegatee) {
                break;
            }
        }

        if (_validatorIndex == validatorStakings[_month].length) {
            uint256 index = validatorStakings[_month].length;
            validatorStakings[_month].push();
            validatorStakings[_month][index].validator = _delegation.delegatee;
        }

        ValidatorStaking storage validatorStaking = validatorStakings[_month][_validatorIndex];
        validatorStaking.amount = validatorStaking.amount.add(_delegation.amount);

        uint256 _validatorDelegationIndex;

        for (
            ;
            _validatorDelegationIndex < validatorStaking.delegators.length;
            _validatorDelegationIndex++
        ) {
            if (
                validatorStaking.delegators[_validatorDelegationIndex].stakingContract == msg.sender
            ) {
                break;
            }
        }

        if (_validatorDelegationIndex == validatorStaking.delegators.length) {
            validatorStaking.delegators.push(
                Delegation({ stakingContract: msg.sender, delegationIndex: _stakerDelegationIndex })
            );
        }
    }

    function getValidatorStaking(uint256 _month, uint256 _validatorIndex)
        public
        view
        returns (ValidatorStaking memory)
    {
        return validatorStakings[_month][_validatorIndex];
    }

    function getValidatorStakings(uint256 _month) public view returns (ValidatorStaking[] memory) {
        return validatorStakings[_month];
    }

    function getValidatorStakingDelegator(
        uint256 _month,
        uint256 _validatorIndex,
        uint256 _delegatorIndex
    ) public view returns (Delegation memory) {
        return validatorStakings[_month][_validatorIndex].delegators[_delegatorIndex];
    }

    function getValidatorStakingDelegators(uint256 _month, uint256 _validatorIndex)
        public
        view
        returns (Delegation[] memory)
    {
        return validatorStakings[_month][_validatorIndex].delegators;
    }
}