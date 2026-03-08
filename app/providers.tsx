"use client";

import { useMemo } from "react";
import { StarknetConfig, cartridgeProvider } from "@starknet-react/core";
import { sepolia } from "@starknet-react/chains";
import { getConnector } from "./lib/cartridge";

export function Providers({ children }: { children: React.ReactNode }) {
  const connectors = useMemo(() => [getConnector()], []);

  return (
    <StarknetConfig
      chains={[sepolia]}
      provider={cartridgeProvider()}
      connectors={connectors}
      autoConnect
    >
      {children}
    </StarknetConfig>
  );
}
