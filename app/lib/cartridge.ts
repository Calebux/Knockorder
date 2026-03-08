import { ControllerConnector } from "@cartridge/connector";

// Sepolia Cartridge RPC
const SEPOLIA_RPC = "https://api.cartridge.gg/x/starknet/sepolia";

// STRK ERC-20 — same address on mainnet and Sepolia
export const STRK_ADDRESS =
  "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d";

// Game treasury — replace with your actual contract or multisig on Sepolia
export const TREASURY_ADDRESS =
  "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7";

// 1 STRK = 10^18
export const MATCH_FEE = "1000000000000000000";

let _connector: ControllerConnector | null = null;

export function getConnector(): ControllerConnector {
  if (!_connector) {
    _connector = new ControllerConnector({
      chains: [{ rpcUrl: SEPOLIA_RPC }],
      // Google + Discord let players skip WebAuthn passkey (avoids TLS cert errors)
      signupOptions: ["google", "discord", "webauthn"],
    });
  }
  return _connector;
}
