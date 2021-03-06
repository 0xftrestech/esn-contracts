// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
// import { NRTManager } from "../../NRT/NRTManager.sol";
import { NRTReceiver } from "../../NRT/NRTReceiver.sol";
// import { Dayswappers } from "../../Dayswappers/DayswappersCore.sol";
// import { TimeAllyManager } from "../1LifeTimes/TimeAllyManager.sol";
import { ITimeAllyStaking } from "../1LifeTimes/ITimeAllyStaking.sol";
// import { PrepaidEs } from "../../PrepaidEs/PrepaidEs.sol";
import { Authorizable } from "../../Governance/Authorizable.sol";
import { RegistryDependent } from "../../KycDapp/RegistryDependent.sol";
import { Governable } from "../../Governance/Governable.sol";
import { ITimeAllyClub } from "./ITimeAllyClub.sol";

contract TimeAllyClub is ITimeAllyClub, Governable, RegistryDependent, NRTReceiver, Authorizable {
    using SafeMath for uint256;

    // Dayswappers public dayswappers;
    // TimeAllyManager public timeallyManager;
    // PrepaidEs public prepaidEs;

    mapping(address => mapping(uint32 => Membership)) monthlyMemberships;
    mapping(uint32 => uint256) totalBusinessVolume;
    mapping(address => Incentive[]) platformIncentiveStructure;

    event Business(
        address indexed networker,
        address indexed platform,
        uint32 indexed month,
        uint256 value
    );

    event Withdraw(
        address indexed networker,
        address indexed platform,
        uint32 indexed month,
        uint256 direct,
        uint256 tree,
        uint256 burn,
        uint256 issTime,
        address staking
    );

    function setInitialValues() public {
        // NRTManager _nrtManager,
        // Dayswappers _dayswappers,
        // TimeAllyManager _timeallyManager,
        // PrepaidEs _prepaidEs,
        // address _kycDapp
        // nrtManager = _nrtManager;
        // dayswappers = _dayswappers;
        // timeallyManager = _timeallyManager;
        // prepaidEs = _prepaidEs;
        // updateAuthorization(address(_timeallyManager), true);
        // updateAuthorization(_kycDapp, true);
    }

    function setPlatformIncentives(address _platform, Incentive[] memory _incentiveStructure)
        public
    {
        if (platformIncentiveStructure[_platform].length > 0) {
            delete platformIncentiveStructure[_platform];
        }

        for (uint256 i = 0; i < _incentiveStructure.length; i++) {
            platformIncentiveStructure[_platform].push(_incentiveStructure[i]);
        }
    }

    // having temporarily until next redeploy for backwards compability purpose
    function reportNewStaking(address _networker, uint256 _value) public {
        rewardToIntroducer(_networker, _value);
    }

    // TODO: make it only allowed
    function rewardToIntroducer(address _networker, uint256 _value) public override {
        // address _introducer = Dayswappers(resolveAddress("DAYSWAPPERS")).resolveIntroducer(
        address _introducer = dayswappers().resolveIntroducer(_networker);
        if (_introducer == address(0)) return;

        rewardToNetworker(_introducer, _value);
    }

    function rewardToNetworker(address _networker, uint256 _value) public override onlyAuthorized {
        uint32 _currentMonth = uint32(nrtManager().currentNrtMonth());
        monthlyMemberships[_networker][_currentMonth]
            .businessVolume = monthlyMemberships[_networker][_currentMonth].businessVolume.add(
            _value
        );

        totalBusinessVolume[_currentMonth] = totalBusinessVolume[_currentMonth].add(_value);

        monthlyMemberships[_networker][_currentMonth].platformBusiness[msg.sender]
            .business = monthlyMemberships[_networker][_currentMonth].platformBusiness[msg.sender]
            .business
            .add(_value);

        emit Business(_networker, msg.sender, _currentMonth, _value);
    }

    function withdrawPlatformIncentive(
        uint32 _month,
        address _platform,
        RewardType _rewardType,
        address _stakingContract
    ) public override {
        // TimeAllyStaking stakingContract
        require(
            timeallyManager().isStakingContractValid(_stakingContract),
            "Club: Staking contract is not valid"
        );
        require(
            // TimeAllyStaking is Governable and owner method is available in Governable
            msg.sender == Governable(payable(_stakingContract)).owner(),
            "Club: Not ownership of staking"
        );
        require(
            !monthlyMemberships[msg.sender][_month].platformBusiness[_platform].claimed,
            "Club: Already claimed"
        );

        (uint256 _direct, uint256 _tree, uint256 _burn) = getReward(msg.sender, _month, _platform);
        require(_direct > 0 || _tree > 0 || _burn > 0, "Club: No reward");

        monthlyMemberships[msg.sender][_month].platformBusiness[_platform].claimed = true;

        uint256 _issTime;
        if (_direct > 0) {
            uint256 _stakedReward = _direct.div(2);
            uint256 _prepaidReward;
            uint256 _liquidReward;

            if (_rewardType == RewardType.Liquid) {
                _liquidReward = _stakedReward; //_reward.div(2);
            } else if (_rewardType == RewardType.Prepaid) {
                _issTime = _stakedReward;
                _prepaidReward = _stakedReward; //_reward.div(2);
            } else if (_rewardType == RewardType.Staked) {
                _issTime = _stakedReward.mul(125).div(100);
                _stakedReward = _direct;
            } else {
                /// @dev Invalid enum calls are auto-reverted but still, just in some case.
                revert("Club: Invalid reward type specified");
            }

            /// @dev Send staking rewards as topup if any.
            if (_stakedReward > 0) {
                (bool _success, ) = address(_stakingContract).call{ value: _stakedReward }("");
                require(_success, "Club: Staking Topup is failing");
            }

            /// @dev Send prepaid rewards if any.
            if (_prepaidReward > 0) {
                prepaidEs().convertToESP{ value: _prepaidReward }(msg.sender);
            }

            /// @dev Send liquid rewards if any.
            if (_liquidReward > 0) {
                (bool _success, ) = msg.sender.call{ value: _liquidReward }("");
                require(_success, "Club: Liquid ES transfer to self is failing");
            }

            /// @dev Increase IssTime Limit for the staking.
            if (_issTime > 0) {
                ITimeAllyStaking(payable(_stakingContract)).increaseIssTime(_issTime);
            }
        }

        if (_tree > 0) {
            dayswappers().payToTree{ value: _tree }(
                msg.sender,
                [uint256(50), uint256(0), uint256(50)]
            );
        }

        if (_burn > 0) {
            nrtManager().addToBurnPool{ value: _burn }();
        }

        emit Withdraw(
            msg.sender,
            _platform,
            _month,
            _direct,
            _tree,
            _burn,
            _issTime,
            _stakingContract
        );
    }

    function getReward(
        address _networker,
        uint32 _month,
        address _platform
    )
        public
        override
        view
        returns (
            uint256 direct,
            uint256 tree,
            uint256 burn
        )
    {
        uint256 _businessVolume = monthlyMemberships[_networker][_month].businessVolume;
        uint256 _otherVolume = monthlyMemberships[_networker][_month].otherVolume;

        Incentive memory slab = getIncentiveSlab(_businessVolume + _otherVolume, _platform);

        PlatformBusiness memory _platformBusiness = monthlyMemberships[_networker][_month]
            .platformBusiness[_platform];

        if (_platformBusiness.claimed) {
            return (0, 0, 0);
        }

        direct = _platformBusiness.business.mul(slab.directBountyPerTenThousand).div(10000);
        tree = _platformBusiness.business.mul(slab.treeBountyPerTenThousand).div(10000);

        uint256 _globalMaxReward = totalBusinessVolume[_month].mul(30).div(100);
        uint256 _selfMaxReward = _platformBusiness.business.mul(30).div(100);
        uint256 _selfActualReward = direct + tree;
        uint256 _nrt = monthlyNRT[_month + 1];
        require(_nrt > 0, "Club: Month NRT not released");
        burn = _selfMaxReward.sub(_selfActualReward);
        if (_globalMaxReward > _nrt) {
            direct = direct.mul(_nrt).div(_globalMaxReward);
            tree = tree.mul(_nrt).div(_globalMaxReward);
        } else {
            burn = burn.add((_nrt.sub(_globalMaxReward)).mul(_selfMaxReward).div(_globalMaxReward));
        }
    }

    function getIncentiveSlab(uint256 _volume, address _platform)
        public
        override
        view
        returns (Incentive memory)
    {
        Incentive[] storage incentiveStructure = platformIncentiveStructure[_platform];

        // uint256 _volume = monthlyMemberships[_networker][_month].businessVolume +
        //     monthlyMemberships[_networker][_month].otherVolume;

        if (incentiveStructure.length == 0) {
            return
                Incentive({
                    label: "Default Slab",
                    target: 0,
                    directBountyPerTenThousand: 0,
                    treeBountyPerTenThousand: 0
                });
        }

        uint256 i = 0;
        for (; i < incentiveStructure.length; i++) {
            // monthlyMemberships[_networker];
            if (_volume < incentiveStructure[i].target) {
                break;
            }
        }

        i--;

        return incentiveStructure[i];
    }

    function getMembershipVolume(address _networker, uint32 _month)
        public
        override
        view
        returns (uint256 businessVolume, uint256 otherVolume)
    {
        businessVolume = monthlyMemberships[_networker][_month].businessVolume;
        otherVolume = monthlyMemberships[_networker][_month].otherVolume;
    }

    function getPlatformBusiness(
        address _network,
        uint32 _month,
        address _platform
    ) public override view returns (PlatformBusiness memory) {
        return monthlyMemberships[_network][_month].platformBusiness[_platform];
    }

    function getTotalBusinessVolume(uint32 _month) public override view returns (uint256) {
        return totalBusinessVolume[_month];
    }
}
