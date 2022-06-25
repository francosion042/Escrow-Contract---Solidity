const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

let EscrowContract

const initialize = async () => {
  const Escrow = await ethers.getContractFactory("Escrow");
  const escrow = await upgrades.deployProxy(Escrow, {kind: "uups", initializer: "initialize"});
  await escrow.deployed();

  EscrowContract = escrow
}

before(async () => {
  await initialize()
})

describe("Escrow", function () {
  it("Should confirm contract deployment", async function () {
    expect(EscrowContract.address).to.be.a("string")
  });
});
