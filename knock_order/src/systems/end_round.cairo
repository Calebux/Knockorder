#[dojo::contract]
pub mod EndRound {
    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;
    use dojo_starter::base::events::RoundEnded;
    use dojo_starter::interfaces::IEndRound::IEndRound;
    use dojo_starter::models::{Match, MatchState, Player, STARTING_LIFE};
    use starknet::{ContractAddress, get_block_timestamp};

    #[abi(embed_v0)]
    impl EndRoundImpl of IEndRound<ContractState> {
        fn end_round(ref self: ContractState, match_id: u64) {
            let mut world = self.world_default();

            // Read match
            let mut match_data: Match = world.read_model(match_id);
            assert(match_data.match_state == MatchState::RoundEnd, 'round not ended');

            // Read players
            let player_a: Player = world.read_model(match_data.player_a);
            let player_b: Player = world.read_model(match_data.player_b);

            // Determine round winner
            let mut winner: Option<ContractAddress> = Option::None;

            if player_a.life == 0 {
                winner = Option::Some(match_data.player_b);
                match_data.player_b_wins += 1;
            } else if player_b.life == 0 {
                winner = Option::Some(match_data.player_a);
                match_data.player_a_wins += 1;
            } else if player_a.life < player_b.life {
                winner = Option::Some(match_data.player_b);
                match_data.player_b_wins += 1;
            } else if player_b.life < player_a.life {
                winner = Option::Some(match_data.player_a);
                match_data.player_a_wins += 1;
            };
            // If life is equal, round is a draw (no winner)

            // Check if match is complete
            let wins_needed = match_data.best_of / 2 + 1;
            if match_data.player_a_wins >= wins_needed || match_data.player_b_wins >= wins_needed {
                match_data.match_state = MatchState::MatchEnd;
            } else {
                // Reset for next round
                match_data.round += 1;
                match_data.match_state = MatchState::Setup;

                // Reset player life for next round
                let mut player_a_reset: Player = world.read_model(match_data.player_a);
                let mut player_b_reset: Player = world.read_model(match_data.player_b);
                player_a_reset.life = STARTING_LIFE;
                player_b_reset.life = STARTING_LIFE;
                // Reset status flags (clear staggered)
                player_a_reset.status_flags = 0;
                player_b_reset.status_flags = 0;
                world.write_model(@player_a_reset);
                world.write_model(@player_b_reset);
            }

            // Write updated match
            world.write_model(@match_data);

            // Emit event
            world.emit_event(@RoundEnded {
                match_id,
                round: match_data.round - 1,
                winner,
                player_a_life: player_a.life,
                player_b_life: player_b.life,
                timestamp: get_block_timestamp(),
            });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
        }
    }
}
