#!/usr/bin/env node
/**
 * Deploy KnockOrderEGS as a standalone Starknet contract using starknet.js.
 * Usage: node scripts/deploy-egs-contract.mjs
 * Env required: STARKNET_RPC_URL, DOJO_ACCOUNT_ADDRESS, DOJO_PRIVATE_KEY
 */
import { readFileSync } from "fs";
import { Account, RpcProvider, json, CallData } from "starknet";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");
const KNOCK_ORDER = path.join(ROOT, "knock_order");

const RPC_URL = process.env.STARKNET_RPC_URL;
const ACCOUNT_ADDRESS = process.env.DOJO_ACCOUNT_ADDRESS;
const PRIVATE_KEY = process.env.DOJO_PRIVATE_KEY;

if (!RPC_URL || !ACCOUNT_ADDRESS || !PRIVATE_KEY) {
  console.error("Missing env: STARKNET_RPC_URL, DOJO_ACCOUNT_ADDRESS, DOJO_PRIVATE_KEY");
  process.exit(1);
}

const SIERRA_PATH = path.join(KNOCK_ORDER, "target/sepolia/dojo_starter_KnockOrderEGS.contract_class.json");
const CASM_PATH = path.join(KNOCK_ORDER, "target/sepolia/dojo_starter_KnockOrderEGS.compiled_contract_class.json");

console.log("=== KnockOrderEGS Deploy Script ===");
console.log("RPC:", RPC_URL);
console.log("Account:", ACCOUNT_ADDRESS);
console.log("Sierra:", SIERRA_PATH);
console.log("CASM:", CASM_PATH);

const provider = new RpcProvider({ nodeUrl: RPC_URL });
const account = new Account({
  provider,
  address: ACCOUNT_ADDRESS,
  signer: PRIVATE_KEY,
});

const sierra = json.parse(readFileSync(SIERRA_PATH, "utf-8"));
const casm = json.parse(readFileSync(CASM_PATH, "utf-8"));

console.log("\n--- Step 1: Declare KnockOrderEGS ---");
let classHash;
try {
  const declareResp = await account.declare({
    contract: sierra,
    casm,
  });
  console.log("Declare tx:", declareResp.transaction_hash);
  console.log("Class hash:", declareResp.class_hash);
  classHash = declareResp.class_hash;
  console.log("Waiting for declare tx...");
  await provider.waitForTransaction(declareResp.transaction_hash);
  console.log("Declared!");
} catch (e) {
  if (e.message && e.message.includes("already declared")) {
    // Parse class hash from error message or use known hash
    const match = e.message.match(/0x[a-fA-F0-9]+/);
    classHash = match ? match[0] : null;
    if (!classHash) {
      // Try to extract from error data
      console.log("Already declared. Error:", e.message);
      // The class is already declared, we need the hash - try to compute it
      const { hash } = await import("starknet");
      classHash = hash.computeSierraContractClassHash(sierra);
      console.log("Computed class hash:", classHash);
    } else {
      console.log("Already declared. Class hash:", classHash);
    }
  } else {
    throw e;
  }
}

if (!classHash) {
  console.error("Could not get class hash");
  process.exit(1);
}

console.log("\n--- Step 2: Deploy KnockOrderEGS ---");
// Constructor: owner: ContractAddress -> pass account address
const constructorCalldata = CallData.compile([ACCOUNT_ADDRESS]);
const deployResp = await account.deployContract({
  classHash,
  constructorCalldata,
});
console.log("Deploy tx:", deployResp.transaction_hash);
console.log("Waiting for deploy...");
await provider.waitForTransaction(deployResp.transaction_hash);

// starknet.js v6: contract_address is in the deploy response
const adapterAddress = deployResp.contract_address;
console.log("\n=== KnockOrderEGS deployed! ===");
console.log("Adapter address:", adapterAddress);
console.log("\nNext:");
console.log(`  sozo execute dojo_starter-EgsConfig set_adapter "${adapterAddress}" -P sepolia --wait`);
console.log(`  Set NEXT_PUBLIC_EGS_ADAPTER_ADDRESS=${adapterAddress} in Vercel`);
