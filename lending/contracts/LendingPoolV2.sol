// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PriceConsumerV3.sol";
import "./StableToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract LendingPoolV2 {
    using SafeMath for uint256;

    address stableTokenAddr = 0x9d83e140330758a8fFD07F8Bd73e86ebcA8a5692;
    StableToken public stableToken = StableToken(stableTokenAddr);

    address oracleAddr = 0xDA0bab807633f07f013f94DD0E6A4F96F8742B53; 
    PriceConsumerV3 public oracle =  PriceConsumerV3(oracleAddr);

    uint256 public constant DEPOSIT_RATE = 2;
    uint256 public constant DEPOSIT_TIME = 10;

    uint256 public constant CLOSE_FACTOR = 5;
    uint256 public constant LIQUITATION_SPREAD = 1;

    struct Loan {
        uint256 LTV;
        uint256 liquid_Thres;
        uint256 interest_rate;
    }
    Loan[] public loans;

    uint256 private totalDeposits;
    uint256 private totalBorrows;

    mapping(address => uint256) public startTime;

    mapping(address => uint256) public supply;

    mapping(address => uint256) public borrowAmounts;

    mapping(address => uint256) public collaterals;

    mapping(address => uint8) public loan_to_user;

    mapping(address => uint256) private healthFactor;

    event Deposit(address user, uint256 amountSupply, uint256 timestamp);

    event Withdraw(address user, uint256 amountToWithdraw, uint256 timestamp);

    event Borrow(
        address user,
        uint256 amountBorrow,
        uint8 index,
        uint256 timestamp
    );

    event Repay(
        address user,
        uint256 amountRepay,
        uint256 collateralRepay,
        uint256 timestamp
    );

    function addLoan(
        uint256 _loanToValue,
        uint256 _liquidationThreshold,
        uint256 _interestRate
    ) external {
        Loan memory newLoan = Loan(
            _loanToValue,
            _liquidationThreshold,
            _interestRate
        );
        loans.push(newLoan);
    }

    function getTotalDeposit() public view returns (uint256) {
        return totalDeposits;
    }

    function getTotalBorrow() public view returns (uint256) {
        return totalBorrows;
    }

    function getHealthFactor(address user) public returns(uint256){
        uint256 index = loan_to_user[user];
        uint256 liquid_Threshold = loans[index].liquid_Thres;
        uint256 debt = borrowAmounts[user];
        // healthFactor[user] =
        //     (collaterals[user] * 1500 * liquid_Threshold) /
        //     ((10**(20) * debt));
        healthFactor[user] =
            (collaterals[user] * getEthUSDPrice() * liquid_Threshold) /
            ((10**(28) * debt));
        return healthFactor[user];
    }

    function getHealthFactor2(address user) public returns(uint256){
        uint256 index = loan_to_user[user];
        uint256 liquid_Threshold = loans[index].liquid_Thres;
        uint256 debt = borrowAmounts[user];
        healthFactor[user] =
            (collaterals[user] * 1600 * liquid_Threshold) /
            ((10**(20) * debt));
        return healthFactor[user];
    }

    function getEthUSDPrice() public view returns (uint256) {
        uint256 price8 = uint256(oracle.getLatestPrice());
        return price8 ;
    }

    /**
     * @dev Deposits an `amount` of ETH
     * @param amount The amount to be deposited
     **/

    function deposit(uint256 amount) external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        require(amount == msg.value, "Deposit amount not enough");

        startTime[msg.sender] = block.timestamp;

        supply[msg.sender] = supply[msg.sender].add(amount);
        totalDeposits = totalDeposits.add(amount);

        require(
            totalDeposits == address(this).balance,
            "Total deposit ETH is not enough"
        );
        emit Deposit(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Withdraws an `amount` of ETH
     * @param amount The amount ETH to be withdrawn
     *  Send the value type(uint256).max in order to withdraw the whole balance
     **/

    function withdraw(uint256 amount) external payable {
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(amount <= supply[msg.sender], "Insufficient balance");

        require(
            block.timestamp - startTime[msg.sender] >= DEPOSIT_TIME,
            "Not available"
        );
        uint256 amountToWithdraw = amount;

        if (amount == type(uint256).max) {
            amountToWithdraw = supply[msg.sender];
        }

        amountToWithdraw = (amountToWithdraw * (100 + DEPOSIT_RATE)) / 100;
        supply[msg.sender] = supply[msg.sender].sub(amountToWithdraw);

        totalDeposits = totalDeposits.sub(amountToWithdraw);

        require(
            amountToWithdraw <= address(this).balance,
            "Not enough ETH in pool to withdraw"
        );

        (bool sent, ) = msg.sender.call{value: amountToWithdraw}("");
        require(sent, "Failed to send Ether ");

        emit Withdraw(msg.sender, amountToWithdraw, block.timestamp);
    }

    /**
     * @dev Allows users to borrow a specific `amount` of the stable Token
     * provided that the borrower already deposited enough collateral (ETH)
     * @param amount The amount Token to be borrowed
     * @param index the index of loan package
     * @return max_value_to_loan the maximum value of token can loan
     **/

    function borrow(uint256 amount, uint8 index)
        external
        payable
        returns (uint256)
    {
        require(amount > 0, "Borrow amount must be greater than 0");

        loan_to_user[msg.sender] = index;
        uint256 LTV = loans[index].LTV;
        uint256 balance = supply[msg.sender];
        // example price of ETH 1500

        // uint256 priceOfBalance = (balance * 1500) / (10**18);
        uint256 price = getEthUSDPrice();
        uint256 priceOfBalance = (balance * price) / (10**26);

        uint256 max_value_to_loan = (priceOfBalance * LTV) / 100;
        require(
            amount <= max_value_to_loan,
            "Deposit not enough ETH to borrow"
        );

        // uint256 amountETH = (amount * (10**20) )/ (1500*LTV);
        uint256 amountETH = (amount * (10**28) )/ (price*LTV);
        require(
            amount < stableToken.balanceOf(address(this)),
            "Not enough stable token"
        );

        totalDeposits = totalDeposits.sub(amountETH);
        supply[msg.sender] = supply[msg.sender].sub(amountETH);
        collaterals[msg.sender] = collaterals[msg.sender].add(amountETH);

        totalBorrows = totalBorrows.add(amount);
        borrowAmounts[msg.sender] = borrowAmounts[msg.sender].add(amount);

        stableToken.approve(address(this), amount);
        stableToken.transferFrom(address(this), msg.sender, amount);

        emit Borrow(msg.sender, amount, index, block.timestamp);

        return max_value_to_loan;
    }

    /**
     * @notice Repays a borrowed `amount` on stable token
     * @param amount The amount to repay
     **/
    function repay(uint256 amount) external payable {
        uint8 index = loan_to_user[msg.sender];

        uint256 interestRate = loans[index].interest_rate;

        require(borrowAmounts[msg.sender] > 0, "No borrow amount to repay");
        require(amount > 0, "Repay amount must be greater than 0");

        uint256 HealthFactor = getHealthFactor(msg.sender);
        require(
            HealthFactor >= 1,
            "Collaterals have been liquidate"
        );

        uint256 repayAmount = (amount * (100 + interestRate)) / 100;

        stableToken.transferFrom(msg.sender, address(this), repayAmount);

        uint256 price = getEthUSDPrice();
        uint256 collateralRepay = (amount * (10**26)) / price;
        (bool sent, ) = msg.sender.call{value: collateralRepay}("");
        require(sent, "Failed to send Ether ");

        borrowAmounts[msg.sender] = borrowAmounts[msg.sender].sub(amount);
        totalBorrows = totalBorrows.sub(amount);
        collaterals[msg.sender] = collaterals[msg.sender].sub(collateralRepay);

        emit Repay(msg.sender, repayAmount, collateralRepay, block.timestamp);
    }

    function liquidateCall(address user) external payable{
        uint256 HF = getHealthFactor2(user);
        require( HF<1 , "You can not liquidate this user");

        uint8 index = loan_to_user[user];

        uint256 debt = (borrowAmounts[user]*CLOSE_FACTOR)/10;
        uint256 debtPay = debt*(100+loans[index].interest_rate)/100;

        stableToken.transferFrom(msg.sender, address(this), debtPay);

        uint256 debtClaim = debt*(10+LIQUITATION_SPREAD)/10;

        //uint256 price8 = getEthUSDPrice();
        uint256 price8 = 160000000000;

        debtClaim = (debtClaim*(10**26)/price8);

        collaterals[user] = collaterals[user].sub(debtClaim);
        borrowAmounts[user] = borrowAmounts[user].sub(debt);
        
        totalBorrows = totalBorrows.sub(debt);

        (bool sent, ) = msg.sender.call{value: debtClaim}("");
        require(sent, "Failed to send Ether ");

    }
}
