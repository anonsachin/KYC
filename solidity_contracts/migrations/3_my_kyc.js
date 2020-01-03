const CustomerKYC = artifacts.require("CustomerKYC");

module.exports = function(deployer) {
  deployer.deploy(CustomerKYC);
};