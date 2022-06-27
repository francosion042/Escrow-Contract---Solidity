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
  state.accounts.initiator = inititor;
  state.accounts.partner = partner;
});

describe("Escrow", function () {
  it("Should confirm contract deployment", async () => {
    await expect(state.Escrow.address).to.be.a("string");
  });

  it("should initiate an agreement", async () => {
    await expect(
      state.Escrow.initiateAgreement(
        state.accounts.partner.address,
        ethers.utils.parseEther("1"),
        5
      )
    ).to.emit(state.Escrow, "AgreementInitiated");
  });

  it("should get an agreement", async () => {
    await expect(await state.Escrow.getAgreement(1))
      .to.be.an("array")
      .which.contains(
        state.accounts.initiator.address,
        state.accounts.partner.address,
        ethers.utils.parseEther("1"),
        ethers.BigNumber.from(5),
        false,
        0
      );
  });

  it("partner should sign agreement", async () => {
    await expect(
      state.Escrow.connect(state.accounts.partner).signAgreement(1)
    ).to.emit(state.Escrow, "AgreementSigned");
  })

  it("partner should deposit agreement amount", async () => {
    const agreement  = await state.Escrow.getAgreement(1)

    const options = { value: ethers.utils.parseEther(ethers.utils.formatEther(agreement.agreementAmount)) };
    await expect(
      state.Escrow.connect(state.accounts.partner).deposit(1, options)
    ).to.emit(state.Escrow, "AgreementAmountDeposited");
  })

  it("partner should confirm agreement fulfilment", async () => {
    await expect(
      state.Escrow.connect(state.accounts.partner).confirmFulfilment(1)
    ).to.emit(state.Escrow, "AgreementFulfilmentConfirmed");
  })
});
