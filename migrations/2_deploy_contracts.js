var ComLib = artifacts.require("./ComLib.sol");
var TokenERC20 = artifacts.require("./TokenERC20.sol");
var HealthContract = artifacts.require("./HealthContract.sol");

module.exports = function(deployer) {
  deployer.deploy(TokenERC20);//, {gas: 4612388});
  deployer.deploy(ComLib);//, {gas: 4612388});
  deployer.link(ComLib, HealthContract);
  deployer.link(TokenERC20, HealthContract);
  deployer.deploy(HealthContract);//, {gas: 4612388});

};
