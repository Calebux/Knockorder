#!/usr/bin/env node
import { RpcProvider, Account, Contract } from "starknet";

const RPC_URL = process.env.STARKNET_RPC_URL;
const ACCOUNT_ADDRESS = process.env.DOJO_ACCOUNT_ADDRESS;
const PRIVATE_KEY = process.env.DOJO_PRIVATE_KEY;
const ADAPTER = process.env.ADAPTER_ADDRESS;
const AUTHORIZED = process.env.AUTHORIZED_ADDRESS;

if (!RPC_URL || !ACCOUNT_ADDRESS || !PRIVATE_KEY || !ADAPTER || !AUTHORIZED) {
  console.error("Missing env vars");
  process.exit(1);
}

const provider = new RpcProvider({ nodeUrl: RPC_URL });
const account = new Account({ provider, address: ACCOUNT_ADDRESS, signer: PRIVATE_KEY });

const abi = [
  {
    type: "interface",
    name: "IEgsAdapter",
    items: [
      {
        type: "function",
        name: "set_authorized_caller",
        inputs: [{ name: "caller", type: "core::starknet::contract_address::ContractAddress" }],
        outputs: [],
        state_mutability: "external",
      },
    ],
  },
];

const contract = new Contract({ abi, address: ADAPTER, providerOrAccount: account });
console.log("Calling set_authorized_caller on", ADAPTER);
console.log("Authorized caller:", AUTHORIZED);

const res = await contract.invoke("set_authorized_caller", [AUTHORIZED]);
console.log("TX:", res.transaction_hash);
await provider.waitForTransaction(res.transaction_hash);
console.log("Done! EndMatch is now authorized to call the EGS adapter.");
