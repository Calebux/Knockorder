"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { useGameStore } from "../lib/gameStore";
import { useAccount, useConnect } from "@starknet-react/core";
import { getConnector } from "../lib/cartridge";
import { useDojoWorld } from "../lib/dojo";
import { RpcProvider } from "starknet";

const BG_IMAGE =
  "https://www.figma.com/api/mcp/asset/391bcf4f-350f-4a5a-8d08-9aad39c53e12";
const AVATAR_IMAGE =
  "https://www.figma.com/api/mcp/asset/d5d821a8-1bb6-4dd7-baf8-1b62a43e7019";
const LOGO_IMAGE =
  "https://www.figma.com/api/mcp/asset/9980f06e-500f-4857-a744-9658e83e286f";

type MatchType = "casual" | "ranked" | "tourney";

export default function CreateMatch() {
  const [matchType, setMatchType] = useState<MatchType>("ranked");
  const [opponentAddress, setOpponentAddress] = useState("");
  const [dojoCreating, setDojoCreating] = useState(false);
  const [dojoError, setDojoError] = useState<string | null>(null);
  const router = useRouter();
  const resetMatch = useGameStore((s) => s.resetMatch);
  const setMatchId = useGameStore((s) => s.setMatchId);
  const setCartridgeUsername = useGameStore((s) => s.setCartridgeUsername);
  const cartridgeUsername = useGameStore((s) => s.cartridgeUsername);

  const { connect } = useConnect();
  const { status, account } = useAccount();
  const { isReady: dojoReady, actions: dojoActions, config: dojoConfig } = useDojoWorld();

  // Open Cartridge popup if not already connected
  useEffect(() => {
    if (status === "disconnected") {
      connect({ connector: getConnector() });
    }
  }, [status, connect]);

  // Fetch and store username once connected
  useEffect(() => {
    if (status !== "connected") return;
    const usernamePromise = getConnector()?.username();
    usernamePromise?.then((name) => {
      setCartridgeUsername(name ?? null);
    }).catch(() => { /* silent */ });
  }, [status, setCartridgeUsername]);

  const handleCreateMatch = async () => {
    if (dojoReady && dojoActions && account && opponentAddress.trim()) {
      setDojoError(null);
      setDojoCreating(true);
      try {
        const res = await dojoActions.MatchSetup.createMatch(
          account,
          opponentAddress.trim() as `0x${string}`,
          matchType === "tourney" ? 5 : 3
        );
        const txHash = res.transaction_hash;
        const rpc = new RpcProvider({ nodeUrl: dojoConfig.rpcUrl });
        const receipt = await rpc.waitForTransaction(txHash, { retryInterval: 1000 });
        const receiptAny = receipt as unknown as { events?: { keys?: unknown[]; data?: string[] }[] };
        const matchIdEvent = receiptAny.events?.find(
          (e) => e.keys?.some((k) => typeof k === "string" && k.includes("MatchCreated"))
        );
        const matchIdFromEvent = matchIdEvent?.data?.[0];
        const newMatchId = matchIdFromEvent !== undefined ? String(matchIdFromEvent) : `tx-${txHash.slice(0, 10)}`;
        resetMatch();
        setMatchId(newMatchId);
        router.push("/ready");
      } catch (err) {
        setDojoError(err instanceof Error ? err.message : "Transaction failed");
      } finally {
        setDojoCreating(false);
      }
      return;
    }
    resetMatch();
    router.push("/ready");
  };

  return (
    <div
      className="relative w-full min-h-screen overflow-hidden"
      style={{ backgroundColor: "#0a060e", fontFamily: "'Space Grotesk', sans-serif" }}
    >
      {/* Background */}
      <div className="absolute inset-0">
        <img
          src={BG_IMAGE}
          alt=""
          className="w-full h-full object-cover pointer-events-none"
        />
      </div>

      {/* Logo */}
      <div
        className="absolute left-1/2 -translate-x-1/2"
        style={{ top: "-13px", width: "350px", height: "200px" }}
      >
        <img
          src={LOGO_IMAGE}
          alt="Knock Order"
          className="w-full h-full object-cover"
        />
      </div>

      {/* Cartridge Identity (top right) */}
      <div
        className="absolute flex items-center rounded-lg border border-[#222f42] p-[9px]"
        style={{
          top: "calc(50% - 353.5px)",
          left: "1200px",
          transform: "translateY(-50%)",
          backdropFilter: "blur(6px)",
          backgroundColor: "#b9e7f4",
        }}
      >
        <div className="flex flex-col items-end" style={{ width: "127px" }}>
          <span
            className="text-black font-bold text-right uppercase tracking-[1px]"
            style={{ fontSize: "10px", lineHeight: "10px" }}
          >
            Cartridge Identity
          </span>
          <span
            className="text-black font-medium text-right"
            style={{ fontSize: "14px", lineHeight: "20px" }}
          >
            {cartridgeUsername ?? (status === "connecting" ? "Connecting…" : "Guest")}
          </span>
        </div>
        <div className="relative ml-4 shrink-0">
          <div
            className="relative rounded border-2 border-[#222f42] overflow-hidden"
            style={{ width: "40px", height: "40px" }}
          >
            <img src={AVATAR_IMAGE} alt="Avatar" className="w-full h-full object-cover" />
          </div>
          <div
            className="absolute -bottom-1 -right-1 rounded-full border-2 border-[#0a060e]"
            style={{ width: "12px", height: "12px", backgroundColor: "#8c25f4" }}
          />
        </div>
      </div>

      {/* Main Content */}
      <div
        className="absolute left-1/2 -translate-x-1/2 -translate-y-1/2 flex items-center justify-center px-3"
        style={{ top: "calc(50% + 29.75px)", width: "960px" }}
      >
        {/* Container with corner accents */}
        <div className="relative flex flex-col gap-6 items-start" style={{ width: "504px" }}>
          {/* Corner accents */}
          <div className="absolute border-t-[1.5px] border-l-[1.5px] border-[#b9e7f4]" style={{ top: "-12px", left: "-12px", width: "36px", height: "36px" }} />
          <div className="absolute border-t-[1.5px] border-r-[1.5px] border-[#b9e7f4]" style={{ top: "-12px", right: "-12px", width: "36px", height: "36px" }} />
          <div className="absolute border-b-[1.5px] border-l-[1.5px] border-[#b9e7f4]" style={{ bottom: "-12px", left: "-12px", width: "36px", height: "36px" }} />
          <div className="absolute border-b-[1.5px] border-r-[1.5px] border-[#b9e7f4]" style={{ bottom: "-12px", right: "-12px", width: "36px", height: "36px" }} />

          {/* Central Config Panel */}
          <div
            className="relative w-full rounded-[6px] border-[2.4px] border-[#b9e7f4] overflow-hidden"
            style={{
              backdropFilter: "blur(4.5px)",
              backgroundColor: "rgba(15,23,42,0.4)",
              padding: "38.4px",
            }}
          >
            <div className="absolute top-[-1.65px] left-[-1.65px] right-[-1.65px] bg-[#56a4cb]" style={{ height: "1.5px" }} />

            <div className="flex flex-col gap-[30px] items-start w-full">
              <div className="w-full flex flex-col gap-[6px] items-center">
                <h2
                  className="text-[#f1f5f9] font-bold text-center uppercase tracking-[4.5px]"
                  style={{ fontSize: "22.5px", lineHeight: "27px" }}
                >
                  Initiate Match Sequence
                </h2>
                <div className="rounded-full bg-[#222f42]" style={{ width: "72px", height: "3px" }} />
              </div>

              <div className="flex flex-col gap-6 items-start w-full">
                {/* Match Type Selector */}
                <div className="flex flex-col gap-3 items-start w-full">
                  <label className="text-white font-bold uppercase tracking-[2.7px]" style={{ fontSize: "9px", lineHeight: "12px" }}>
                    Select Match Type
                  </label>
                  <div className="flex gap-3 items-start w-full">
                    {([
                      { key: "casual" as MatchType, icon: "sports_esports", label: "Casual", sub: "No Stakes" },
                      { key: "ranked" as MatchType, icon: "military_tech", label: "Ranked", sub: "Earn Points", popular: true },
                      { key: "tourney" as MatchType, icon: "emoji_events", label: "Tourney", sub: "Bracketed" },
                    ]).map((mt) => (
                      <div key={mt.key} className="relative flex-1">
                        <button
                          onClick={() => setMatchType(mt.key)}
                          className={`w-full flex flex-col items-center py-[18.75px] ko-btn transition-all ${matchType === mt.key ? "ko-btn-secondary active" : "ko-btn-secondary"}`}
                        >
                          <span className={`material-icons mb-2 ko-btn-icon ${matchType === mt.key ? "text-[#222f42]" : "text-[#56a4cb]"}`} style={{ fontSize: "22.5px" }}>
                            {mt.icon}
                          </span>
                          <span className={`font-bold uppercase tracking-[1.05px] ko-btn-text ${matchType === mt.key ? "text-black" : "text-[#f1f5f9]"}`} style={{ fontSize: "10.5px", lineHeight: "15px" }}>
                            {mt.label}
                          </span>
                          <span className={`uppercase mt-[3px] ${matchType === mt.key ? "text-[rgba(0,0,0,0.8)]" : "text-[#94a3b8]"}`} style={{ fontSize: "7.5px", lineHeight: "11.25px" }}>
                            {mt.sub}
                          </span>
                        </button>
                        {mt.popular && (
                          <div className="absolute left-1/2 -translate-x-1/2 bg-[#222f42] rounded-[3px] px-[6px] py-[1.5px]" style={{ top: "-9px" }}>
                            <span className="text-[#f1f5f9] font-bold uppercase text-center" style={{ fontSize: "7.5px", lineHeight: "11.25px" }}>Popular</span>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </div>

                {/* On-chain: Opponent address (required when Dojo is enabled) */}
                {dojoReady && (
                  <div className="flex flex-col gap-3 items-start w-full">
                    <label className="text-white font-bold uppercase tracking-[2.7px]" style={{ fontSize: "9px", lineHeight: "12px" }}>
                      Opponent wallet address (on-chain)
                    </label>
                    <input
                      type="text"
                      value={opponentAddress}
                      onChange={(e) => setOpponentAddress(e.target.value)}
                      placeholder="0x..."
                      className="w-full rounded-[6px] border border-[#56a4cb] p-[9.75px] bg-[rgba(30,41,59,0.5)] text-[#f1f5f9] placeholder:text-[#64748b]"
                      style={{ fontSize: "10.5px" }}
                    />
                    {dojoError && <p className="text-red-400 text-xs">{dojoError}</p>}
                  </div>
                )}

                {/* Deck Selection + Server Region */}
                <div className="flex gap-[18px] items-start w-full" style={{ height: "67.5px" }}>
                  <div className="flex-1 flex flex-col gap-[6px] items-start self-stretch">
                    <label className="text-white font-bold uppercase tracking-[0.9px]" style={{ fontSize: "9px", lineHeight: "12px" }}>Deck Selection</label>
                    <div className="flex items-center justify-between w-full rounded-[6px] border-[0.75px] border-[#56a4cb] p-[9.75px] cursor-pointer" style={{ backgroundColor: "rgba(30,41,59,0.5)" }}>
                      <div className="flex items-center">
                        <div className="rounded-[3px] border-[0.75px] border-[#b9e7f4] shrink-0 bg-[#334155]" style={{ width: "24px", height: "30px" }} />
                        <div className="flex flex-col items-start pl-[9px]">
                          <span className="text-[#f1f5f9] font-medium" style={{ fontSize: "10.5px", lineHeight: "15px" }}>Void Walkers v.2</span>
                          <span className="text-white" style={{ fontSize: "7.5px", lineHeight: "11.25px" }}>10 Cards • SR Rare</span>
                        </div>
                      </div>
                      <span className="material-icons text-white" style={{ fontSize: "10.5px" }}>expand_more</span>
                    </div>
                  </div>
                  <div className="flex-1 flex flex-col gap-[6px] items-start self-stretch">
                    <label className="text-white font-bold uppercase tracking-[0.9px]" style={{ fontSize: "9px", lineHeight: "12px" }}>Server Region</label>
                    <div className="flex items-center justify-between w-full rounded-[6px] border-[0.75px] border-[#56a4cb] p-[9.75px] cursor-pointer" style={{ backgroundColor: "rgba(30,41,59,0.5)" }}>
                      <div className="flex items-center">
                        <span className="material-icons text-[#56a4cb]" style={{ fontSize: "13.5px" }}>language</span>
                        <span className="text-[#f1f5f9] font-medium uppercase tracking-[-0.525px] pl-[9px]" style={{ fontSize: "10.5px", lineHeight: "15px" }}>Automatic (24ms)</span>
                      </div>
                      <span className="material-icons text-white" style={{ fontSize: "10.5px" }}>expand_more</span>
                    </div>
                  </div>
                </div>

                {/* Create Match Button */}
                <div className="flex flex-col gap-3 items-start w-full pt-[18px]">
                  <button
                    onClick={() => void handleCreateMatch()}
                    disabled={dojoReady && (!opponentAddress.trim() || dojoCreating)}
                    className="flex w-full py-[15px] ko-btn ko-btn-primary animate-pulse disabled:opacity-50 disabled:cursor-not-allowed"
                    style={{ animationDuration: "3s" }}
                  >
                    <span className="material-icons text-white ko-btn-icon" style={{ fontSize: "18px" }}>radar</span>
                    <span className="text-white font-bold uppercase tracking-[6px] pl-3 ko-btn-text" style={{ fontSize: "15px", lineHeight: "21px" }}>
                      {dojoCreating ? "Creating on-chain…" : "Create Match"}
                    </span>
                    <span className="material-icons text-white pl-3 ko-btn-icon" style={{ fontSize: "18px" }}>radar</span>
                  </button>
                  <p className="text-white text-center uppercase tracking-[1.5px] w-full" style={{ fontSize: "7.5px", lineHeight: "11.25px" }}>
                    Establishing secure P2P connection via Cartridge Layer...
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Footer Stats */}
          <div className="flex gap-3 items-start w-full" style={{ height: "53.25px" }}>
            {[
              { label: "Active Players", value: "12,408" },
              { label: "Live Lobbies", value: "1,102" },
              { label: "Avg Queue", value: "14s" },
            ].map((stat) => (
              <div
                key={stat.label}
                className="flex-1 flex flex-col items-center justify-center rounded-[3px] border-[1.5px] border-[#b9e7f4] p-[10.5px] self-stretch"
                style={{ backgroundColor: "rgba(15,23,42,0.6)" }}
              >
                <span className="text-[#f5f5f5] font-bold uppercase tracking-[0.75px] text-center" style={{ fontSize: "7.5px", lineHeight: "11.25px" }}>
                  {stat.label}
                </span>
                <span className="text-white font-bold text-center" style={{ fontSize: "13.5px", lineHeight: "21px" }}>
                  {stat.value}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
