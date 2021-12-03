const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('Property Contract', () => {
  let Token, token, owner, hoaAdmin, treasuryAdmin, defaultAdmin;

  beforeEach(async () => {
    Token = await ethers.getContractFactory('PropertyToken');
    [owner, hoaAdmin, treasuryAdmin, defaultAdmin, _] = await ethers.getSigners();
    const constructorParams = {
      //string uri_,
      uri_ = "https://ipfs.io/ipfs/QmUeGFH1YszzkVpZcNpvYyszwPoXjWzzXhXG5mm3imdtwL",
      //address treasury,
      treasury = treasuryAdmin.address,
      //bytes _parentHash,
      _parentHash = Buffer.from('QmUeGFH1YszzkVpZcNpvYyszwPoXjWzzXhXG5mm3imdtwL', 'utf8'),
      //address _propertyAddress
      _propertyAddress = owner.address,
    }
    token = await Token.deploy(
      constructorParams.uri_,
      constructorParams.treasury,
      constructorParams._parentHash,
      constructorParams._propertyAddress
    );
  });

  // describe('Deployment', () => {
  //   it('Should set the right owner', async () => {
  //     expect(await token.owner()).to.equal(owner.address);
  //   })
  // })
})