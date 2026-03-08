/**
 * Map frontend card id (gameData.Card.id) to contract MoveCard card_id (1–10).
 * Contract init_cards: 1 Basic Strike, 2 Heavy Strike, 3 Quick Strike, 4 Block, 5 Perfect Block,
 * 6 Counter, 7 Dodge, 8 Control, 9 Finisher, 10 Feint.
 * Unmapped cards default to 1 (Basic Strike) so lock_moves never fails.
 */
export const FRONTEND_TO_CONTRACT_CARD_ID: Record<string, number> = {
  // Strike (contract: 1 Basic, 2 Heavy, 3 Quick, 10 Feint, 9 Finisher)
  direct_impact: 1,
  power_punch: 2,
  storm_kick: 3,
  phantom_break: 10,
  finisher: 9,
  // Defense (4 Block, 5 Perfect Block, 6 Counter, 7 Dodge)
  guard_stance: 4,
  stability: 5,
  reversal_edge: 6,
  evasion: 7,
  anticipation: 4,
  // Control (8)
  mind_game: 8,
  pressure_advance: 8,
  disrupt: 8,
};

const DEFAULT_CONTRACT_CARD_ID = 1;

export function frontendCardIdToContractId(frontendCardId: string): number {
  return FRONTEND_TO_CONTRACT_CARD_ID[frontendCardId] ?? DEFAULT_CONTRACT_CARD_ID;
}
