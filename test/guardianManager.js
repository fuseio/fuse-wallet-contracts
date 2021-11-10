const GuardianManager = require("../build/GuardianManager");
const GuardianStorage = require("../build/GuardianStorage");
const Wallet = require("../build/BaseWallet");
const Registry = require("../build/ModuleRegistry");
const DumbContract = require("../build/TestContract");
const NonCompliantGuardian = require("../build/NonCompliantGuardian");

const TestManager = require("../utils/test-manager");

describe.only("GuardianManager", function () {
    this.timeout(10000);

    const manager = new TestManager();

    let infrastructure = accounts[0].signer;
    let owner = accounts[1].signer;
    let guardian1 = accounts[2].signer;
    let guardian2 = accounts[3].signer;
    let guardian3 = accounts[4].signer;
    let guardian4 = accounts[5].signer;
    let guardian5 = accounts[6].signer;
    let nonowner = accounts[7].signer;

    let wallet, guardianStorage, guardianManager;

    beforeEach(async () => {
        deployer = manager.newDeployer();
        const registry = await deployer.deploy(Registry);
        guardianStorage = await deployer.deploy(GuardianStorage);
        guardianManager = await deployer.deploy(GuardianManager, {}, registry.contractAddress, guardianStorage.contractAddress);
        wallet = await deployer.deploy(Wallet);
        await wallet.init(owner.address, [guardianManager.contractAddress]);
    });

    describe("Adding Guardians", () => {
        describe("EOA Guardians", () => {
            it("should let the owner add EOA Guardians (blockchain transaction)", async () => {
                await guardianManager.from(owner).addGuardian(wallet.contractAddress, guardian1.address, { gasLimit: 500000 });
                let count = (await guardianStorage.guardianCount(wallet.contractAddress)).toNumber();
                let active = await guardianManager.isGuardian(wallet.contractAddress, guardian1.address);
                assert.isTrue(active, 'first guardian should be active');
                assert.equal(count, 1, '1 guardian should be active');

                await guardianManager.from(owner).addGuardian(wallet.contractAddress, guardian2.address, { gasLimit: 500000 });
                count = (await guardianStorage.guardianCount(wallet.contractAddress)).toNumber();
                active = await guardianManager.isGuardian(wallet.contractAddress, guardian2.address);
                assert.isTrue(active, 'second guardian should not yet be active');
                assert.equal(count, 2, 'second guardian should be active');
            });

            it("should only let the owner add an EOA guardian (blockchain transaction)", async () => {
                await assert.revert(guardianManager.from(nonowner).addGuardian(wallet.contractAddress, guardian1.address, { gasLimit: 500000 }), "adding from nonowner should throw");
            });

            it("should let the owner add an EOA guardian (relayed transaction)", async () => {
                await manager.relay(guardianManager, 'addGuardian', [wallet.contractAddress, guardian1.address], wallet, [owner])
                const count = (await guardianStorage.guardianCount(wallet.contractAddress)).toNumber();
                const active = await guardianManager.isGuardian(wallet.contractAddress, guardian1.address);
                assert.isTrue(active, 'first guardian should be active');
                assert.equal(count, 1, '1 guardian should be active');
            });

            it("should add many Guardians (blockchain transaction)", async () => {
                const guardians = [guardian1, guardian2, guardian3, guardian4, guardian5];
                let count, active;
                for (let i = 1; i <= 5; i++) {
                    await guardianManager.from(owner).addGuardian(wallet.contractAddress, guardians[i - 1].address, { gasLimit: 500000 });
                    count = (await guardianStorage.guardianCount(wallet.contractAddress)).toNumber();
                    active = await guardianManager.isGuardian(wallet.contractAddress, guardians[i - 1].address);
                    assert.equal(count, i, 'guardian ' + i + ' should be added');
                    assert.isTrue(active, 'guardian ' + i + ' should be active');
                }
            });

            it("should add many Guardians (relayed transaction)", async () => {
                const guardians = [guardian1, guardian2, guardian3, guardian4, guardian5];
                let count, active;
                for (let i = 1; i <= 3; i++) {
                    await manager.relay(guardianManager, 'addGuardian', [wallet.contractAddress, guardians[i - 1].address], wallet, [owner]);
                    count = (await guardianStorage.guardianCount(wallet.contractAddress)).toNumber();
                    active = await guardianManager.isGuardian(wallet.contractAddress, guardians[i - 1].address);
                    assert.equal(count, i, 'guardian ' + i + ' should be added');
                    assert.isTrue(active, 'guardian ' + i + ' should be active');
                }
            });
        });

        describe("Smart Contract Guardians", () => {

            let guardianWallet1, guardianWallet2, dumbContract;

            beforeEach(async () => {
                guardianWallet1 = await deployer.deploy(Wallet);
                await guardianWallet1.init(guardian1.address, [guardianManager.contractAddress]);
                guardianWallet2 = await deployer.deploy(Wallet);
                await guardianWallet2.init(guardian2.address, [guardianManager.contractAddress]);
                dumbContract = await deployer.deploy(DumbContract);
            });

            it("should let the owner add Smart Contract Guardians (blockchain transaction)", async () => {
                await guardianManager.from(owner).addGuardian(wallet.contractAddress, guardianWallet1.contractAddress, { gasLimit: 500000 });
                let count = (await guardianStorage.guardianCount(wallet.contractAddress)).toNumber();
                let active = await guardianManager.isGuardian(wallet.contractAddress, guardian1.address);
                assert.isTrue(active, 'first guardian owner should be recognized as guardian');
                active = await guardianManager.isGuardian(wallet.contractAddress, guardianWallet1.contractAddress);
                assert.isTrue(active, 'first guardian should be recognized as guardian');
                assert.equal(count, 1, '1 guardian should be active');

                await guardianManager.from(owner).addGuardian(wallet.contractAddress, guardianWallet2.contractAddress, { gasLimit: 500000 });
                count = (await guardianStorage.guardianCount(wallet.contractAddress)).toNumber();
                active = await guardianManager.isGuardian(wallet.contractAddress, guardian2.address);
                assert.isTrue(active, 'second guardian owner should be active');
                active = await guardianManager.isGuardian(wallet.contractAddress, guardianWallet2.contractAddress);
                assert.isTrue(active, 'second guardian should be active');
                assert.equal(count, 2, '2 guardians should be active');
            });

            it("should let the owner add a Smart Contract guardian (relayed transaction)", async () => {
                await manager.relay(guardianManager, 'addGuardian', [wallet.contractAddress, guardianWallet1.contractAddress], wallet, [owner])
                const count = (await guardianStorage.guardianCount(wallet.contractAddress)).toNumber();
                let active = await guardianManager.isGuardian(wallet.contractAddress, guardianWallet1.contractAddress);
                assert.isTrue(active, 'first guardian should be active');
                active = await guardianManager.isGuardian(wallet.contractAddress, guardian1.address);
                assert.isTrue(active, 'first guardian owner should be active');
                assert.equal(count, 1, '1 guardian should be active');
            });

            it("should not let owner add a Smart Contract guardian that does not have an owner manager", async () => {
                await assert.revert(guardianManager.from(owner).addGuardian(wallet.contractAddress, dumbContract.contractAddress, { gasLimit: 500000 }), "adding invalid guardian contract should throw");
            });
        });
    });

    describe("Revoking Guardians", () => {
        beforeEach(async () => {
            await guardianManager.from(owner).addGuardian(wallet.contractAddress, guardian1.address, { gasLimit: 500000 });
            await guardianManager.from(owner).addGuardian(wallet.contractAddress, guardian2.address, { gasLimit: 500000 });
            const count = (await guardianStorage.guardianCount(wallet.contractAddress)).toNumber();
            assert.equal(count, 2, '2 guardians should be added');
        });

        it("should revoke a guardian (blockchain transaction)", async () => {
            await guardianManager.from(owner).revokeGuardian(wallet.contractAddress, guardian1.address);
            count = (await guardianStorage.guardianCount(wallet.contractAddress)).toNumber();
            active = await guardianManager.isGuardian(wallet.contractAddress, guardian1.address);
            assert.isFalse(active, 'the revoked guardian should no longer be active');
            assert.equal(count, 1, 'the revoked guardian should be removed');
        });

        it("should add a guardian after a revoke (blockchain transaction)", async () => {
            await guardianManager.from(owner).revokeGuardian(wallet.contractAddress, guardian1.address);
            let count = (await guardianStorage.guardianCount(wallet.contractAddress)).toNumber();
            assert.equal(count, 1, 'there should be 1 guardian left');

            await guardianManager.from(owner).addGuardian(wallet.contractAddress, guardian3.address, { gasLimit: 500000 });
            count = (await guardianStorage.guardianCount(wallet.contractAddress)).toNumber();
            assert.equal(count, 2, 'there should be 2 guardians again');
        });
    });

    describe("Cancelling Pending Guardians", () => {
        let nonCompliantGuardian;
        beforeEach(async () => {
            await guardianManager.from(owner).addGuardian(wallet.contractAddress, guardian1.address, { gasLimit: 500000 });
            nonCompliantGuardian = await deployer.deploy(NonCompliantGuardian);
        });
        it("it should fail to add a non-compliant guardian", async () => {
            await assert.revert(guardianManager.from(owner).addGuardian(wallet.contractAddress, nonCompliantGuardian.contractAddress, { gasLimit: 2000000 }));
        });
    });
});