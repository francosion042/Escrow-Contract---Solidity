const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

const state = {
  Escrow: null,
  accounts: {
    initiator: "",
    partner: "",
  },
};

const initialize = async () => {
  const Contract = await ethers.getContractFactory("Escrow");
  const escrow = await upgrades.deployProxy(Contract, {
    kind: "uups",
    initializer: "initialize",
  });
  await escrow.deployed();

  state.Escrow = escrow;
};

before(async () => {
  await initialize();
  const [inititor, partner] = await ethers.getSigners();
  state.accounts.initiator = inititor.address;
  state.accounts.partner = partner.address;
});

describe("Escrow", function () {
  it("Should confirm contract deployment", async () => {
    await expect(state.Escrow.address).to.be.a("string");
  });

  it("should initiate an agreement", async () => {
    await expect(
      state.Escrow.initiateAgreement(
        state.accounts.partner,
        ethers.utils.parseEther("1"),
        5
      )
    ).to.emit(state.Escrow, "AgreementInitiated");
  });

  it("should get an agreement", async () => {

    const agreement = await expect(
      state.Escrow.initiateAgreement(
        state.accounts.partner,
        ethers.utils.parseEther("1"),
        5
      ))

      console.log(agreement)

    await expect(await state.Escrow.getAgreement(1))
      .to.be.an("array")
      .which.contains(
        state.accounts.initiator,
        state.accounts.partner,
        ethers.utils.parseEther("1"),
        ethers.BigNumber.from(5),
        false,
        0
      );
  });
});
