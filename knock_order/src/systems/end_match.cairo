#[dojo::contract]
pub mod EndMatch {
    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;
    use dojo_starter::base::events::MatchEnded;
    use dojo_starter::interfaces::IEndMatch::IEndMatch;
    use dojo_starter::interfaces::IEgsAdapter::{IEgsAdapterDispatcher, IEgsAdapterDispatcherTrait};
    use dojo_starter::models::{EgsConfig, Match, MatchState};
    use starknet::{ContractAddress, get_block_timestamp};

    #[abi(embed_v0)]
    impl EndMatchImpl of IEndMatch<ContractState> {
        fn end_match(ref self: ContractState, match_id: u64) {
            let mut world = self.world_default();

            // Read match
            let mut match_data: Match = world.read_model(match_id);
            assert(match_data.match_state == MatchState::MatchEnd, 'match not ended');
            
            // Check if match is complete
            let wins_needed = match_data.best_of / 2 + 1;
            assert(
                match_data.player_a_wins >= wins_needed || match_data.player_b_wins >= wins_needed,
                'match not complete',
            );

            // Get winner
            let winner = if match_data.player_a_wins >= wins_needed {
                match_data.player_a
            } else {
                match_data.player_b
            };

            // Finalize match state
            match_data.match_state = MatchState::MatchEnd;

            // Write updated match
            world.write_model(@match_data);

            // Emit event
            world.emit_event(@MatchEnded {
                match_id,
                winner,
                player_a_wins: match_data.player_a_wins,
                player_b_wins: match_data.player_b_wins,
                timestamp: get_block_timestamp(),
            });

            // Push result to EGS adapter if one is configured.
            // score = winner_wins * 100 + loser_wins
            //   e.g.  2-0 → 200 | 2-1 → 201 | 3-0 → 300 | 3-2 → 302
            let egs_cfg: EgsConfig = world.read_model(0_u8);
            let zero_addr: ContractAddress = 0.try_into().unwrap();
            if egs_cfg.adapter_address != zero_addr {
                let winner_wins = wins_needed;
                let loser_wins = match_data.player_a_wins
                    + match_data.player_b_wins
                    - wins_needed;
                let egs_score: u64 = winner_wins.into() * 100_u64
                    + loser_wins.into();
                let adapter = IEgsAdapterDispatcher {
                    contract_address: egs_cfg.adapter_address,
                };
                adapter.record_result(match_id.into(), egs_score);
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
        }
    }
}
