"use client";

/**
 * Knock Order — Provable Games EGS integration
 *
 * Reads score and game_over state directly from the deployed KnockOrderEGS
 * adapter contract via RPC. No Torii / Denshokan indexer required for reads.
 *
 * The denshokan-sdk (@provable-games/denshokan-sdk) is installed and ready to
 * use for leaderboard queries once the contract is registered with the EGS
 * Registry via the Provable Games tooling.
 *
 * Adapter ABI (relevant subset):
 *   fn score(token_id: felt252) -> u64
 *   fn game_over(token_id: felt252) -> bool
 *   fn supports_interface(interface_id: felt252) -> bool
 */

import { useEffect, useState } from "react";
import { RpcProvider } from "starknet";
import { getDojoConfig } from "./config";

/** Address of the deployed KnockOrderEGS adapter — set via env var after deploy */
export const EGS_ADAPTER_ADDRESS =
  process.env.NEXT_PUBLIC_EGS_ADAPTER_ADDRESS ?? "";

/** EGS interface ID — XOR of IMinigame function selectors */
export const IMINIGAME_ID =
  "0x3d1730c22937da340212dec5546ff5826895259966fa6a92d1191ab068cc2b4";

export interface EgsMatchData {
  /** winner_wins * 100 + loser_wins  (e.g. 200 = 2-0, 302 = 3-2) */
  score: number;
  /** true once EndMatch has finalised and pushed the result on-chain */
  gameOver: boolean;
}

/**
 * React hook — polls the EGS adapter for the match's score and game_over
 * status every 10 s while game_over is false, then stops.
 * Returns null when matchId is not numeric / adapter not configured.
 */
export function useEgsScore(matchId: string | null): EgsMatchData | null {
  const [data, setData] = useState<EgsMatchData | null>(null);
  const config = getDojoConfig();

  useEffect(() => {
    if (!matchId || !EGS_ADAPTER_ADDRESS || !/^\d+$/.test(matchId)) return;

    const matchIdHex = "0x" + BigInt(matchId).toString(16);
    const rpc = new RpcProvider({ nodeUrl: config.rpcUrl });
    let stopped = false;

    const fetch = async () => {
      try {
        const [scoreResult, gameOverResult] = await Promise.all([
          rpc.callContract({
            contractAddress: EGS_ADAPTER_ADDRESS,
            entrypoint: "score",
            calldata: [matchIdHex],
          }),
          rpc.callContract({
            contractAddress: EGS_ADAPTER_ADDRESS,
            entrypoint: "game_over",
            calldata: [matchIdHex],
          }),
        ]);

        const score = Number(BigInt(scoreResult[0]));
        const gameOver = BigInt(gameOverResult[0]) !== BigInt(0);
        setData({ score, gameOver });

        // Stop polling once finalised
        if (gameOver) stopped = true;
      } catch {
        // Silent — adapter may not be deployed yet
      }

      if (!stopped) setTimeout(fetch, 10_000);
    };

    void fetch();
    return () => { stopped = true; };
  }, [matchId, config.rpcUrl]);

  return data;
}

/** Decode an EGS score into readable "W-L" round notation */
export function decodeEgsScore(score: number): string {
  if (score === 0) return "—";
  const winner = Math.floor(score / 100);
  const loser = score % 100;
  return `${winner}-${loser}`;
}
