/**
 * Dojo config (Tyc pattern): static manifest + createDojoConfig.
 * Copy the real manifest from knock_order target/sepolia (sozo migrate output) to this folder as manifest.json,
 * or replace world.address in this manifest after deploy.
 */
import { createDojoConfig } from "@dojoengine/core";
import manifest from "./manifest.json";

const rpcUrl =
  process.env.NEXT_PUBLIC_DOJO_RPC_URL ??
  process.env.NEXT_PUBLIC_STARKNET_RPC_URL ??
  "https://api.cartridge.gg/x/starknet/sepolia";

export const dojoConfig = createDojoConfig({
  manifest,
  rpcUrl,
});
