pragma solidity ^0.5.9;

import "./kyc_solution.sol";

contract Banks is kyc{
    constructor()public kyc(msg.sender){}

    function addBanks(string memory name,address _ethAddress,string memory reqNumber)public returns(uint8){
        banks[_ethAddress] = Bank({
            ethAddress: _ethAddress,
            bankName: name,
            regNumber: reqNumber,
            rating:0,
            kyc_count:0
        });
        bankAddresses.push(_ethAddress);
        return 1;
    }
}