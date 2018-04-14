var Migrations = artifacts.require("./Migrations.sol");
var SoftFloat = artifacts.require("./SoftFloat.sol")

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(SoftFloat);
};