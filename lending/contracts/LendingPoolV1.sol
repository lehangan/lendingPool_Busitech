// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LendingPoolV1 {

    uint256 public totalDeposits;
    uint256 public totalBorrows;

    mapping(address => uint256) public startTime;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public borrowAmounts;
    mapping(address => uint256) public collaterals;
    mapping(address => uint256) public loan_to_user;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount, uint256 collateral);
    event Repay(address indexed user, uint256 amount);

    struct Loan {
        uint256 interestRate;
        uint256 loanToValue;
        uint256 liquidationThreshold;
        uint256 time;
    }
    Loan[] public loans;

    function addLoan(
        uint256 _interestRate,
        uint256 _loanToValue,
        uint256 _liquidationThreshold,
        uint256 _time
    ) external {
        Loan memory newLoan = Loan(
            _interestRate,
            _loanToValue,
            _liquidationThreshold,
            _time
        );
        loans.push(newLoan);
    }

    function deposit(uint256 index) external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        loan_to_user[msg.sender] = index;
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;

        startTime[msg.sender] = block.timestamp;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external payable {
        uint index = loan_to_user[msg.sender];
        uint256 interestRate = loans[index].interestRate;

        require(
            block.timestamp - startTime[msg.sender] >= loans[index].time,
            "Not enough time in deposit"
        );

        require(amount > 0, "Withdraw amount must be greater than 0");
        require(amount <= balances[msg.sender], "Insufficient balance");
        require(
            amount < address(this).balance,
            "not have enough money in pool"
        );

        balances[msg.sender] -= amount;
        uint256 inRate = (amount * interestRate) / 100;
        totalDeposits -= amount + inRate;

        (bool sent, ) = msg.sender.call{value: amount + inRate}("");
        require(sent, "Failed to send Ether ");
        emit Withdraw(msg.sender, amount);
    }

    function borrow(uint256 amount, uint256 collateral, uint256 index) external payable {
        require(
            amount < address(this).balance,
            "not have enough money in pool"
        );
        require(
            collateral == msg.value,
            "You have to give collateral to borrow"
        );

        uint256 LTV = loans[index].loanToValue;

        require(amount > 0, "Borrow amount must be greater than 0");
        require(
            collateral >= (amount * (100 - LTV)) / 100,
            "Insufficient collateral"
        );

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether ");

        borrowAmounts[msg.sender] += amount;
        collaterals[msg.sender] += collateral;
        totalBorrows += amount;
        emit Borrow(msg.sender, amount, collateral);
    }

    function repay() external payable {
        uint index = loan_to_user[msg.sender];
        uint256 interestRate = loans[index].interestRate;

        require(borrowAmounts[msg.sender] > 0, "No borrow amount to repay");
        require(msg.value > 0, "Repay amount must be greater than 0");

        uint256 repayAmount = borrowAmounts[msg.sender] +
            (borrowAmounts[msg.sender] * interestRate) /
            100;
        require(msg.value >= repayAmount, "Insufficient repay amount");

        balances[msg.sender] += msg.value - repayAmount;
        totalDeposits += msg.value - repayAmount;
        totalBorrows -= borrowAmounts[msg.sender];
        borrowAmounts[msg.sender] = 0;

        uint256 collateralRe = collaterals[msg.sender];
        (bool sent, ) = msg.sender.call{value: collateralRe}("");
        require(sent, "Failed to send Ether ");

        collaterals[msg.sender] = 0;
        emit Repay(msg.sender, repayAmount);
    }
}
