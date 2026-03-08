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

async function resolveCartridgeUsername(username: string): Promise<string | null> {
  if (!username.trim()) return null;
  try {
    const res = await fetch("https://api.cartridge.gg/query", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        query: `{ controller(username: ${JSON.stringify(username.trim())}, chainId: "SN_SEPOLIA") { address } }`,
      }),
    });
    const json = await res.json();
    return (json?.data?.controller?.address as string) ?? null;
  } catch {
    return null;
  }
}

export default function CreateMatch() {
  const [matchType, setMatchType] = useState<MatchType>("ranked");
  const [opponentUsername, setOpponentUsername] = useState("");
  const [resolvedAddress, setResolvedAddress] = useState<string | null>(null);
  const [resolving, setResolving] = useState(false);
  const [dojoCreating, setDojoCreating] = useState(false);
  const [dojoError, setDojoError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
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

  // Debounced Cartridge username → address resolution
  useEffect(() => {
    if (!opponentUsername.trim()) {
      setResolvedAddress(null);
      setResolving(false);
      return;
    }
    setResolving(true);
    setResolvedAddress(null);
    const timer = setTimeout(async () => {
      const addr = await resolveCartridgeUsername(opponentUsername);
      setResolvedAddress(addr);
      setResolving(false);
    }, 600);
    return () => clearTimeout(timer);
  }, [opponentUsername]);

  const handleCreateMatch = async () => {
    if (dojoReady && dojoActions && account && resolvedAddress) {
      setDojoError(null);
      setDojoCreating(true);
      try {
        const res = await dojoActions.MatchSetup.createMatch(
          account,
          resolvedAddress as `0x${string}`,
          matchType === "tourney" ? 5 : 3
        );
        const txHash = res.transaction_hash;
        const rpc = new RpcProvider({ nodeUrl: dojoConfig.rpcUrl });
        const receipt = await rpc.waitForTransaction(txHash, { retryInterval: 1000 });
        const receiptAny = receipt as unknown as { events?: { from_address?: string; keys?: string[]; data?: string[] }[] };
        const worldAddr = (dojoConfig.worldAddress ?? "").toLowerCase();
        // Dojo EventEmitted structure: keys[1] = event type selector, data[1] = match_id (#[key] field)
        // MatchCreated selector from manifest
        const MATCH_CREATED_SELECTOR = "0x199ebe35c5cd3caaf8f8d7137a307e01bee043b122843117644198c0847f45a";
        const matchCreatedEvent = receiptAny.events?.find((e) => {
          if (worldAddr && (e.from_address ?? "").toLowerCase() !== worldAddr) return false;
          if ((e.keys?.[1] ?? "").toLowerCase() !== MATCH_CREATED_SELECTOR) return false;
          return (e.data?.length ?? 0) >= 2;
        });
        // data[0] = keys span length (2: match_id + player_a), data[1] = match_id
        const matchIdFromEvent = matchCreatedEvent ? String(BigInt(matchCreatedEvent.data![1])) : null;
        const newMatchId = matchIdFromEvent ?? `tx-${txHash.slice(0, 10)}`;
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
          {account?.address && (
            <button
              onClick={() => {
                void navigator.clipboard.writeText(account.address).then(() => {
                  setCopied(true);
                  setTimeout(() => setCopied(false), 2000);
                });
              }}
              className="flex items-center gap-[3px] mt-[2px] cursor-pointer"
              title={account.address}
            >
              <span className="text-[#222f42] font-mono text-right" style={{ fontSize: "8px" }}>
                {account.address.slice(0, 6)}…{account.address.slice(-4)}
              </span>
              <span className="material-icons text-[#222f42]" style={{ fontSize: "9px" }}>
                {copied ? "check" : "content_copy"}
              </span>
            </button>
          )}
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

                {/* On-chain: Opponent Cartridge username (optional — leave blank to play solo) */}
                {dojoReady && (
                  <div className="flex flex-col gap-[6px] items-start w-full">
                    <label className="text-white font-bold uppercase tracking-[2.7px]" style={{ fontSize: "9px", lineHeight: "12px" }}>
                      Opponent Cartridge username <span className="text-[#56a4cb] normal-case tracking-normal" style={{ fontSize: "8px" }}>(optional — leave blank for solo vs AI)</span>
                    </label>
                    <div className="relative w-full">
                      <input
                        type="text"
                        value={opponentUsername}
                        onChange={(e) => setOpponentUsername(e.target.value)}
                        placeholder="cartridge username"
                        className="w-full rounded-[6px] border border-[#56a4cb] p-[9.75px] pr-8 bg-[rgba(30,41,59,0.5)] text-[#f1f5f9] placeholder:text-[#64748b]"
                        style={{ fontSize: "10.5px" }}
                      />
                      {opponentUsername.trim() && (
                        <span
                          className="absolute right-2 top-1/2 -translate-y-1/2 material-icons"
                          style={{
                            fontSize: "14px",
                            color: resolving ? "#94a3b8" : resolvedAddress ? "#4ade80" : "#f87171",
                          }}
                        >
                          {resolving ? "pending" : resolvedAddress ? "check_circle" : "cancel"}
                        </span>
                      )}
                    </div>
                    {resolvedAddress && (
                      <p className="text-[#56a4cb]" style={{ fontSize: "8px" }}>
                        {resolvedAddress.slice(0, 10)}…{resolvedAddress.slice(-6)}
                      </p>
                    )}
                    {opponentUsername.trim() && !resolving && !resolvedAddress && (
                      <p className="text-red-400" style={{ fontSize: "8px" }}>Username not found on Starknet Sepolia</p>
                    )}
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
                    disabled={dojoCreating}
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
