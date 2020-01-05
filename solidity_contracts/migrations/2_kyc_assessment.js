const Bank = artifacts.require("Banks");

module.exports = function(deployer) {
  deployer.deploy(Bank);
};