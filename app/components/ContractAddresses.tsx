"use client";

import React, { useState } from "react";
import { getDojoConfig } from "../lib/dojo/config";

type ManifestWorld = { address?: string; name?: string; seed?: string };
type ManifestContract = { tag?: string; address?: string };
type ManifestShape = { world?: ManifestWorld; contracts?: ManifestContract[] };

function shortenAddress(addr: string, chars = 6): string {
  if (!addr || addr.length <= chars * 2 + 2) return addr;
  return `${addr.slice(0, chars + 2)}…${addr.slice(-chars)}`;
}

function copyToClipboard(text: string): void {
  navigator.clipboard?.writeText(text);
}

export function ContractAddresses() {
  const { manifest } = getDojoConfig();
  const [copied, setCopied] = useState<string | null>(null);
  const [expanded, setExpanded] = useState(false);

  const m = manifest as ManifestShape | null;
  const world = m?.world;
  const contracts = m?.contracts ?? [];

  if (!world?.address && contracts.length === 0) return null;

  const handleCopy = (label: string, value: string) => {
    copyToClipboard(value);
    setCopied(label);
    setTimeout(() => setCopied(null), 1500);
  };

  const row = (label: string, address: string) => (
    <div
      key={label}
      className="ko-addr-row"
      onClick={() => handleCopy(label, address)}
      title="Click to copy"
    >
      <span className="ko-addr-label">{label}</span>
      <code className="ko-addr-value">{shortenAddress(address)}</code>
      {copied === label && <span className="ko-addr-copied">Copied</span>}
    </div>
  );

  return (
    <>
      <style>{`
        .ko-addresses-panel {
          position: absolute;
          left: 40px;
          bottom: 80px;
          width: 320px;
          z-index: 15;
          font-family: 'Ruda', sans-serif;
          background: rgba(15, 23, 42, 0.92);
          border: 1px solid rgba(86, 164, 203, 0.35);
          border-radius: 8px;
          backdrop-filter: blur(8px);
          overflow: hidden;
        }
        .ko-addresses-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 10px 14px;
          cursor: pointer;
          color: #b9e7f4;
          font-size: 12px;
          font-weight: 700;
          letter-spacing: 1px;
          text-transform: uppercase;
        }
        .ko-addresses-header:hover { background: rgba(86, 164, 203, 0.15); }
        .ko-addresses-body {
          padding: 8px 14px 14px;
          max-height: ${expanded ? "400px" : "0"};
          overflow: auto;
          transition: max-height 0.25s ease;
        }
        .ko-addr-row {
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 6px 0;
          cursor: pointer;
          border-bottom: 1px solid rgba(86, 164, 203, 0.12);
        }
        .ko-addr-row:last-child { border-bottom: none; }
        .ko-addr-row:hover { color: #56a4cb; }
        .ko-addr-label {
          flex: 0 0 140px;
          font-size: 11px;
          color: rgba(185, 231, 244, 0.85);
        }
        .ko-addr-value {
          flex: 1;
          font-size: 11px;
          color: #fff;
          word-break: break-all;
        }
        .ko-addr-copied {
          font-size: 10px;
          color: #22c55e;
          margin-left: auto;
        }
      `}</style>
      <div className="ko-addresses-panel">
        <div
          className="ko-addresses-header"
          onClick={() => setExpanded((e) => !e)}
        >
          <span>Contract addresses</span>
          <span>{expanded ? "▼" : "▶"}</span>
        </div>
        <div className="ko-addresses-body">
          {world?.address && row("World", world.address)}
          {contracts.map((c) =>
            c.tag && c.address ? row(c.tag, c.address) : null
          )}
        </div>
      </div>
    </>
  );
}
