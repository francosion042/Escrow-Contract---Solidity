//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/** 
 * @title Escrow
 * @dev Implements an Escrow system for a 2 member Agreement
 * @dev the contract is deployed and supplied with the address of the seller, buyer, the amount and the time period for delivery
 */

contract Escrow {
    
    enum State {NOT_STARTED, AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETED, CANCELED}
    State public agreementState;

    uint public agreementAmount; 
    address payable seller;
    address buyer;

    uint public deliveryDays;

    mapping (address => bool) public agreementApproval;

    // modifiers
    modifier onlyBuyer () {
        require(msg.sender == buyer, "Only the buyer can call this function");
        _;
    }

    constructor (address payable _seller, address _buyer, uint _agreementAmount, uint _deliveryDays) {
        seller = _seller;
        buyer = _buyer;
        agreementAmount = _agreementAmount * (1 ether);

        deliveryDays = block.timestamp + _deliveryDays * 1 days;
    }

    // Each of the 2 parties will call this function to sign
    function initiateAgreement() public {
        require(agreementState == State.NOT_STARTED);
        // the caller confirms he's in
        agreementApproval[msg.sender] = true;

        if (agreementApproval[seller] && agreementApproval[buyer]) {
            agreementState = State.AWAITING_PAYMENT;
        }
    }

    // the buyer can make payment
    function deposit () public payable onlyBuyer {
        require(agreementState == State.AWAITING_PAYMENT, "You have already paid");
        require(msg.value == agreementAmount, "Pay the Agreed Amount");

        agreementState = State.AWAITING_DELIVERY;
    }

    // the buyer confirms that they've received the stuff, and that completes the agreement
    function confirmDelivery () public onlyBuyer {
        require(agreementState == State.AWAITING_DELIVERY, "You Have not Made Payment");

        // transfer the money to the seller
        seller.transfer(agreementAmount);

        agreementState = State.COMPLETED;
    }

    // if the buyer didn't get the stuff at the end of the delivery period, they can withdraw their money
    function withdraw () public payable onlyBuyer {
        require(block.timestamp > deliveryDays, "you cannot End the Agreement within delivery period");
        require(agreementState == State.AWAITING_DELIVERY, "Withdrawal Not Allowed");

        payable(buyer).transfer(agreementAmount);

        agreementState = State.CANCELED;
    }

}
