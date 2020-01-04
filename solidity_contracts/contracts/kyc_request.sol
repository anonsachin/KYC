pragma solidity ^0.5.10;

contract CustomerKYC{

    struct customer{
        string name;
        string cData;
        uint256 upVote;
        address bank;
    }

    struct request{
        string name;
        string cData;
        address bank;
    }

    struct bank{
        string name;
        address ethAddress;
        string reqNumber;
    }
    mapping (string => request) internal requestList;
    mapping (string => customer) public customerList;

    function AddRequest(string memory name, string memory data)
    public alreadyInReq(name) returns(uint){
        requestList[name] = request({
            name:name,
            cData:data,
            bank:msg.sender
        });

        return 1;
    }

    function AddCustomer(string memory name, string memory data) public checkInReq(name) returns(uint){
        customerList[name] = customer({
            name:name,
            cData:data,
            upVote:1,
            bank:msg.sender
        });

        RemoveRequest(customerList[name].name);
        return 1;
    }

    function RemoveRequest(string memory name) public checkInReq(name) returns(uint){
            delete requestList[name];
            return 1;
    }

    function RemoveCustomer(string memory name)
        public  checkInCust(name) returns(uint){
            delete customerList[name];
            return 1;
    }

    function modifyCustomer(string memory name, string memory data)public checkInCust(name) returns(uint){
            customerList[name].cData = data;
            return 1;
    }

    function viewCustomer(string memory name)public checkInCust(name) view returns(string memory){
        return customerList[name].cData;
    }

    function upVote(string memory name) public checkInCust(name) returns(uint){
        customerList[name].upVote += 1;
        return 1;
    }

    modifier checkInReq(string memory name){
        if(bytes(requestList[name].name).length == 0){
        revert("There is no such request");
        }
        _;
    }
    modifier checkInCust(string memory name){
        if(bytes(customerList[name].name).length == 0){
        revert("There is no such customer");
        }
        _;
    }

    modifier alreadyInReq(string memory name){
        if(bytes(requestList[name].name).length != 0){
            revert("Already present");
        }
        _;
    }

    modifier alreadyInCust(string memory name) {
        if(bytes(customerList[name].name).length != 0){
        revert("Already present");
        }
        _;
    }

}