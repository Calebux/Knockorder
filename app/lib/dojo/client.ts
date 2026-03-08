"use client";

import { useMemo, useEffect } from "react";
import { DojoProvider } from "@dojoengine/core";
import { useAccount } from "@starknet-react/core";
import { setupWorld, type DojoWorldActions } from "./contracts.gen";
import { getDojoConfig } from "./config";

let cachedProvider: DojoProvider | null = null;
let cachedActions: DojoWorldActions | null = null;

function createProvider(manifest: unknown, rpcUrl: string): DojoProvider | null {
  if (!manifest || typeof (manifest as { world?: { address?: string } }).world?.address !== "string")
    return null;
  try {
    return new DojoProvider(manifest as any, rpcUrl);
  } catch {
    return null;
  }
}

/**
 * Returns Dojo world actions and config (Tyc pattern: static manifest from dojoConfig).
 * Only available when manifest has world address set (or NEXT_PUBLIC_DOJO_WORLD_ADDRESS).
 */
export function useDojoWorld() {
  const config = getDojoConfig();
  const { address: accountAddress, account } = useAccount();
  const manifest = config.manifest;

  const provider = useMemo(() => {
    if (!config.isEnabled || !manifest) return null;
    if (cachedProvider) return cachedProvider;
    const p = createProvider(manifest, config.rpcUrl);
    if (p) cachedProvider = p;
    return p;
  }, [config.isEnabled, config.rpcUrl, manifest]);

  const actions = useMemo(() => {
    if (!provider) return null;
    if (cachedActions) return cachedActions;
    cachedActions = setupWorld(provider);
    return cachedActions;
  }, [provider]);

  const isReady = Boolean(config.isEnabled && actions && accountAddress);

  // Seed default cards on-chain once per device (idempotent write)
  useEffect(() => {
    if (!actions || !account) return;
    if (typeof window !== "undefined" && localStorage.getItem("ko_cards_initialized_v1")) return;
    actions.InitCards.initDefaultCards(account)
      .then(() => localStorage.setItem("ko_cards_initialized_v1", "1"))
      .catch(() => { /* silent — cards may already exist */ });
  }, [actions, account]);

  return {
    config,
    provider,
    actions,
    accountAddress: accountAddress ?? null,
    isReady,
    loading: false,
  };
}
