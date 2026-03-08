// Minimal schema type for bindings (avoids @dojoengine/sdk dependency)
import { CairoCustomEnum, CairoOption, CairoOptionVariant, BigNumberish } from "starknet";

export interface Match {
  match_id: BigNumberish;
  player_a: string;
  player_b: string;
  round: BigNumberish;
  match_state: MatchStateEnum;
  best_of: BigNumberish;
  player_a_wins: BigNumberish;
  player_b_wins: BigNumberish;
}

export interface MoveBox {
  match_id: BigNumberish;
  player: string;
  round: BigNumberish;
  slot_0: BigNumberish;
  slot_1: BigNumberish;
  slot_2: BigNumberish;
  slot_3: BigNumberish;
  slot_4: BigNumberish;
  locked: boolean;
}

export interface MoveCard {
  card_id: BigNumberish;
  name: BigNumberish;
  move_type: MoveTypeEnum;
  rarity: RarityEnum;
  base_knock: BigNumberish;
  priority: BigNumberish;
  drain_multiplier: BigNumberish;
}

export interface Player {
  address: string;
  life: BigNumberish;
  deck_id: BigNumberish;
  status_flags: BigNumberish;
}

export const matchState = ["Waiting", "Setup", "Locked", "Resolving", "RoundEnd", "MatchEnd"] as const;
export type MatchStateEnum = CairoCustomEnum;

export const moveType = ["Strike", "Defense", "Counter", "Control", "Evasion", "Finisher"] as const;
export type MoveTypeEnum = CairoCustomEnum;

export const rarity = ["Common", "Rare", "Epic", "Legendary"] as const;
export type RarityEnum = CairoCustomEnum;

export enum ModelsMapping {
  Match = "dojo_starter-Match",
  MoveBox = "dojo_starter-MoveBox",
  MoveCard = "dojo_starter-MoveCard",
  Player = "dojo_starter-Player",
}
