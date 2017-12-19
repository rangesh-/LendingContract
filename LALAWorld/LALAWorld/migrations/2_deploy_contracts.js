var ConvertLib = artifacts.require("./ConvertLib.sol");
var MetaCoin = artifacts.require("./MetaCoin.sol");
var LendingContract = artifacts.require("./LendingContract.sol");

module.exports = function(deployer) {
 deployer.deploy(LendingContract);
};
