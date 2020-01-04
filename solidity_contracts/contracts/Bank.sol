pragma solidity ^0.5.9;

import "./kyc_solution.sol";

/*
 * It has all the admin facing calls in this contract
 * Remaining all functions are Implented in the other contract
 */

contract Banks is kyc{
    constructor()public kyc(msg.sender){}

    modifier isAdmin(address sender){
        require(sender == admin,"ONlY ADMIN HAS ACCESS TO THESE");
        _;
    }

    function addBank(string memory name,address _ethAddress,string memory reqNumber)public isAdmin(msg.sender) returns(uint8){
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

    function removeBank(address _ethAddress)public isAdmin(msg.sender) returns(uint8){
        for(uint i=0;i<bankAddresses.length;i++){
            if(bankAddresses[i] == _ethAddress){
                delete banks[_ethAddress];
                for(uint j=i+1;j<bankAddresses.length;j++){
                    bankAddresses[j-1] = bankAddresses[j];
                }
                return 1;
            }
        }
        return 0;
    }
}