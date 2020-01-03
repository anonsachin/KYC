const kyc_solution = artifacts.require("bank");

module.exports = function(deployer) {
  deployer.deploy(kyc_solution);
};