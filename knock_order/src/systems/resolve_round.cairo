#[dojo::contract]
pub mod ResolveRound {
    use dojo::model::ModelStorage;
    use dojo::world::WorldStorageTrait;
    use dojo::event::EventStorage;
    use starknet::get_block_timestamp;
    use dojo_starter::base::events::RoundResolved;
    use dojo_starter::interfaces::IResolveRound::IResolveRound;
    use dojo_starter::interfaces::IResolveSlot::{IResolveSlotDispatcher, IResolveSlotDispatcherTrait};
    use dojo_starter::models::{Match, MatchState, MAX_SLOTS};

    #[abi(embed_v0)]
    impl ResolveRoundImpl of IResolveRound<ContractState> {
        fn resolve_round(ref self: ContractState, match_id: u64) {
            let mut world = self.world_default();

            // Read match
            let mut match_data: Match = world.read_model(match_id);
            assert(match_data.match_state == MatchState::Locked, 'match not locked');

            // Update state to resolving
            match_data.match_state = MatchState::Resolving;
            world.write_model(@match_data);

            // Get system dispatcher
            let resolve_slot_option = world.dns(@"ResolveSlot");
            let (resolve_slot_address, _) = resolve_slot_option.unwrap();
            let resolve_slot_system = IResolveSlotDispatcher { contract_address: resolve_slot_address };

            // Resolve each slot sequentially
            let mut slot_index = 0_u8;
            loop {
                if slot_index >= MAX_SLOTS {
                    break;
                }

                // Resolve slot (this also drains life internally)
                resolve_slot_system.resolve_slot(match_id, slot_index);

                // Check if finisher ended the round early
                let current_match: Match = world.read_model(match_id);
                if current_match.match_state == MatchState::RoundEnd {
                    break;
                }

                slot_index += 1;
            }

            // Mark round as ended
            match_data.match_state = MatchState::RoundEnd;
            world.write_model(@match_data);

            world.emit_event(@RoundResolved {
                match_id,
                round: match_data.round,
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
