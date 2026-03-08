use starknet::ContractAddress;
use dojo_starter::models::InteractionResult;

// Helper function to convert InteractionResult enum to u8
pub fn interaction_result_to_u8(result: InteractionResult) -> u8 {
    match result {
        InteractionResult::Normal => 0,
        InteractionResult::Blocked => 1,
        InteractionResult::Dodged => 2,
        InteractionResult::Countered => 3,
        InteractionResult::ControlEffect => 4,
        InteractionResult::FinisherHit => 5,
        InteractionResult::FinisherBlocked => 6,
    }
}

// ============================================================================
// Match Events
// ============================================================================

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct MatchCreated {
    #[key]
    pub match_id: u64,
    #[key]
    pub player_a: ContractAddress,
    pub player_b: ContractAddress,
    pub best_of: u8,
    pub timestamp: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct PlayerJoined {
    #[key]
    pub match_id: u64,
    #[key]
    pub player: ContractAddress,
    pub timestamp: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct MovesLocked {
    #[key]
    pub match_id: u64,
    #[key]
    pub player: ContractAddress,
    pub round: u8,
    pub timestamp: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct SlotResolved {
    #[key]
    pub match_id: u64,
    pub slot_index: u8,
    pub player_a_card: u32,
    pub player_b_card: u32,
    pub player_a_knock: u32,
    pub player_b_knock: u32,
    pub interaction_result: u8, // InteractionResult enum as u8
    pub timestamp: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct RoundResolved {
    #[key]
    pub match_id: u64,
    pub round: u8,
    pub timestamp: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct LifeDrained {
    #[key]
    pub match_id: u64,
    #[key]
    pub player: ContractAddress,
    pub knock: u32,
    pub life_drained: u32,
    pub remaining_life: u32,
    pub timestamp: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct RoundEnded {
    #[key]
    pub match_id: u64,
    pub round: u8,
    pub winner: Option<ContractAddress>,
    pub player_a_life: u32,
    pub player_b_life: u32,
    pub timestamp: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct MatchEnded {
    #[key]
    pub match_id: u64,
    pub winner: ContractAddress,
    pub player_a_wins: u8,
    pub player_b_wins: u8,
    pub timestamp: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct CardInitialized {
    #[key]
    pub card_id: u32,
    pub name: felt252,
    pub timestamp: u64,
}
