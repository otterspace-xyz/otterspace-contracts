import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";
import { ethers } from "hardhat";

let otterBadge: Contract;
let otterBadgeFactory: ContractFactory;

let owner: SignerWithAddress;
let wallet1: SignerWithAddress;

before(async () => {
  [owner, wallet1] = await ethers.getSigners();
  otterBadgeFactory = await ethers.getContractFactory("OtterBadge");
});

beforeEach(async () => {
  otterBadge = await otterBadgeFactory.deploy()
  await otterBadge.deployed()
});

describe("OtterBadge", function () {
  it("Should mint an NFT to the sender", async function () {
    // const OtterBadge = await ethers.getContractFactory("OtterBadge");
    // const otterBadge = await OtterBadge.deploy();
    // await otterBadge.deployed();

    const [owner, address1] = await ethers.getSigners();
    const tokenURI = "ipfs://badges/1234";

    let mintBadgeTxn = await otterBadge.mintBadge(owner.address, tokenURI);
    await mintBadgeTxn.wait();

    mintBadgeTxn = await otterBadge.mintBadge(address1.address, tokenURI);
    await mintBadgeTxn.wait();

    mintBadgeTxn = await otterBadge.mintBadge(owner.address, tokenURI);
    await mintBadgeTxn.wait();

    expect(await otterBadge.balanceOf(owner.address)).to.equal(2);
    expect(await otterBadge.balanceOf(address1.address)).to.equal(1);

    expect(await otterBadge.ownerOf(1)).to.equal(owner.address);
    expect(await otterBadge.ownerOf(2)).to.equal(address1.address);
    expect(await otterBadge.ownerOf(3)).to.equal(owner.address);
  });
});
