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
    enum State {NOT_SIGNED, AWAITING_PAYMENT, AWAITING_CONFIRMATION, COMPLETED, CANCELLED}

    // Events
    event AgreementInitated(
            uint256 indexed agreementId, 
            address indexed initiator, 
            address indexed partner,
            uint256 agreementAmount,
            uint256 maxFulfilmentDays
        );
    event AgreementSigned(
            uint256 indexed agreementId,
            address indexed partner
        );

    event AgreementAmountDeposited(
            uint256 indexed agreementId,
            uint256 agreementAmount,
            address indexed partner
        );

    event AgreementTransactionConfirmed(
            uint256 indexed agreementId,
            address indexed partner
        );

    event AgreementAmountWithdrawn(
            uint256 indexed agreementId,
            uint256 agreementAmount,
            address indexed partner
        );

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
    uint256 count;
    mapping (uint256 => Agreement) public agreements;

    // Modifiers
    modifier onlyPartner (uint256 _agreementId) {
        require(msg.sender == agreements[_agreementId].partner, "Only the partner can call this function");
        _;
    }

    // Functions
    function initialize () public initializer {
        __Ownable_init();
        count = 0;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function initiateAgreement (address _partner, uint _agreementAmount, uint _maxFulfilmentDays) public returns(uint256) {
        count ++;

        agreements[count] = Agreement({ 
            initiator: msg.sender, 
            partner: _partner, 
            agreementAmount: _agreementAmount, 
            maxFulfilmentDays: block.timestamp + _maxFulfilmentDays * 1 days, 
            agreementPartnerSigned: false, 
            agreementState: State.NOT_SIGNED
        });
        emit AgreementInitated(
            count, 
            msg.sender, 
            _partner,
            _agreementAmount, 
            block.timestamp + _maxFulfilmentDays * 1 days
        );
        
        return count;
    }

    function getAgreement (uint256 _agreementId) public view returns(Agreement memory) {
        return agreements[_agreementId];
    }

    // Each of the 2 parties will call this function to sign
    function signAgreement(uint256 _agreementId) public onlyPartner(_agreementId) {
        require(agreements[_agreementId].agreementState == State.NOT_SIGNED);
        // the caller confirms he's in
        agreements[_agreementId].agreementPartnerSigned = true;

        agreements[_agreementId].agreementState == State.AWAITING_PAYMENT;

        emit AgreementSigned(
            _agreementId, 
            msg.sender
        );
    }

    // the partner can make payment
    function deposit (uint256 _agreementId) public payable onlyPartner(_agreementId) {
        require(agreements[_agreementId].agreementState == State.AWAITING_PAYMENT, "You have already paid");
        require(msg.value == agreements[_agreementId].agreementAmount, "Pay the Agreed Amount");

        agreements[_agreementId].agreementState = State.AWAITING_CONFIRMATION;

        emit AgreementAmountDeposited(
            _agreementId, 
            msg.value, 
            msg.sender
        );
    }

    // the partner confirms that they've received the stuff, and that completes the agreement
    function confirm (uint256 _agreementId) public onlyPartner(_agreementId) {
        require(agreements[_agreementId].agreementState == State.AWAITING_CONFIRMATION, "You Have not Made Payment");

         agreements[_agreementId].agreementState = State.COMPLETED;

        // transfer the money to the seller
        payable(agreements[_agreementId].initiator).transfer(agreements[_agreementId].agreementAmount);

        emit AgreementTransactionConfirmed(
            _agreementId, 
            msg.sender
        );
    }

    // if the partner didn't get the stuff at the end of the delivery period, they can withdraw their money
    function withdraw (uint256 _agreementId) public payable onlyPartner(_agreementId) {
        require(block.timestamp > agreements[_agreementId].maxFulfilmentDays, "you cannot End the Agreement before its max fulfilment period");
        require(agreements[_agreementId].agreementState == State.AWAITING_CONFIRMATION, "Withdrawal Not Allowed");

        agreements[_agreementId].agreementState = State.CANCELLED;

        payable(agreements[_agreementId].partner).transfer(agreements[_agreementId].agreementAmount);

        emit AgreementAmountWithdrawn(
            _agreementId, 
            agreements[_agreementId].agreementAmount, 
            msg.sender
        );

    }
 }