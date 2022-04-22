// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
 
/**
 * Tool to swap 1 to 1 tokens in big amounts.
 * Keep in mind tokens are expected to have the same decimal amount and to be exactly 1 to 1
 * Recieve a +5% bonus of the new tokens for all deposits before bonusTime.
 * End time and bonus time can be upgradable, but shold be over origin time.
 * By @developersuper
 */
 
import "./Auth.sol";
import "./IBEP20.sol";
 
contract TokenMigrator is Auth {
 
    struct Info{
        address tokenIn;
        address tokenOut;
        uint256 decimals;
        uint256 startTime;
        uint256 bonusTime;
    }
 
    uint256 receivedToken;
    uint256 totalBalance;
    uint256 claimedBalance;
 
    uint256 immutable startTime = 1644678000;
    uint256 public bonusTime =  1647097200;
 
    address public tokenIn = 0xA7339FAD4feDD614E2C113698Fd10fF334F98263;
    address public tokenOut;
 
    bool public claimable = false;
 
    mapping (address => uint256) public deposits;
    mapping (address => uint256) public claimed;
 
    event Deposit(address indexed depositer, uint256 quantity);
    event Claimed(address indexed receiver, uint256 quantity);
 
    constructor() Auth(msg.sender) {
    }
 
    /** setters **/
    function updateBonusTime(uint256 updatedTime_) external authorized {
        require(updatedTime_ > bonusTime, "Migrator::must be after old bonustime");
        bonusTime = updatedTime_;
    }
 
 
    function setClaimable(bool value) external authorized {
        require(value != claimable, "Migrator::must not be same with old value");
        if(value == true) {
            require(tokenOut != address(0), "Migrator::invalid out token address");
        }
        claimable = value;
    }
 
    function setTokenOut(address tokenAddress) external authorized {
        require(tokenAddress != address(0), "Migrator::invalid token address");
        tokenOut = tokenAddress;
    }
 
    function deposit(uint256 amount) external {
        require(block.timestamp > startTime, "Migrator::not started yet");
        require(amount > 0, "Migrator::must be over 0");
 
        IBEP20(tokenIn).transferFrom(msg.sender, address(this), amount);
 
        receivedToken += amount;
 
        if(block.timestamp <= bonusTime) {
            deposits[msg.sender] += (amount * 105 / 100);
        } else {
            deposits[msg.sender] += amount;
        }
 
        totalBalance += deposits[msg.sender];
 
        emit Deposit(msg.sender, amount);
    }
 
    function depositAll() external {
        require(block.timestamp > startTime, "Migrator::not started yet");
        
        uint256 amount = IBEP20(tokenIn).balanceOf(msg.sender);
        require(amount > 0, "Migrator::must be over 0");
        require(IBEP20(tokenIn).allowance(msg.sender, address(this)) >= amount, "Migrator::not approved to transfer");
 
        IBEP20(tokenIn).transferFrom(msg.sender, address(this), amount);
        receivedToken += amount;
 
        if(block.timestamp <= bonusTime) {
            deposits[msg.sender] += (amount * 105 / 100);
        }else {
            deposits[msg.sender] += amount;
        }
 
        totalBalance += deposits[msg.sender];
 
        emit Deposit(msg.sender, amount);
    }
 
    function claim() external {
        require(claimable && block.timestamp > startTime, "Migrator::not claimable");
        require(deposits[msg.sender] > 0, "Migrator::no balance");
 
        uint256 amount = deposits[msg.sender];
        deposits[msg.sender] = 0;
        claimed[msg.sender] += amount;
 
        claimedBalance += claimed[msg.sender];
 
        IBEP20(tokenOut).transfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }
 
    /** getters **/
 
    function getInfo() external view returns (Info memory) {
        return Info(tokenIn, tokenOut, IBEP20(tokenIn).decimals(), startTime, bonusTime);
    }
    
}
