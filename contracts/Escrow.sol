//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/** 
 * @title Escrow
 * @dev Implements an Escrow system for a 2 member Agreement
 * @dev the contract is deployed and supplied with the address of the seller, partner, the amount and the time period for delivery
 */

 contract Escrow is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    enum State {NOT_STARTED, AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETED, CANCELED}

    // Structs
    struct Agreement {
        address initiator;
        address partner;
        uint256 agreementAmount;
        uint256 maxFulfilmentDays;
        bool agreementPartnerSigned;
        State agreementState;
    }

    // Variables
    mapping (uint256 => Agreement) public agreements;

    // modifiers
    modifier onlyPartner (uint256 _agreementId) {
        require(msg.sender == agreements[_agreementId].partner, "Only the partner can call this function");
        _;
    }
    function initialize () public initializer {
        __Ownable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function initiateAgreement (address _partner, uint _agreementAmount, uint _maxFulfilmentDays) public {
        agreements[1] = Agreement({ initiator: msg.sender, 
                                    partner: _partner, 
                                    agreementAmount: _agreementAmount, 
                                    maxFulfilmentDays: block.timestamp + _maxFulfilmentDays * 1 days, 
                                    agreementPartnerSigned: false, 
                                    agreementState: State.NOT_STARTED
                                  });
    }

    // Each of the 2 parties will call this function to sign
    // function signAgreement() public {
    //     require(agreementState == State.NOT_STARTED);
    //     // the caller confirms he's in
    //     agreementApproval[msg.sender] = true;

    //     if (agreementApproval[seller] && agreementApproval[partner]) {
    //         agreementState = State.AWAITING_PAYMENT;
    //     }
    // }

    // // the partner can make payment
    // function deposit (uint256 _agreementId) public payable onlyPartner(_agreementId) {
    //     require(agreementState == State.AWAITING_PAYMENT, "You have already paid");
    //     require(msg.value == agreementAmount, "Pay the Agreed Amount");

    //     agreementState = State.AWAITING_DELIVERY;
    // }

    // // the partner confirms that they've received the stuff, and that completes the agreement
    // function confirmDelivery (uint256 _agreementId) public onlyPartner(_agreementId) {
    //     require(agreementState == State.AWAITING_DELIVERY, "You Have not Made Payment");

    //      agreementState = State.COMPLETED;

    //     // transfer the money to the seller
    //     seller.transfer(agreementAmount);
    // }

    // // if the partner didn't get the stuff at the end of the delivery period, they can withdraw their money
    // function withdraw (uint256 _agreementId) public payable onlyPartner(_agreementId) {
    //     require(block.timestamp > deliveryDays, "you cannot End the Agreement within delivery period");
    //     require(agreementState == State.AWAITING_DELIVERY, "Withdrawal Not Allowed");

    //     agreementState = State.CANCELED;

    //     payable(partner).transfer(agreementAmount);

    // }
 }