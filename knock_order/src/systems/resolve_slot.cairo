#[dojo::contract]
pub mod ResolveSlot {
    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;
    use dojo_starter::base::events::{interaction_result_to_u8, SlotResolved};
    use dojo_starter::interfaces::IResolveSlot::IResolveSlot;
    use dojo_starter::models::{
        InteractionResult, Match, MatchState, MoveBox, MoveCard, MoveType, Player,
        SlotResolution, FINISHER_THRESHOLD,
    };
    use starknet::{ContractAddress, get_block_timestamp};

    #[abi(embed_v0)]
    impl ResolveSlotImpl of IResolveSlot<ContractState> {
        fn resolve_slot(ref self: ContractState, match_id: u64, slot_index: u8) {
            let mut world = self.world_default();

            // Read match state
            let mut match_data: Match = world.read_model(match_id);
            assert(match_data.match_state == MatchState::Locked, 'match not locked');
            assert(slot_index < 5, 'invalid slot index');

            // Read MoveBoxes
            let player_a_box: MoveBox = world.read_model((match_id, match_data.player_a));
            let player_b_box: MoveBox = world.read_model((match_id, match_data.player_b));
            assert(player_a_box.locked && player_b_box.locked, 'moves not locked');
            assert(player_a_box.round == match_data.round, 'round mismatch');

            // Read MoveCards
            let card_a_id = get_slot_card(player_a_box, slot_index);
            let card_b_id = get_slot_card(player_b_box, slot_index);
            let card_a: MoveCard = world.read_model(card_a_id);
            let card_b: MoveCard = world.read_model(card_b_id);

            // Read Players
            let mut player_a: Player = world.read_model(match_data.player_a);
            let mut player_b: Player = world.read_model(match_data.player_b);

            // Resolve interaction
            let resolution = resolve_interaction(
                card_a, card_b, player_a, player_b, match_data.player_a, match_data.player_b,
            );

            // Apply knock
            let mut knock_a = 0_u32;
            let mut knock_b = 0_u32;

            match resolution.interaction_result {
                InteractionResult::Normal => {
                    knock_a = card_a.base_knock;
                    knock_b = card_b.base_knock;
                },
                InteractionResult::Blocked => {
                    // Defense reduces knock
                    if card_a.move_type == MoveType::Strike {
                        knock_a = 0;  // Blocked
                    } else {
                        knock_a = card_a.base_knock;
                    }
                    if card_b.move_type == MoveType::Strike {
                        knock_b = 0;  // Blocked
                    } else {
                        knock_b = card_b.base_knock;
                    }
                },
                InteractionResult::Dodged => {
                    // Evasion avoids knock
                    if card_a.move_type == MoveType::Strike {
                        knock_a = 0;
                    } else {
                        knock_a = card_a.base_knock;
                    }
                    if card_b.move_type == MoveType::Strike {
                        knock_b = 0;
                    } else {
                        knock_b = card_b.base_knock;
                    }
                },
                InteractionResult::Countered => {
                    // Counter adds bonus knock
                    if card_a.move_type == MoveType::Counter {
                        knock_a = card_a.base_knock * 2;  // Counter bonus
                    } else {
                        knock_a = card_a.base_knock;
                    }
                    if card_b.move_type == MoveType::Counter {
                        knock_b = card_b.base_knock * 2;
                    } else {
                        knock_b = card_b.base_knock;
                    }
                },
                InteractionResult::FinisherHit => {
                    // Finisher ignores defense and ends round
                    if card_a.move_type == MoveType::Finisher {
                        knock_a = card_a.base_knock;
                        match_data.match_state = MatchState::RoundEnd;
                    } else {
                        knock_a = card_a.base_knock;
                    }
                    if card_b.move_type == MoveType::Finisher {
                        knock_b = card_b.base_knock;
                        match_data.match_state = MatchState::RoundEnd;
                    } else {
                        knock_b = card_b.base_knock;
                    }
                },
                InteractionResult::FinisherBlocked => {
                    // Finisher was blocked (rare case)
                    knock_a = 0;
                    knock_b = 0;
                },
                InteractionResult::ControlEffect => {
                    // Control cards modify next slots (handled separately)
                    knock_a = card_a.base_knock;
                    knock_b = card_b.base_knock;
                },
            };

            // Drain life based on knock
            // Player B's knock drains Player A's life, and vice versa
            let drain_a = knock_b;
            let drain_b = knock_a;

            if drain_a > player_a.life {
                player_a.life = 0;
            } else {
                player_a.life -= drain_a;
            }

            if drain_b > player_b.life {
                player_b.life = 0;
            } else {
                player_b.life -= drain_b;
            }

            // Write updated players and match state
            world.write_model(@player_a);
            world.write_model(@player_b);
            world.write_model(@match_data);

            // Emit event
            world.emit_event(@SlotResolved {
                match_id,
                slot_index,
                player_a_card: card_a_id,
                player_b_card: card_b_id,
                player_a_knock: knock_a,
                player_b_knock: knock_b,
                interaction_result: interaction_result_to_u8(resolution.interaction_result),
                timestamp: get_block_timestamp(),
            });
        }
    }

    fn get_slot_card(move_box: MoveBox, index: u8) -> u32 {
        if index == 0 {
            return move_box.slot_0;
        };
        if index == 1 {
            return move_box.slot_1;
        };
        if index == 2 {
            return move_box.slot_2;
        };
        if index == 3 {
            return move_box.slot_3;
        };
        if index == 4 {
            return move_box.slot_4;
        };
        0
    }

    fn resolve_interaction(
        card_a: MoveCard, card_b: MoveCard, player_a: Player, player_b: Player,
        addr_a: ContractAddress, addr_b: ContractAddress,
    ) -> SlotResolution {
        let mut result = InteractionResult::Normal;

        // Finisher checks
        if card_a.move_type == MoveType::Finisher {
            let is_staggered = (player_b.status_flags & 1) != 0;
            if player_b.life <= FINISHER_THRESHOLD || is_staggered {
                return SlotResolution {
                    slot_index: 0,
                    player_a_card: card_a.card_id,
                    player_b_card: card_b.card_id,
                    player_a_knock: card_a.base_knock,
                    player_b_knock: 0,
                    interaction_result: InteractionResult::FinisherHit,
                };
            }
        }

        if card_b.move_type == MoveType::Finisher {
            let is_staggered = (player_a.status_flags & 1) != 0;
            if player_a.life <= FINISHER_THRESHOLD || is_staggered {
                return SlotResolution {
                    slot_index: 0,
                    player_a_card: card_a.card_id,
                    player_b_card: card_b.card_id,
                    player_a_knock: 0,
                    player_b_knock: card_b.base_knock,
                    interaction_result: InteractionResult::FinisherHit,
                };
            }
        }

        // Strike vs Defense
        if card_a.move_type == MoveType::Strike && card_b.move_type == MoveType::Defense {
            result = InteractionResult::Blocked;
        } else if card_b.move_type == MoveType::Strike && card_a.move_type == MoveType::Defense {
            result = InteractionResult::Blocked;
        }
        // Strike vs Evasion
        else if card_a.move_type == MoveType::Strike && card_b.move_type == MoveType::Evasion {
            result = InteractionResult::Dodged;
        } else if card_b.move_type == MoveType::Strike && card_a.move_type == MoveType::Evasion {
            result = InteractionResult::Dodged;
        }
        // Strike vs Counter
        else if card_a.move_type == MoveType::Strike && card_b.move_type == MoveType::Counter {
            result = InteractionResult::Countered;
        } else if card_b.move_type == MoveType::Strike && card_a.move_type == MoveType::Counter {
            result = InteractionResult::Countered;
        }
        // Control cards
        else if card_a.move_type == MoveType::Control || card_b.move_type == MoveType::Control {
            result = InteractionResult::ControlEffect;
        };

        SlotResolution {
            slot_index: 0,
            player_a_card: card_a.card_id,
            player_b_card: card_b.card_id,
            player_a_knock: card_a.base_knock,
            player_b_knock: card_b.base_knock,
            interaction_result: result,
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
        }
    }
}
