pragma solidity ^0.5.9;

contract kyc {

    address admin;

    /*
    Struct for a customer
     */
    struct Customer {
        string userName;   //unique
        string data_hash;  //unique
        uint8 upvotes;
        uint rating;        // the rating is calculated using this formula = (number of votes*100/number of banks)
        address bank;       // if rating is greater than 50 move to final customer list
    }

    /*
    Struct for a Bank
     */
    struct Bank{
        address ethAddress;   //unique
        string bankName;
        string regNumber;       //unique
        uint rating;
        uint votes; // for upvoting
        uint kyc_count;
    }

    /*
    Struct for a KYC Request
     */
    struct KYCRequest {
        string userName;
        string data_hash;  //unique
        address bank;
        bool isAllowed;
    }

    /*
    Mapping a customer's username to the Customer struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(string => Customer) customers;
    string[] customerNames;

    /*
    Mapping a bank's address to the Bank Struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(address => Bank) banks;
    address[] bankAddresses;

    /*
    Mapping a customer's Data Hash to KYC request captured for that customer.
    This mapping is used to keep track of every kycRequest initiated for every customer by a bank.
     */
    mapping(string => KYCRequest) kycRequests;
    string[] customerDataList;

    /*
    Mapping a customer's user name with a bank's address
    This mapping is used to keep track of every upvote given by a bank to a customer
     */
    mapping(string => mapping(address => uint256)) upvotes;

    /*
    Mapping to represent the finalized list of customers
    This is customers name to the customer struct
     */
     mapping(string => Customer) finalized_customers;
     string[] verified;

     mapping (address=>mapping(address=>bool)) bankVotes; // To keep track of the banks that have voted for other banks
                                            // It is of the form voting bank => voted bank => bool

    mapping (string => string) Passwords;

    /**
     * Constructor of the contract.
     * We save the contract's admin as the account which deployed this contract.
     */
    constructor(address _admin) public {
        admin = _admin;
    }

    //Events
    event kycAdded(address indexed bank,string indexed name);
    event customerAdded(address indexed bank,string indexed name);
    event verificationDone(string indexed name,uint rating);

    /**
     * Record a new KYC request on behalf of a customer
     * The sender of message call is the bank itself
     * @param  {string} _userName The name of the customer for whom KYC is to be done
     * @param  {address} _bankEthAddress The ethAddress of the bank issuing this request
     * @return {bool}        True if this function execution was successful
     */
    function addKycRequest(string memory _userName, string memory _customerData) public isBank(msg.sender) returns (uint8) {
        // Check that the user's KYC has not been done before, the Bank is a valid bank and it is allowed to perform KYC.
        require(kycRequests[_customerData].bank == address(0), "This user already has a KYC request with same data in process.");
        //bytes memory uname = new bytes(bytes(_userName));
        // Save the timestamp for this KYC request.
        kycRequests[_customerData].data_hash = _customerData;
        kycRequests[_customerData].userName = _userName;
        kycRequests[_customerData].bank = msg.sender;
        banks[msg.sender].kyc_count = banks[msg.sender].kyc_count + 1;
        if((banks[msg.sender].rating)*2 > 100){ // keep the rating interms of a multiple of 100*actual_rating(decimal value)
            kycRequests[_customerData].isAllowed = true;
        }
        else{
            kycRequests[_customerData].isAllowed = false;
        }
        customerDataList.push(_customerData);
        emit kycAdded(msg.sender,_userName);
        return 1;
    }

    /**
     * Add a new customer
     * @param {string} _userName Name of the customer to be added
     * @param {string} _hash Hash of the customer's ID submitted for KYC
     */
    function addCustomer(string memory _userName, string memory _customerData) public isBank(msg.sender) returns (uint8){
        require(
            customers[_userName].bank == address(0),
        "This customer is already present, please call modifyCustomer to edit the customer data"
        );
        require(kycRequests[_userName].isAllowed == true,"It is not allowed"); // if invalid bank adds a request dont process it
        customers[_userName].userName = _userName;
        customers[_userName].data_hash = _customerData;
        customers[_userName].bank = msg.sender;
        customers[_userName].upvotes = 100;
        customers[_userName].rating = (customers[_userName].upvotes)/bankAddresses.length;
        customerNames.push(_userName);
        upvotes[_userName][msg.sender] = now;//storing the timestamp when vote was casted, not required though, additional
        emit customerAdded(msg.sender,_userName);
        return 1;
    }

    /**
     * Remove KYC request
     * @param  {string} _userName Name of the customer
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function removeKYCRequest(string memory _userName) public isBank(msg.sender) returns (uint8) {
        uint8 k = 0;
        for (uint256 i = 0; i < customerDataList.length; i++){
            if (stringsEquals(kycRequests[customerDataList[i]].userName,_userName)) {
                delete kycRequests[customerDataList[i]];
                for(uint j = i+1;j < customerDataList.length;j++)
                {
                    customerDataList[j-1] = customerDataList[j];
                }
                customerDataList.length --;
                k = 1;
            }
        }
        return k; // 0 is returned if no request with the input username is found.
    }

    /**
     * Remove customer information
     * @param  {string} _userName Name of the customer
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function removeCustomer(string memory _userName) public isBank(msg.sender) returns (uint8) {
            for(uint i = 0;i < customerNames.length;i++)
            {
                if(stringsEquals(customerNames[i],_userName))
                {
                    delete customers[_userName];
                    for(uint j = i+1;j < customerNames.length;j++)
                    {
                        customerNames[j-1] = customerNames[j];
                    }
                    customerNames.length--;
                    if(removeFromVerified(_userName) == 1){ //if customer is verified it is deleted
                        for(uint j = 0;j<bankAddresses.length;j++){ // delete votes
                            if(upvotes[_userName][bankAddresses[j]] != 0){
                            delete upvotes[_userName][bankAddresses[j]];
                            }
                        }
                    }
                    return 1;
                }

            }
            return 0;
    }

    /**
     * Edit customer information
     * @param  {public} _userName Name of the customer
     * @param  {public} _hash New hash of the updated ID provided by the customer
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function modifyCustomer(string memory _userName, string memory _newcustomerData) public isBank(msg.sender) returns (uint8){
        for(uint i = 0;i < customerNames.length;i++) {
             if(stringsEquals(customerNames[i],_userName)){
                if(removeFromVerified(_userName) == 1){// this function checks if the customer is verified if so deletes it from the list
                        customers[_userName].data_hash = _newcustomerData; // and only then updates the data
                        customers[_userName].rating = 0;
                        customers[_userName].upvotes = 0;
                        customers[_userName].bank = msg.sender;
                    }
                    for(uint j = 0;j<bankAddresses.length;j++){ // delete votes
                        if(upvotes[_userName][bankAddresses[j]] != 0){
                        delete upvotes[_userName][bankAddresses[j]];
                        }
                    }
                    return 1;
                }
            }
            return 0;
    }

    /**
     * View customer information
     * @param  {public} _userName Name of the customer
     * @return {Customer}         The customer struct as an object
     */
    function viewCustomer(string memory _userName) public view returns (string memory, string memory, uint8, address) {
        return (customers[_userName].userName, customers[_userName].data_hash, customers[_userName].upvotes, customers[_userName].bank);
    }

    /*
     * Moves the customer to the verified list once rating is greater than 50%
     * @param {private} name Name of the customer
     * @param {private} good The Customer struct object;
    */
    function addToVerified(string memory name,Customer memory good)private returns(uint8){
        for(uint i = 0;i<verified.length;i++){
            if(stringsEquals(verified[i],name)){
                return 0;
            }
        }
        finalized_customers[name] = good;
        verified.push(name);
        emit verificationDone(name,good.rating);
        return 1;
    }
    // Remove from Verified
    // @param {private} name Name of the customer
    function removeFromVerified(string memory name)private returns(uint8){
        for(uint i = 0;i<verified.length;i++){
            if(stringsEquals(verified[i],name)){
                delete finalized_customers[name];
                for(uint j = i+1; j<verified.length;j++){
                    verified[j-1] = verified[j];
                }
                verified.length--;
                return 1;
            }
        }
        return 0;
    }

    /**
     * Add a new upvote from a bank
     * @param {public} _userName Name of the customer to be upvoted
     */
    function Upvote(string memory _userName) public isBank(msg.sender) returns (uint8) {
        require(upvotes[_userName][msg.sender] == 0,"You have already cast your vote");
        for(uint i = 0;i < customerNames.length;i++)
            {
                if(stringsEquals(customerNames[i],_userName))
                {
                    customers[_userName].upvotes = customers[_userName].upvotes + 100;
                    customers[_userName].rating = (customers[_userName].upvotes)/bankAddresses.length;
                    upvotes[_userName][msg.sender] = now;//storing the timestamp when vote was casted, not required though, additional
                    if(customers[_userName].rating > 50){
                        addToVerified(_userName,customers[_userName]);
                    }
                    return 1;
                }
            }
            return 0;
    }

// if you are using string, you can use the following function to compare two strings
// function to compare two string value
// This is an internal fucntion to compare string values
// @Params - String a and String b are passed as Parameters
// @return - This function returns true if strings are matched and false if the strings are not matching
    function stringsEquals(string storage _a, string memory _b) internal view returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;
        // @todo unroll this loop
        for (uint i = 0; i < a.length; i ++)
        {
            if (a[i] != b[i])
                return false;
        }
        return true;
    }
/*
 * This function returns all the request of a bank that are not yet been finalized
 * @param {public} bank Address of the bank in question
*/
    function getBankRequests(address bank)public view returns(bytes32[] memory,bytes32[] memory,bool[] memory){
        bytes32[] memory userNames;
        bytes32[] memory hashes;
        bool[] memory allowed;
        uint j = 0;
        for(uint i = 0;i<customerDataList.length; i++){
            if(kycRequests[customerDataList[i]].bank == bank){
                if(finalized_customers[kycRequests[customerDataList[i]].userName].bank == address(0)){ // this to check if the request has been finalized
                    userNames[j] = bytes(kycRequests[customerDataList[i]].userName)[0]; // sending only the first string as array of arrys not properly implemented yet
                    hashes[j] = bytes(kycRequests[customerDataList[i]].data_hash)[0]; // sending only the first string as the hash is just one long string and array of arrys not properly implemented yet
                    allowed[j] = kycRequests[customerDataList[i]].isAllowed;
                    j++;
                }
            }
        }
        return (userNames,hashes,allowed);
    }

    /*
    * This function is up voting a bank only if it previously hasn't
    * @param {public} vote Address of the bank to be upvoted
    */

    function upVoteBank(address vote)public isABank(msg.sender) returns(uint8){
        if(bankVotes[msg.sender][vote] == false){
            bankVotes[msg.sender][vote] = true;
            banks[vote].votes = banks[vote].votes + 100;
            banks[vote].rating = banks[vote].votes/bankAddresses.length;
            return 1;
        }
        return 0;
    }
    // To make sure only banks can call the functionError: CompileError: UnimplementedFeatureError: Encoding type "structs
    modifier isABank(address bank){
        require(banks[bank].ethAddress != address(0),"you are not a bank");
        _;
    }

    //Get customer rating
    function getCustomerRating(string memory name)public view returns(uint){
        return customers[name].rating;
    }

    // Bank's rating
    function getBankRating(address bank)public view returns(uint){
        return banks[bank].rating;
    }

    // Get the bank that made the last changed to the customer data
    function retrieveAccessHist(string memory name)public view returns(address){
        return customers[name].bank;
    }

    // returning individual bank details unable to return structs
    function getBankDetails(address bank)public view returns(address,string memory,string memory,uint,uint,uint){
        Bank memory ret = banks[bank];
        return (
            ret.ethAddress,
            ret.bankName,
            ret.regNumber,
            ret.rating,
            ret.votes,
            ret.kyc_count
        );
    }

    // Basic Password setting
    function setPassword(string memory name,string memory password)
        public isABank(msg.sender) returns(bool){
            Passwords[name] = password;
            return true;
        }

    //Checks if you are a registered bank
    modifier isBank(address bank){
        bool isB = false;
        for(uint i = 0;i<bankAddresses.length;i++){
            if(bankAddresses[i] == bank){
                isB = true;
                break;
            }
        }
        require(isB == true,"Not a bank");
        _;
    }

}