import { DojoProvider } from "@dojoengine/core";
import { Account, AccountInterface, BigNumberish } from "starknet";

export function setupWorld(provider: DojoProvider) {
  const build_DrainLife_drainLife_calldata = (
    matchId: BigNumberish,
    playerAKnock: BigNumberish,
    playerBKnock: BigNumberish
  ) => ({
    contractName: "DrainLife",
    entrypoint: "drain_life",
    calldata: [matchId, playerAKnock, playerBKnock],
  });

  const DrainLife_drainLife = async (
    snAccount: Account | AccountInterface,
    matchId: BigNumberish,
    playerAKnock: BigNumberish,
    playerBKnock: BigNumberish
  ) => {
    return provider.execute(
      snAccount,
      build_DrainLife_drainLife_calldata(matchId, playerAKnock, playerBKnock),
      "dojo_starter"
    );
  };

  const build_EndMatch_endMatch_calldata = (matchId: BigNumberish) => ({
    contractName: "EndMatch",
    entrypoint: "end_match",
    calldata: [matchId],
  });

  const EndMatch_endMatch = async (snAccount: Account | AccountInterface, matchId: BigNumberish) => {
    return provider.execute(snAccount, build_EndMatch_endMatch_calldata(matchId), "dojo_starter");
  };

  const build_EndRound_endRound_calldata = (matchId: BigNumberish) => ({
    contractName: "EndRound",
    entrypoint: "end_round",
    calldata: [matchId],
  });

  const EndRound_endRound = async (snAccount: Account | AccountInterface, matchId: BigNumberish) => {
    return provider.execute(snAccount, build_EndRound_endRound_calldata(matchId), "dojo_starter");
  };

  const build_InitCards_initDefaultCards_calldata = () => ({
    contractName: "InitCards",
    entrypoint: "init_default_cards",
    calldata: [],
  });

  const InitCards_initDefaultCards = async (snAccount: Account | AccountInterface) => {
    return provider.execute(
      snAccount,
      build_InitCards_initDefaultCards_calldata(),
      "dojo_starter"
    );
  };

  const build_LockMoves_lockMoves_calldata = (
    matchId: BigNumberish,
    slots: Array<BigNumberish>
  ) => ({
    contractName: "LockMoves",
    entrypoint: "lock_moves",
    calldata: [matchId, slots],
  });

  const LockMoves_lockMoves = async (
    snAccount: Account | AccountInterface,
    matchId: BigNumberish,
    slots: Array<BigNumberish>
  ) => {
    return provider.execute(
      snAccount,
      build_LockMoves_lockMoves_calldata(matchId, slots),
      "dojo_starter"
    );
  };

  const build_MatchSetup_createMatch_calldata = (
    opponent: string,
    bestOf: BigNumberish
  ) => ({
    contractName: "MatchSetup",
    entrypoint: "create_match",
    calldata: [opponent, bestOf],
  });

  const MatchSetup_createMatch = async (
    snAccount: Account | AccountInterface,
    opponent: string,
    bestOf: BigNumberish
  ) => {
    return provider.execute(
      snAccount,
      build_MatchSetup_createMatch_calldata(opponent, bestOf),
      "dojo_starter"
    );
  };

  const build_MatchSetup_joinMatch_calldata = (matchId: BigNumberish) => ({
    contractName: "MatchSetup",
    entrypoint: "join_match",
    calldata: [matchId],
  });

  const MatchSetup_joinMatch = async (
    snAccount: Account | AccountInterface,
    matchId: BigNumberish
  ) => {
    return provider.execute(
      snAccount,
      build_MatchSetup_joinMatch_calldata(matchId),
      "dojo_starter"
    );
  };

  const build_ResolveRound_resolveRound_calldata = (matchId: BigNumberish) => ({
    contractName: "ResolveRound",
    entrypoint: "resolve_round",
    calldata: [matchId],
  });

  const ResolveRound_resolveRound = async (
    snAccount: Account | AccountInterface,
    matchId: BigNumberish
  ) => {
    return provider.execute(
      snAccount,
      build_ResolveRound_resolveRound_calldata(matchId),
      "dojo_starter"
    );
  };

  const build_ResolveSlot_resolveSlot_calldata = (
    matchId: BigNumberish,
    slotIndex: BigNumberish
  ) => ({
    contractName: "ResolveSlot",
    entrypoint: "resolve_slot",
    calldata: [matchId, slotIndex],
  });

  const ResolveSlot_resolveSlot = async (
    snAccount: Account | AccountInterface,
    matchId: BigNumberish,
    slotIndex: BigNumberish
  ) => {
    return provider.execute(
      snAccount,
      build_ResolveSlot_resolveSlot_calldata(matchId, slotIndex),
      "dojo_starter"
    );
  };

  return {
    DrainLife: { drainLife: DrainLife_drainLife, buildDrainLifeCalldata: build_DrainLife_drainLife_calldata },
    EndMatch: { endMatch: EndMatch_endMatch, buildEndMatchCalldata: build_EndMatch_endMatch_calldata },
    EndRound: { endRound: EndRound_endRound, buildEndRoundCalldata: build_EndRound_endRound_calldata },
    InitCards: {
      initDefaultCards: InitCards_initDefaultCards,
      buildInitDefaultCardsCalldata: build_InitCards_initDefaultCards_calldata,
    },
    LockMoves: {
      lockMoves: LockMoves_lockMoves,
      buildLockMovesCalldata: build_LockMoves_lockMoves_calldata,
    },
    MatchSetup: {
      createMatch: MatchSetup_createMatch,
      buildCreateMatchCalldata: build_MatchSetup_createMatch_calldata,
      joinMatch: MatchSetup_joinMatch,
      buildJoinMatchCalldata: build_MatchSetup_joinMatch_calldata,
    },
    ResolveRound: {
      resolveRound: ResolveRound_resolveRound,
      buildResolveRoundCalldata: build_ResolveRound_resolveRound_calldata,
    },
    ResolveSlot: {
      resolveSlot: ResolveSlot_resolveSlot,
      buildResolveSlotCalldata: build_ResolveSlot_resolveSlot_calldata,
    },
  };
}

export type DojoWorldActions = ReturnType<typeof setupWorld>;
