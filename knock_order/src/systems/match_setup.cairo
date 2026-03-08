#[dojo::contract]
pub mod MatchSetup {
    use dojo::event::EventStorage;
    use dojo::model::ModelStorage;
    use dojo_starter::base::events::{MatchCreated, PlayerJoined};
    use dojo_starter::interfaces::IMatchSetup::IMatchSetup;
    use dojo_starter::models::{Match, MatchState, Player, STARTING_LIFE};
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};

    #[abi(embed_v0)]
    impl MatchSetupImpl of IMatchSetup<ContractState> {
        fn create_match(
            ref self: ContractState, opponent: ContractAddress, best_of: u8,
        ) -> u64 {
            let mut world = self.world_default();
            let player_a = get_caller_address();

            assert(player_a != opponent, 'cannot play against yourself');
            assert(best_of == 3 || best_of == 5, 'best_of must be 3 or 5');

            // Generate match_id (simple incrementing for MVP)
            // In production, use a proper ID generator
            let match_id = get_next_match_id(@world);

            // Create match
            let match_data = Match {
                match_id,
                player_a,
                player_b: opponent,
                round: 1,
                match_state: MatchState::Waiting,
                best_of,
                player_a_wins: 0,
                player_b_wins: 0,
            };

            // Initialize player A
            let player_a_data = Player {
                address: player_a,
                life: STARTING_LIFE,
                deck_id: 0,  // Default deck
                status_flags: 0,
            };

            world.write_model(@match_data);
            world.write_model(@player_a_data);

            world.emit_event(@MatchCreated {
                match_id,
                player_a,
                player_b: opponent,
                best_of,
                timestamp: get_block_timestamp(),
            });

            match_id
        }

        fn join_match(ref self: ContractState, match_id: u64) {
            let mut world = self.world_default();
            let player = get_caller_address();

            // Read match
            let mut match_data: Match = world.read_model(match_id);
            assert(match_data.match_state == MatchState::Waiting, 'match not waiting');
            assert(match_data.player_b == player, 'not the invited player');

            // Initialize player B
            let player_b_data = Player {
                address: player,
                life: STARTING_LIFE,
                deck_id: 0,  // Default deck
                status_flags: 0,
            };

            // Update match state
            match_data.match_state = MatchState::Setup;

            world.write_model(@match_data);
            world.write_model(@player_b_data);

            world.emit_event(@PlayerJoined {
                match_id,
                player,
                timestamp: get_block_timestamp(),
            });
        }
    }

    // Simple match ID generator (in production, use proper counter)
    fn get_next_match_id(world: @dojo::world::WorldStorage) -> u64 {
        // For MVP, use timestamp-based or counter-based ID
        // This is a placeholder - in production, use a proper counter model
        1_u64  // Simplified for MVP
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
        }
    }
}
