/**
 * Dojo world config (Tyc pattern: single dojoConfig with static manifest + rpcUrl).
 * World address comes from manifest; env NEXT_PUBLIC_DOJO_WORLD_ADDRESS overrides when set.
 */
import { dojoConfig } from "./dojoConfig";

const worldAddressFromManifest =
  (dojoConfig.manifest as { world?: { address?: string } })?.world?.address ?? "";
const WORLD_ADDRESS =
  process.env.NEXT_PUBLIC_DOJO_WORLD_ADDRESS ?? worldAddressFromManifest;
const RPC_URL =
  process.env.NEXT_PUBLIC_DOJO_RPC_URL ??
  process.env.NEXT_PUBLIC_STARKNET_RPC_URL ??
  (dojoConfig as { rpcUrl?: string }).rpcUrl ??
  "https://api.cartridge.gg/x/starknet/sepolia";

export function getDojoConfig() {
  return {
    worldAddress: WORLD_ADDRESS,
    rpcUrl: RPC_URL,
    manifest: dojoConfig.manifest,
    isEnabled: Boolean(WORLD_ADDRESS),
  };
}

export type DojoConfig = ReturnType<typeof getDojoConfig>;
