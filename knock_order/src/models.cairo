use starknet::ContractAddress;

// ============================================================================
// Core Components (Models)
// ============================================================================

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Player {
    #[key]
    pub address: ContractAddress,
    pub life: u32,              // Starts at 100, only decreases
    pub deck_id: u32,           // Reference to player's deck
    pub status_flags: u32,      // Bit flags: staggered, etc.
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Match {
    #[key]
    pub match_id: u64,
    pub player_a: ContractAddress,
    pub player_b: ContractAddress,
    pub round: u8,              // Current round number
    pub match_state: MatchState,
    pub best_of: u8,            // 3 for standard, 5 for tournament
    pub player_a_wins: u8,
    pub player_b_wins: u8,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct MoveBox {
    #[key]
    pub match_id: u64,
    #[key]
    pub player: ContractAddress,
    pub round: u8,
    pub slot_0: u32,
    pub slot_1: u32,
    pub slot_2: u32,
    pub slot_3: u32,
    pub slot_4: u32,
    pub locked: bool,           // Whether moves are locked
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct MoveCard {
    #[key]
    pub card_id: u32,
    pub name: felt252,          // Card name
    pub move_type: MoveType,
    pub rarity: Rarity,
    pub base_knock: u32,        // Base knock value
    pub priority: u32,          // Higher priority resolves first
    pub drain_multiplier: u32,  // Multiplier for life drain (scaled by 100)
}

// ============================================================================
// Enums
// ============================================================================

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug, DojoStore, Default)]
pub enum MoveType {
    #[default]
    Strike,
    Defense,
    Counter,
    Control,
    Evasion,
    Finisher,
}

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug, DojoStore, Default)]
pub enum Rarity {
    #[default]
    Common,
    Rare,
    Epic,
    Legendary,
}

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug, DojoStore, Default)]
pub enum MatchState {
    #[default]
    Waiting,        // Waiting for players to join
    Setup,          // Players selecting moves
    Locked,         // Both players locked, ready to resolve
    Resolving,      // Currently resolving slots
    RoundEnd,       // Round ended, checking win conditions
    MatchEnd,       // Match completed
}

#[derive(Copy, Drop, Serde, Debug)]
pub struct SlotResolution {
    pub slot_index: u8,
    pub player_a_card: u32,
    pub player_b_card: u32,
    pub player_a_knock: u32,
    pub player_b_knock: u32,
    pub interaction_result: InteractionResult,
}

#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug, DojoStore, Default)]
pub enum InteractionResult {
    #[default]
    Normal,         // Standard resolution
    Blocked,        // Defense blocked strike
    Dodged,         // Evasion avoided strike
    Countered,      // Counter triggered
    ControlEffect,  // Control card altered next slots
    FinisherHit,    // Finisher connected
    FinisherBlocked,// Finisher was blocked
}

// ============================================================================
// Constants
// ============================================================================

pub const STARTING_LIFE: u32 = 100;
pub const FINISHER_THRESHOLD: u32 = 30;  // Life threshold for finisher
pub const MAX_SLOTS: u8 = 5;
pub const STANDARD_BEST_OF: u8 = 3;
pub const TOURNAMENT_BEST_OF: u8 = 5;

// ============================================================================
// Helper Functions
// ============================================================================

#[generate_trait]
pub impl PlayerImpl of PlayerTrait {
    fn is_staggered(self: Player) -> bool {
        (self.status_flags & 1) != 0
    }

    fn set_staggered(ref self: Player, staggered: bool) {
        if staggered {
            self.status_flags = self.status_flags + 1;
        } else {
            self.status_flags = self.status_flags - (self.status_flags & 1);
        }
    }

    fn is_alive(self: Player) -> bool {
        self.life > 0
    }
}

#[generate_trait]
pub impl MatchImpl of MatchTrait {
    fn is_complete(self: Match) -> bool {
        let wins_needed = self.best_of / 2 + 1;
        self.player_a_wins >= wins_needed || self.player_b_wins >= wins_needed
    }

    fn get_winner(self: Match) -> Option<ContractAddress> {
        let wins_needed = self.best_of / 2 + 1;
        if self.player_a_wins >= wins_needed {
            Option::Some(self.player_a)
        } else if self.player_b_wins >= wins_needed {
            Option::Some(self.player_b)
        } else {
            Option::None
        }
    }
}
