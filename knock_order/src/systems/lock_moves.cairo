#[dojo::contract]
pub mod LockMoves {
    use dojo::event::EventStorage;
    use dojo::model::ModelStorage;
    use dojo_starter::base::events::MovesLocked;
    use dojo_starter::interfaces::ILockMoves::ILockMoves;
    use dojo_starter::models::{Match, MatchState, MoveBox, Player, MAX_SLOTS};
    use starknet::{get_block_timestamp, get_caller_address};

    #[abi(embed_v0)]
    impl LockMovesImpl of ILockMoves<ContractState> {
        fn lock_moves(ref self: ContractState, match_id: u64, slots: Span<u32>) {
            let mut world = self.world_default();
            let player = get_caller_address();

            // Validate slots length
            assert(slots.len() == MAX_SLOTS.into(), 'must provide exactly 5 slots');

            // Read match state
            let mut match_data: Match = world.read_model(match_id);
            assert(match_data.match_state == MatchState::Setup, 'match not in setup phase');
            assert(
                match_data.player_a == player || match_data.player_b == player,
                'not a player in this match',
            );

            // Validate player exists
            let mut player_data: Player = world.read_model(player);
            assert(player_data.life > 0, 'player is dead');

            // Check if already locked
            let mut move_box: MoveBox = world.read_model((match_id, player));
            assert(!move_box.locked, 'moves already locked');

            // Validate no duplicate cards (unless explicitly allowed)
            // For MVP, we'll allow duplicates but can add validation later
            // Convert Span to MoveBox slots
            let slot_0 = *slots.at(0);
            let slot_1 = *slots.at(1);
            let slot_2 = *slots.at(2);
            let slot_3 = *slots.at(3);
            let slot_4 = *slots.at(4);

            // Update MoveBox
            move_box.match_id = match_id;
            move_box.player = player;
            move_box.round = match_data.round;
            move_box.slot_0 = slot_0;
            move_box.slot_1 = slot_1;
            move_box.slot_2 = slot_2;
            move_box.slot_3 = slot_3;
            move_box.slot_4 = slot_4;
            move_box.locked = true;

            world.write_model(@move_box);

            // Check if both players locked - re-read match_data to get latest state
            let current_match: Match = world.read_model(match_id);
            let player_a_box: MoveBox = world.read_model((match_id, current_match.player_a));
            let player_b_box: MoveBox = world.read_model((match_id, current_match.player_b));

            if player_a_box.locked && player_b_box.locked {
                let mut updated_match: Match = world.read_model(match_id);
                updated_match.match_state = MatchState::Locked;
                world.write_model(@updated_match);
            }

            world.emit_event(@MovesLocked {
                match_id,
                player,
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
