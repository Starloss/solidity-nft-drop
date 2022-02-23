const { expect } = require("chai");
const { ethers, network } = require("hardhat");

describe("ERC721 Token", () => {
    let ERC721TokenFactory, ERC721Token, owner, user1, user2;

    beforeEach(async () => {
        ERC721TokenFactory = await ethers.getContractFactory("ERC721Token");
        ERC721Token = await ERC721TokenFactory.deploy();
        [owner, user1, user2, _] = await ethers.getSigners();
    });

    describe("Deployment", () => {
        it("Should set the right owner", async () => {
            expect(await ERC721Token.isAdmin(owner.address)).to.be.equal(true);
            expect(await ERC721Token.isMinter(owner.address)).to.be.equal(false);
        });

        it("Should set the right admin", async () => {
            expect(await ERC721Token.owner()).to.be.equal(owner.address);
        });

        it("Should set the right admin role to the minter role", async () => {
            expect(await ERC721Token.getRoleAdmin(ERC721Token.MINTER_ROLE())).to.be.equal(await ERC721Token.ADMIN_ROLE());
        });
        
        it("Should set the right hidden metadata URI", async () => {
            expect(await ERC721Token.hiddenMetadataUri()).to.be.equal("ipfs://Qmetig1Cdep14CmpfyM63aiErkSovse2ge7zxzXpnxVypB/hidden.json");
        });
    });

    describe("Primary Functions", () => {
        beforeEach(async () => {
            await ERC721Token.startContract();
            await ERC721Token.grantMinterRole(user1.address);
        });

        it("Should let mint", async () => {
            await ERC721Token.connect(user1).mint(1, { value: ethers.utils.parseEther("0.01") });
            await network.provider.send("evm_mine");

            let user1Wallet = await ERC721Token.walletOfOwner(user1.address);
            expect(user1Wallet[0]).to.be.equal(1);
        });

        it("Should let burn", async () => {
            await ERC721Token.connect(user1).mint(1, { value: ethers.utils.parseEther("0.01") });
            await network.provider.send("evm_mine");
    
            await ERC721Token.connect(user1).burn(1);
            await network.provider.send("evm_mine");

            user1Wallet = await ERC721Token.walletOfOwner(user1.address);
            expect(user1Wallet.length).to.be.equal(0);
        });
    });

    describe("Role Access", () => {
        it("Should let set the Minter Role to all users", async () => {
            await ERC721Token.grantMinterRole(user1.address);
            expect(await ERC721Token.isMinter(user1.address)).to.be.equal(true);
            expect(await ERC721Token.isAdmin(user1.address)).to.be.equal(false);
            
            await ERC721Token.grantMinterRole(user2.address);
            expect(await ERC721Token.isMinter(user2.address)).to.be.equal(true);
            expect(await ERC721Token.isAdmin(user1.address)).to.be.equal(false);
        });
        
        it("Should let a user with Minter Role to execute Minter functions", async () => {
            await ERC721Token.startContract();
            await ERC721Token.grantMinterRole(user1.address);

            await ERC721Token.connect(user1).mint(1, { value: ethers.utils.parseEther("0.01") });
            await network.provider.send("evm_mine");

            let user1Wallet = await ERC721Token.walletOfOwner(user1.address);
            expect(user1Wallet.length).to.be.equal(1);
        });

        it("Should fail if a user without Minter Role tries to execute Minter functions", async () => {
            await ERC721Token.startContract();

            await expect(
                ERC721Token
                .connect(user1)
                .mint(1)
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.MINTER_ROLE());
        });

        it("Should let a user with Admin Role to execute Admin functions", async () => {
            expect(await ERC721Token.state()).to.be.equal(0);
            await ERC721Token.startContract();
            expect(await ERC721Token.state()).to.be.equal(1);

            await ERC721Token.mintForAddress(3, user1.address);
            await network.provider.send("evm_mine");
            
            let user1Wallet = await ERC721Token.walletOfOwner(user1.address);
            expect(user1Wallet.length).to.be.equal(3);

            await ERC721Token.setRevealed(true);
            expect(await ERC721Token.revealed()).to.be.equal(true);
            
            await ERC721Token.setCost(ethers.utils.parseEther("0.03"));
            expect(await ERC721Token.cost()).to.be.equal(ethers.utils.parseEther("0.03"));

            await ERC721Token.setMaxMintAmountPerTx(10);
            expect(await ERC721Token.maxMintAmountPerTx()).to.be.equal(10);

            await ERC721Token.setHiddenMetadataUri("Hi");
            expect(await ERC721Token.hiddenMetadataUri()).to.be.equal("Hi");

            await ERC721Token.setUriPrefix("Hi");
            expect(await ERC721Token.uriPrefix()).to.be.equal("Hi");

            await ERC721Token.setUriSuffix("Hi");
            expect(await ERC721Token.uriSuffix()).to.be.equal("Hi");

            await ERC721Token.pause();
            expect(await ERC721Token.paused()).to.be.equal(true);

            await ERC721Token.unpause();
            expect(await ERC721Token.paused()).to.be.equal(false);

            await ERC721Token.setAddressInWhitelist(user1.address, true);
            expect(await ERC721Token.whitelist(user1.address)).to.be.equal(true);

            await ERC721Token.setAddressInWhitelist(user1.address, false);
            expect(await ERC721Token.whitelist(user1.address)).to.be.equal(false);

            await ERC721Token.grantMinterRole(user1.address);
            expect(await ERC721Token.isMinter(user1.address)).to.be.equal(true);

            await ERC721Token.connect(user1).mint(10, { value: ethers.utils.parseEther("3") });
            await network.provider.send("evm_mine");

            expect(await ERC721Token.withdraw());

            await ERC721Token.revokeMinterRole(user1.address);
            expect(await ERC721Token.isMinter(user1.address)).to.be.equal(false);
        });

        it("Should fail if a user without Admin Role try to execute Admin functions", async () => {
            await ERC721Token.startContract();

            await expect(
                ERC721Token
                .connect(user1)
                .startContract()
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());

            await expect(
                ERC721Token
                .connect(user1)
                .mintForAddress(3, user1.address)
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());

            await expect(
                ERC721Token
                .connect(user1)
                .setRevealed(true)
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());
            
            await expect(
                ERC721Token
                .connect(user1)
                .setCost("1")
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());

            await expect(
                ERC721Token
                .connect(user1)
                .setMaxMintAmountPerTx(300)
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());

            await expect(
                ERC721Token
                .connect(user1)
                .setHiddenMetadataUri("Hidden")
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());

            await expect(
                ERC721Token
                .connect(user1)
                .setUriPrefix("hi")
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());

            await expect(
                ERC721Token
                .connect(user1)
                .setUriSuffix("Hi")
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());

            await expect(
                ERC721Token
                .connect(user1)
                .pause()
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());

            await expect(
                ERC721Token
                .connect(user1)
                .unpause()
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());

            await expect(
                ERC721Token
                .connect(user1)
                .setAddressInWhitelist(user1.address, true)
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());

            await expect(
                ERC721Token
                .connect(user1)
                .setAddressInWhitelist(owner.address, false)
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());

            await expect(
                ERC721Token
                .connect(user1)
                .grantMinterRole(user1.address)
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());

            await expect(
                ERC721Token
                .connect(user1)
                .revokeMinterRole(owner.address)
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());

            await expect(
                ERC721Token
                .connect(user1)
                .withdraw()
            )
            .to
            .be
            .revertedWith(`AccessControl: account ` + user1.address.toLowerCase() + ` is missing role ` + await ERC721Token.ADMIN_ROLE());
        });
    });

    describe("Hidden/Revealed URI", () => {
        beforeEach(async () => {
            await ERC721Token.startContract();
            await ERC721Token.grantMinterRole(user1.address);

            await ERC721Token.connect(user1).mint(1, { value: ethers.utils.parseEther("0.01") });
            await network.provider.send("evm_mine");
        });

        it("Should get Hidden URI if not revealed", async () => {
            expect(await ERC721Token.tokenURI(1)).to.be.equal("ipfs://Qmetig1Cdep14CmpfyM63aiErkSovse2ge7zxzXpnxVypB/hidden.json");
        });

        it("Should get Real URI if revealed", async () => {
            await ERC721Token.setUriPrefix("revealed/");
            await ERC721Token.setRevealed(true);

            expect(await ERC721Token.tokenURI(1)).to.be.equal("revealed/1.json");
        });

        it("Should fail if trying to get the URI of a Token that not exist", async () => {
            await expect(
                ERC721Token
                .tokenURI(2)
            )
            .to
            .be
            .revertedWith("ERC721Metadata: URI query for nonexistent token");
        });
    });

    describe("Pausable", () => {
        beforeEach(async () => {
            await ERC721Token.startContract();
            await ERC721Token.grantMinterRole(user1.address);
        });

        it("Should works if the contract is not paused", async () => {
            await ERC721Token.connect(user1).mint(1, { value: ethers.utils.parseEther("0.01") });
            await network.provider.send("evm_mine");

            let user1Wallet = await ERC721Token.walletOfOwner(user1.address);
            expect(user1Wallet.length).to.be.equal(1);

            await ERC721Token.mintForAddress(1, user2.address);
            await network.provider.send("evm_mine");

            let user2Wallet = await ERC721Token.walletOfOwner(user2.address);
            expect(user2Wallet.length).to.be.equal(1);

            await ERC721Token.connect(user1).burn(1);
            await network.provider.send("evm_mine");

            user1Wallet = await ERC721Token.walletOfOwner(user1.address);
            expect(user1Wallet.length).to.be.equal(0);
        });

        it("Should fails if the contract is paused", async () => {
            await ERC721Token.pause();

            await expect(
                ERC721Token
                .connect(user1)
                .mint(1, { value: ethers.utils.parseEther("0.01") })
            )
            .to
            .be
            .revertedWith("Pausable: paused");

            await expect(
                ERC721Token
                .mintForAddress(1, user1.address)
            )
            .to
            .be
            .revertedWith("Pausable: paused");

            await expect(
                ERC721Token
                .connect(user1)
                .burn(1)
            )
            .to
            .be
            .revertedWith("Pausable: paused");
        });
    });

    describe("Whitelist", () => {
        beforeEach(async () => {
            await ERC721Token.grantMinterRole(user1.address);
            await ERC721Token.grantMinterRole(user2.address);
            await ERC721Token.setAddressInWhitelist(user1.address, true);
        });

        it("Should let whitelisted mint before starts", async () => {
            await ERC721Token.connect(user1).mint(1, { value: ethers.utils.parseEther("0.01") });
            await network.provider.send("evm_mine");

            let user1Wallet = await ERC721Token.walletOfOwner(user1.address);
            expect(user1Wallet.length).to.be.equal(1);
        });

        it("Should fail if a not whitelisted mint before starts", async () => {
            await expect(
                ERC721Token
                .connect(user2)
                .mint(1, { value: ethers.utils.parseEther("0.01") })
            )
            .to
            .be
            .revertedWith("The contract has not started yet!");
        });
    });
});