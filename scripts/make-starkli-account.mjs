#!/usr/bin/env node
// Compute public key from private key and create starkli account config
import { ec } from "starknet";
import { writeFileSync } from "fs";

const PRIVATE_KEY = process.env.DOJO_PRIVATE_KEY;
const ACCOUNT_ADDRESS = process.env.DOJO_ACCOUNT_ADDRESS;
const CLASS_HASH = "0x036078334509b514626504edc9fb252328d1a240e4e948bef8d0c08dff45927f";
const OUT = "/tmp/starkli_account.json";

if (!PRIVATE_KEY || !ACCOUNT_ADDRESS) {
  console.error("Missing DOJO_PRIVATE_KEY or DOJO_ACCOUNT_ADDRESS");
  process.exit(1);
}

const pubKey = ec.starkCurve.getStarkKey(PRIVATE_KEY);
console.log("Public key:", pubKey);

const config = {
  version: 1,
  variant: {
    type: "open_zeppelin",
    version: 1,
    public_key: pubKey,
    legacy: false,
  },
  deployment: {
    status: "deployed",
    class_hash: CLASS_HASH,
    address: ACCOUNT_ADDRESS,
  },
};

writeFileSync(OUT, JSON.stringify(config, null, 2));
console.log("Account config written to", OUT);
