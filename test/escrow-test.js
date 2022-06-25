const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

const state = {
  EscrowContract: null,
  EscrowProxy: null,
  accounts: {
    initiator: "",
    partner: "",
  }
};

const initialize = async () => {
  state.EscrowContract = await ethers.getContractFactory("Escrow");
  const escrow = await upgrades.deployProxy(state.EscrowContract, {
    kind: "uups",
    initializer: "initialize",
  });
  await escrow.deployed();

  state.EscrowProxy = escrow;

};

before(async () => {
  await initialize();
  const [inititor, partner] = await ethers.getSigners();
  state.accounts.initiator = inititor.address;
  state.accounts.partner = partner.address;
});

describe("Escrow", function () {
  it("Should confirm contract deployment", async () => {
    await expect(state.EscrowProxy.address).to.be.a("string");
  });

  it("should initiate an agreement", async () => {
    const Escrow = await state.EscrowContract.attach(state.EscrowProxy.address);

    // console.log(state.accounts.partner)
  
    await expect(
      await Escrow.initiateAgreement(
        state.accounts.partner,
        ethers.utils.parseEther("1"),
        5
      )
    )
      .to.emit(Escrow, "AgreementInitiated")
      .withArgs(
        state.accounts.initiator,
        state.accounts.partner,
        ethers.utils.parseEther("1"),
        5
      );
  });

  // it("should get an agreement", async () => {
  //   const Escrow = await state.EscrowContract.attach(state.EscrowProxy.address);

  //   await expect(
  //     await Escrow.getAgreement(1)
  //   )
  //   .to.returned()
  // })
});
