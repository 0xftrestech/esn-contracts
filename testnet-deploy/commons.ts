import { ethers } from 'ethers';
import { CustomProvider } from './custom-provider';

interface ExistingContractAddresses {
  nrtManager?: string;
  timeallyManager?: string;
  timeallyStakingTarget?: string;
  validatorSet?: string;
  validatorManager?: string;
  randomnessManager?: string;
  blockRewardManager?: string;
  prepaidEs?: string;
  dayswappers?: string;
  kycdapp?: string;
  timeallyclub?: string;
  timeAllyPromotionalBucket?: string;
  tsgap?: string;
}

// ATTENTION: Ensure NRT SECONDS_IN_MONTH is 0 for testnet
// testnet chain
export const existing: ExistingContractAddresses = {
  nrtManager: '0x89309551Fb7AbaaB85867ACa60404CDA649751d4',
  timeallyManager: '0x7F87f9830baB8A591E6f94fd1A47EE87560B0bB0',
  timeallyStakingTarget: '0xA3C6cf908EeeebF61da6e0e885687Cab557b5e3F',
  validatorSet: '0x8418249278d74D46014683A8029Fd6fbC88482a1',
  validatorManager: '0xE14D14bd8D0E2c36f5E4D00106417d8cf1000e22',
  randomnessManager: '0x44F70d80642998F6ABc424ceAf1E706a479De8Ce',
  blockRewardManager: '0x2AA786Cd8544c50136e5097D5E19F6AE10E02543',
  prepaidEs: '0x22E0940C1AE5D31B9efBaf7D674F7D62895FBde8',
  dayswappers: '0x4CaDa3B127fd31921127409a86A71D0a7Cb7A85b',
  kycdapp: '0xC4336494606203e3907539d5b462A5cb7853B3C6',
  timeallyclub: '0x6D57FaDF31e62E28Ab059f3dCd565df055428c57',
  timeAllyPromotionalBucket: '0xaDbA96fDA88B0Cbcf11d668FF6f7A29d062eD050',
  // tsgap: '0xb7eCCeAef09f917357253f09130A529E9F8b778d',
};
// local
// export const existing: ExistingContractAddresses = {
//   nrtManager: '0xAE519FC2Ba8e6fFE6473195c092bF1BAe986ff90',
//   timeallyManager: '0x73b647cbA2FE75Ba05B8e12ef8F8D6327D6367bF',
//   timeallyStakingTarget: '0x7d73424a8256C0b2BA245e5d5a3De8820E45F390',
//   validatorSet: '0x08425D9Df219f93d5763c3e85204cb5B4cE33aAa',
//   validatorManager: '0xA10A3B175F0f2641Cf41912b887F77D8ef34FAe8',
//   randomnessManager: '0x6E05f58eEddA592f34DD9105b1827f252c509De0',
//   blockRewardManager: '0x79EaFd0B5eC8D3f945E6BB2817ed90b046c0d0Af',
//   prepaidEs: '0x2Ce636d6240f8955d085a896e12429f8B3c7db26',
//   dayswappers: '0x59AF421cB35fc23aB6C8ee42743e6176040031f4',
//   kycdapp: '0x4fb87c52Bb6D194f78cd4896E3e574028fedBAB9',
//   timeallyclub: '0xEd8d61f42dC1E56aE992D333A4992C3796b22A74',
//   timeAllyPromotionalBucket: '0x47eb28D8139A188C5686EedE1E9D8EDE3Afdd543',
//   tsgap: '0xC85dE468d545eD44a986b31D1c5d604733FB4A33',
// };

export const providerETH = ethers.getDefaultProvider('rinkeby');

const network = {
  name: 'EraSwapNetwork',
  chainId: 5196,
  ensAddress: '0xC4336494606203e3907539d5b462A5cb7853B3C6',
};

export const providerESN = new CustomProvider(
  'https://node2.testnet.eraswap.network',
  // 'http://localhost:8545'
  network
);

if (!process.argv[2]) {
  throw '\nNOTE: Please pass your private key as comand line argument';
}

const wallet = new ethers.Wallet(process.argv[2]);
// const wallet = new ethers.Wallet(process.argv[2]);

// @ts-ignore
export const walletETH = wallet.connect(providerETH);

export const walletESN = wallet.connect(providerESN);

export const validatorAddresses = [
  '0x08d85bd1004e3e674042eaddf81fb3beb4853a22',
  '0xb4fb9d198047fe763472d58045f1d9341161eb73',
  '0x36560493644fbb79f1c38d12ff096f7ec5d333b7',
];
