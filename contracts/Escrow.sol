//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

/** 
 * @title Escrow
 * @dev Implements an Escrow system for a 2 member Agreement
 * @dev the contract is deployed and supplied with the address of the seller, partner, the amount and the time period for delivery
 */

 contract Escrow {
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
    State public agreementState;

    uint public agreementAmount; 
    address payable seller;
    address partner;

    uint public deliveryDays;

    mapping (address => bool) public agreementApproval;

    // modifiers
    modifier onlyPartner () {
        require(msg.sender == partner, "Only the partner can call this function");
        _;
    }

    constructor (address payable _seller, address _partner, uint _agreementAmount, uint _deliveryDays) {
        seller = _seller;
        partner = _partner;
        agreementAmount = _agreementAmount * (1 ether);

        deliveryDays = block.timestamp + _deliveryDays * 1 days;
    }

    // Each of the 2 parties will call this function to sign
    function signAgreement() public {
        require(agreementState == State.NOT_STARTED);
        // the caller confirms he's in
        agreementApproval[msg.sender] = true;

        if (agreementApproval[seller] && agreementApproval[partner]) {
            agreementState = State.AWAITING_PAYMENT;
        }
    }

    // the partner can make payment
    function deposit () public payable onlyPartner {
        require(agreementState == State.AWAITING_PAYMENT, "You have already paid");
        require(msg.value == agreementAmount, "Pay the Agreed Amount");

        agreementState = State.AWAITING_DELIVERY;
    }

    // the partner confirms that they've received the stuff, and that completes the agreement
    function confirmDelivery () public onlyPartner {
        require(agreementState == State.AWAITING_DELIVERY, "You Have not Made Payment");

         agreementState = State.COMPLETED;

        // transfer the money to the seller
        seller.transfer(agreementAmount);
    }

    // if the partner didn't get the stuff at the end of the delivery period, they can withdraw their money
    function withdraw () public payable onlyPartner {
        require(block.timestamp > deliveryDays, "you cannot End the Agreement within delivery period");
        require(agreementState == State.AWAITING_DELIVERY, "Withdrawal Not Allowed");

        agreementState = State.CANCELED;

        payable(partner).transfer(agreementAmount);

    }
 }