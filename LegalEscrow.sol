// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    Simple Legal Escrow (Client <-> Solicitor)

    - Client deposits ETH into escrow.
    - Client can release funds to the solicitor.
    - Solicitor can refund the client (e.g., cancellation/dispute resolved).
    - Basic access control + state flags to prevent double actions.
*/

contract LegalEscrow {
    address public client;
    address public solicitor;

    uint256 public amount;
    bool public deposited;
    bool public released;
    bool public refunded;

    event Deposited(address indexed client, uint256 amount);
    event Released(address indexed solicitor, uint256 amount);
    event Refunded(address indexed client, uint256 amount);

    constructor(address _solicitor) {
        require(_solicitor != address(0), "Invalid solicitor address");
        solicitor = _solicitor;
        client = msg.sender;
    }

    // Client deposits ETH into the escrow
    function deposit() external payable {
        require(msg.sender == client, "Only client can deposit");
        require(!deposited, "Deposit already made");
        require(!released && !refunded, "Escrow already completed");
        require(msg.value > 0, "Deposit must be greater than zero");

        amount = msg.value;
        deposited = true;

        emit Deposited(client, amount);
    }

    // Client releases funds to solicitor
    function releaseToSolicitor() external {
        require(msg.sender == client, "Only client can release");
        require(deposited, "No deposit made");
        require(!released && !refunded, "Escrow already completed");

        released = true;

        emit Released(solicitor, amount);
        payable(solicitor).transfer(amount);
    }

    // Solicitor refunds client (if cancelled/dispute resolved)
    function refundToClient() external {
        require(msg.sender == solicitor, "Only solicitor can refund");
        require(deposited, "No deposit made");
        require(!released && !refunded, "Escrow already completed");

        refunded = true;

        emit Refunded(client, amount);
        payable(client).transfer(amount);
    }

    // Optional helper for screenshots/testing
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
