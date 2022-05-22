//import { RelayClient } from 'defender-relay-client';
const { ethers } = require('ethers');
const { RelayClient } = require('defender-relay-client');
require('dotenv').config();


const { DefenderRelayProvider, DefenderRelaySigner } = require('defender-relay-client/lib/ethers');
const credentials = { apiKey: process.env.API_KEY, apiSecret: process.env.API_SECRET };
console.log(credentials);
const provider = new DefenderRelayProvider(credentials);
const MPWABI = require('./abi/MWP.json');
const VENDORABI = require('./abi/Vendor.json');
//console.log(MPWABI);

const relayer = new RelayClient({ apiKey: process.env.API_KEY, apiSecret: process.env.API_SECRET });

const signer = new DefenderRelaySigner(credentials, provider, { speed: 'fast' });

const erc20 = new ethers.Contract(process.env.CONTRACTADDRESSMWP, MPWABI, signer);

const Vendor = new ethers.Contract(process.env.CONTRACTADDRESSVENDOR, VENDORABI, signer);

async function transfer(){
    const tx = await erc20.functions.transfer('0x88f800B8D198eC07F80883dBa087067D15Bf307d', (1e18).toString());

    const mined = await tx.wait();
    //console.log(mined);
    console.log(tx);
} 
async function send(){
    const tx = await relayer.sendTransaction({
        to: '0x5b062482C4402d90875426FE72bb223e49bE62C5',
        value: '0x16345785d8a0000',
        data: '0x5af3107a',
        speed: 'fast',
        gasLimit: 100000,
    });
    console.log(tx);
}
async function SetWhiteList(address){
    const tx = await Vendor.functions.setWhiteList(address);

    const mined = await tx.wait();
    //console.log(mined);
    console.log(tx);
} 

async function BuyPix(address,value){
    const tx = await Vendor.functions.BuyPix(address,value);

    const mined = await tx.wait();
    //console.log(mined);
    console.log(tx);
} 


async function main(){
    //transfer();
    SetWhiteList("0x88f800B8D198eC07F80883dBa087067D15Bf307d");
    BuyPix("0x88f800B8D198eC07F80883dBa087067D15Bf307d",(1e18).toString());
    //send();
}
main();