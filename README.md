let provider, signer, farm;

const farmAddress = "YOUR_FARM_ADDRESS";

const abi = [
  "function deposit(uint256,uint256)",
  "function withdraw(uint256,uint256)",
  "function pendingReward(uint256,address) view returns(uint256)"
];

async function connect() {
  provider = new ethers.providers.Web3Provider(window.ethereum);
  await provider.send("eth_requestAccounts", []);

  signer = provider.getSigner();
  const address = await signer.getAddress();

  document.getElementById("wallet").innerText = address;

  farm = new ethers.Contract(farmAddress, abi, signer);
}

async function deposit() {
  let pid = document.getElementById("pid").value;
  let amount = ethers.utils.parseEther(document.getElementById("amount").value);

  await farm.deposit(pid, amount);
  document.getElementById("status").innerText = "Deposited!";
}

async function withdraw() {
  let pid = document.getElementById("withdrawPid").value;
  let amount = ethers.utils.parseEther(document.getElementById("withdrawAmount").value);

  await farm.withdraw(pid, amount);
  document.getElementById("status").innerText = "Withdrawn!";
}

async function checkRewards() {
  let pid = document.getElementById("rewardPid").value;
  let addr = await signer.getAddress();

  let reward = await farm.pendingReward(pid, addr);

  document.getElementById("status").innerText =
    "Rewards: " + ethers.utils.formatEther(reward);
}