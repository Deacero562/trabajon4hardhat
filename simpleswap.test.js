const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleSwap", function () {
let tokenA, tokenB, swap;
let owner, user;

async function getDeadline(seconds = 3600) {
const blockNum = await ethers.provider.getBlockNumber();
const block = await ethers.provider.getBlock(blockNum);
return block.timestamp + seconds;
}

beforeEach(async function () {
[owner, user] = await ethers.getSigners();

// Desplegar TokenA y TokenB
const Token = await ethers.getContractFactory("TokenA");
tokenA = await Token.deploy();
await tokenA.waitForDeployment();

tokenB = await Token.deploy();
await tokenB.waitForDeployment();

// Desplegar SimpleSwap
const Swap = await ethers.getContractFactory("SimpleSwap");
swap = await Swap.deploy();
await swap.waitForDeployment();

// Mint tokens al owner para pruebas
await tokenA.mint(owner.address, ethers.parseEther("1000000"));
await tokenB.mint(owner.address, ethers.parseEther("1000000"));

// Aprobar swap para mover tokens
await tokenA.approve(swap.target, ethers.parseEther("1000000"));
await tokenB.approve(swap.target, ethers.parseEther("1000000"));

// Agregar liquidez
const deadline = await getDeadline();
await swap.addLiquidity(
tokenA.target,
tokenB.target,
ethers.parseEther("1000"),
ethers.parseEther("1000"),
ethers.parseEther("900"),
ethers.parseEther("900"),
owner.address,
deadline
);

// Transferir tokens a user para tests
await tokenA.transfer(user.address, ethers.parseEther("100"));
await tokenB.transfer(user.address, ethers.parseEther("100"));
});

it("agrega liquidez correctamente", async function () {
const [reserveA, reserveB] = await swap.getReserves(tokenA.target, tokenB.target);
expect(reserveA).to.equal(ethers.parseEther("1000"));
expect(reserveB).to.equal(ethers.parseEther("1000"));
});

it("calcula el precio de swap correctamente", async function () {
const price = await swap.getPrice(tokenA.target, tokenB.target);
expect(price).to.be.gt(0);
});

it("realiza swap de token A a token B", async function () {
const userSwap = swap.connect(user);
await tokenA.connect(user).approve(swap.target, ethers.parseEther("10"));

const balanceBefore = await tokenB.balanceOf(user.address);
const deadline = await getDeadline();

await userSwap.swapExactTokensForTokens(
ethers.parseEther("10"),
0,
[tokenA.target, tokenB.target],
user.address,
deadline
);

const balanceAfter = await tokenB.balanceOf(user.address);
expect(balanceAfter).to.be.gt(balanceBefore);
});

it("realiza swap de token B a token A", async function () {
const userSwap = swap.connect(user);
await tokenB.connect(user).approve(swap.target, ethers.parseEther("10"));

const balanceBefore = await tokenA.balanceOf(user.address);
const deadline = await getDeadline();

await userSwap.swapExactTokensForTokens(
ethers.parseEther("10"),
0,
[tokenB.target, tokenA.target],
user.address,
deadline
);

const balanceAfter = await tokenA.balanceOf(user.address);
expect(balanceAfter).to.be.gt(balanceBefore);
});

it("falla con token inválido en getPrice", async function () {
const FakeToken = await ethers.getContractFactory("TokenA");
const fake = await FakeToken.deploy();
await fake.waitForDeployment();

await expect(
swap.getPrice(fake.target, fake.target)
).to.be.revertedWith("Identical tokens");
});

it("remueve liquidez correctamente", async function () {
const liquidityTokenAddress = await swap.getLiquidityToken(tokenA.target, tokenB.target);
const LiquidityToken = await ethers.getContractFactory("LiquidityToken");
const liquidityToken = LiquidityToken.attach(liquidityTokenAddress);

const liquidityBalance = await liquidityToken.balanceOf(owner.address);
const deadline = await getDeadline();

await swap.removeLiquidity(
tokenA.target,
tokenB.target,
liquidityBalance,
0,
0,
owner.address,
deadline
);

const [reserveA, reserveB] = await swap.getReserves(tokenA.target, tokenB.target);
expect(reserveA).to.equal(0);
expect(reserveB).to.equal(0);

expect(await tokenA.balanceOf(owner.address)).to.be.gt(ethers.parseEther("999000"));
expect(await tokenB.balanceOf(owner.address)).to.be.gt(ethers.parseEther("999000"));
});
});
