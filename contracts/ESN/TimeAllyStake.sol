// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "../lib/SafeMath.sol";
import "./NRTManager.sol";
import "./TimeAllyManager.sol";
import "./ValidatorManager.sol";

contract TimeAllyStake {
    using SafeMath for uint256;

    struct Delegation {
        address platform;
        address delegatee;
        uint256 amount;
    }

    NRTManager public nrtManager;
    TimeAllyManager public timeAllyManager;
    ValidatorManager public validatorManager;

    address public staker;
    uint256 public timestamp;
    uint256 public stakingStartMonth;
    uint256 public stakingPlanId;
    uint256 public stakingEndMonth;
    uint256 public unboundedBasicAmount;
    mapping(uint256 => uint256) public principalAmount;
    mapping(uint256 => bool) public isMonthClaimed;
    mapping(uint256 => Delegation[]) public delegation;

    modifier onlyStaker() {
        require(msg.sender == staker, "TAStake: Only staker can call");
        _;
    }

    constructor(uint256 _planId) public payable {
        timeAllyManager = TimeAllyManager(msg.sender);
        nrtManager = NRTManager(timeAllyManager.nrtManager());
        validatorManager = ValidatorManager(timeAllyManager.validatorManager());
        staker = tx.origin;
        timestamp = now;
        stakingPlanId = _planId;
        stakingStartMonth = nrtManager.currentNrtMonth() + 1;
        (uint256 _months, , ) = timeAllyManager.stakingPlans(_planId);
        stakingEndMonth = stakingStartMonth + _months - 1;

        for (uint256 i = stakingStartMonth; i <= stakingEndMonth; i++) {
            principalAmount[i] = msg.value;
        }

        unboundedBasicAmount = msg.value.mul(2).div(100);
    }

    receive() external payable {
        _stakeTopUp(msg.value);
    }

    function delegate(
        address _platform,
        address _delegatee,
        uint256 _amount,
        uint256[] memory _months
    ) public onlyStaker {
        require(_platform != address(0), "TAStake: Cannot delegate on zero");
        require(_delegatee != address(0), "TAStake: Cannot delegate to zero");
        uint256 _currentMonth = nrtManager.currentNrtMonth();
        for (uint256 i = 0; i < _months.length; i++) {
            require(_months[i] > _currentMonth, "TAStake: Only future delegatable");
            Delegation[] storage monthlyDelegation = delegation[i];
            uint256 _alreadyDelegated;
            Delegation storage existingDelegation;
            uint256 _delegationIndex;
            for (
                _delegationIndex = 0;
                _delegationIndex < monthlyDelegation.length;
                _delegationIndex++
            ) {
                _alreadyDelegated = _alreadyDelegated.add(
                    monthlyDelegation[_delegationIndex].amount
                );
                if (
                    _platform == monthlyDelegation[_delegationIndex].platform &&
                    _delegatee == monthlyDelegation[_delegationIndex].delegatee
                ) {
                    existingDelegation = monthlyDelegation[_delegationIndex];
                }
            }
            require(
                _amount.add(_alreadyDelegated) <= principalAmount[i],
                "TAStake: delegate overflow"
            );
            if (existingDelegation.delegatee != address(0)) {
                existingDelegation.amount = existingDelegation.amount.add(_amount);
            } else {
                _delegationIndex = monthlyDelegation.length;

                monthlyDelegation.push(
                    Delegation({ platform: _platform, delegatee: _delegatee, amount: _amount })
                );
            }

            validatorManager.addDelegation(_months[i], _delegationIndex);
        }
    }

    function _stakeTopUp(uint256 _topupAmount) private {
        uint256 _currentMonth = nrtManager.currentNrtMonth();

        for (uint256 i = _currentMonth + 1; i <= stakingEndMonth; i++) {
            principalAmount[i] += _topupAmount;
        }

        uint256 _increasedBasic = _topupAmount
            .mul(2)
            .div(100)
            .mul(stakingEndMonth - _currentMonth)
            .div(stakingEndMonth - stakingStartMonth + 1);

        unboundedBasicAmount = unboundedBasicAmount.add(_increasedBasic);

        timeAllyManager.increaseActiveStake(_topupAmount, stakingEndMonth);
    }

    function getAllDelegationsByMonth(uint256 _month) public view returns (Delegation[] memory) {
        return delegation[_month];
    }
}
