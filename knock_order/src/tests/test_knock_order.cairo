#[cfg(test)]
mod tests {
    use dojo_starter::base::events;
    use dojo_starter::interfaces::IMatchSetup::{IMatchSetupDispatcher, IMatchSetupDispatcherTrait};
    use dojo_starter::interfaces::ILockMoves::{ILockMovesDispatcher, ILockMovesDispatcherTrait};
    use dojo_starter::interfaces::IResolveSlot::{IResolveSlotDispatcher, IResolveSlotDispatcherTrait};
    use dojo_starter::interfaces::IResolveRound::{IResolveRoundDispatcher, IResolveRoundDispatcherTrait};
    use dojo_starter::interfaces::IEndRound::{IEndRoundDispatcher, IEndRoundDispatcherTrait};
    use dojo_starter::interfaces::IEndMatch::{IEndMatchDispatcher, IEndMatchDispatcherTrait};
    use dojo_starter::interfaces::IInitCards::{IInitCardsDispatcher, IInitCardsDispatcherTrait};
    use dojo_starter::models::{
        m_Match, m_MoveBox, m_MoveCard, m_Player, Match, MatchState, MoveBox, MoveCard, MoveType,
        Player, STARTING_LIFE,
    };
    use dojo_starter::systems::match_setup::MatchSetup;
    use dojo_starter::systems::lock_moves::LockMoves;
    use dojo_starter::systems::resolve_slot::ResolveSlot;
    use dojo_starter::systems::resolve_round::ResolveRound;
    use dojo_starter::systems::end_round::EndRound;
    use dojo_starter::systems::end_match::EndMatch;
    use dojo_starter::systems::init_cards::InitCards;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::{WorldStorageTrait, world};
    use dojo_cairo_test::{
        ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
        spawn_test_world,
    };
    use starknet::{ContractAddress, contract_address_const, testing};

    fn PLAYER_A() -> ContractAddress {
        contract_address_const::<0x1>()
    }

    fn PLAYER_B() -> ContractAddress {
        contract_address_const::<0x2>()
    }

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "dojo_starter",
            resources: [
                TestResource::Model(m_Player::TEST_CLASS_HASH),
                TestResource::Model(m_Match::TEST_CLASS_HASH),
                TestResource::Model(m_MoveBox::TEST_CLASS_HASH),
                TestResource::Model(m_MoveCard::TEST_CLASS_HASH),
                TestResource::Event(events::e_MatchCreated::TEST_CLASS_HASH),
                TestResource::Event(events::e_PlayerJoined::TEST_CLASS_HASH),
                TestResource::Event(events::e_MovesLocked::TEST_CLASS_HASH),
                TestResource::Event(events::e_SlotResolved::TEST_CLASS_HASH),
                TestResource::Event(events::e_RoundResolved::TEST_CLASS_HASH),
                TestResource::Event(events::e_LifeDrained::TEST_CLASS_HASH),
                TestResource::Event(events::e_RoundEnded::TEST_CLASS_HASH),
                TestResource::Event(events::e_MatchEnded::TEST_CLASS_HASH),
                TestResource::Event(events::e_CardInitialized::TEST_CLASS_HASH),
                TestResource::Contract(MatchSetup::TEST_CLASS_HASH),
                TestResource::Contract(LockMoves::TEST_CLASS_HASH),
                TestResource::Contract(ResolveSlot::TEST_CLASS_HASH),
                TestResource::Contract(ResolveRound::TEST_CLASS_HASH),
                TestResource::Contract(EndRound::TEST_CLASS_HASH),
                TestResource::Contract(EndMatch::TEST_CLASS_HASH),
                TestResource::Contract(InitCards::TEST_CLASS_HASH),
            ]
                .span(),
        };

        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"dojo_starter", @"MatchSetup")
                .with_writer_of([dojo::utils::bytearray_hash(@"dojo_starter")].span()),
            ContractDefTrait::new(@"dojo_starter", @"LockMoves")
                .with_writer_of([dojo::utils::bytearray_hash(@"dojo_starter")].span()),
            ContractDefTrait::new(@"dojo_starter", @"ResolveSlot")
                .with_writer_of([dojo::utils::bytearray_hash(@"dojo_starter")].span()),
            ContractDefTrait::new(@"dojo_starter", @"ResolveRound")
                .with_writer_of([dojo::utils::bytearray_hash(@"dojo_starter")].span()),
            ContractDefTrait::new(@"dojo_starter", @"EndRound")
                .with_writer_of([dojo::utils::bytearray_hash(@"dojo_starter")].span()),
            ContractDefTrait::new(@"dojo_starter", @"EndMatch")
                .with_writer_of([dojo::utils::bytearray_hash(@"dojo_starter")].span()),
            ContractDefTrait::new(@"dojo_starter", @"InitCards")
                .with_writer_of([dojo::utils::bytearray_hash(@"dojo_starter")].span()),
        ]
            .span()
    }

    // ============================================================================
    // Test: Initialize Cards
    // ============================================================================

    #[test]
    fn test_init_cards() {
        let caller = PLAYER_A();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (init_cards_address, _) = world.dns(@"InitCards").unwrap();
        let init_cards = IInitCardsDispatcher { contract_address: init_cards_address };
        testing::set_contract_address(caller);

        init_cards.init_default_cards();

        // Verify cards were created
        let card1: MoveCard = world.read_model(1);
        assert(card1.card_id == 1, 'Card 1 ID mismatch');
        assert(card1.name == 'Basic Strike', 'Card 1 name mismatch');
        assert(card1.move_type == MoveType::Strike, 'Card 1 type mismatch');
        assert(card1.base_knock == 10, 'Card 1 knock mismatch');

        let card9: MoveCard = world.read_model(9);
        assert(card9.card_id == 9, 'Card 9 ID mismatch');
        assert(card9.name == 'Finisher', 'Card 9 name mismatch');
        assert(card9.move_type == MoveType::Finisher, 'Card 9 type mismatch');
    }

    // ============================================================================
    // Test: Match Creation and Joining
    // ============================================================================

    #[test]
    fn test_create_match() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };
        testing::set_contract_address(player_a);

        let match_id = match_setup.create_match(player_b, 3);

        // Verify match was created
        let match_data: Match = world.read_model(match_id);
        assert(match_data.match_id == match_id, 'Match ID mismatch');
        assert(match_data.player_a == player_a, 'Player A mismatch');
        assert(match_data.player_b == player_b, 'Player B mismatch');
        assert(match_data.best_of == 3, 'Best of mismatch');
        assert(match_data.match_state == MatchState::Waiting, 'Match state should be Waiting');
        assert(match_data.round == 1, 'Round should be 1');

        // Verify player A was initialized
        let player_a_data: Player = world.read_model(player_a);
        assert(player_a_data.life == STARTING_LIFE, 'Player A life mismatch');
        assert(player_a_data.address == player_a, 'Player A address mismatch');
    }

    #[test]
    fn test_join_match() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };

        // Create match
        testing::set_contract_address(player_a);
        let match_id = match_setup.create_match(player_b, 3);

        // Join match
        testing::set_contract_address(player_b);
        match_setup.join_match(match_id);

        // Verify match state changed
        let match_data: Match = world.read_model(match_id);
        assert(match_data.match_state == MatchState::Setup, 'Match state should be Setup');

        // Verify player B was initialized
        let player_b_data: Player = world.read_model(player_b);
        assert(player_b_data.life == STARTING_LIFE, 'Player B life mismatch');
        assert(player_b_data.address == player_b, 'Player B address mismatch');
    }

    #[test]
    #[should_panic]
    fn test_join_match_wrong_player() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let wrong_player = contract_address_const::<0x999>();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };

        testing::set_contract_address(player_a);
        let match_id = match_setup.create_match(player_b, 3);

        // Wrong player tries to join
        testing::set_contract_address(wrong_player);
        match_setup.join_match(match_id); // Should panic
    }

    // ============================================================================
    // Test: Lock Moves
    // ============================================================================

    #[test]
    fn test_lock_moves() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        // Initialize cards
        let (init_cards_address, _) = world.dns(@"InitCards").unwrap();
        let init_cards = IInitCardsDispatcher { contract_address: init_cards_address };
        testing::set_contract_address(player_a);
        init_cards.init_default_cards();

        // Create and join match
        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };
        testing::set_contract_address(player_a);
        let match_id = match_setup.create_match(player_b, 3);
        testing::set_contract_address(player_b);
        match_setup.join_match(match_id);

        // Lock moves for player A
        let (lock_moves_address, _) = world.dns(@"LockMoves").unwrap();
        let lock_moves = ILockMovesDispatcher { contract_address: lock_moves_address };
        testing::set_contract_address(player_a);
        let slots = array![1, 2, 3, 4, 5];
        lock_moves.lock_moves(match_id, slots.span());

        // Verify MoveBox was created and locked
        let move_box_a: MoveBox = world.read_model((match_id, player_a));
        assert(move_box_a.locked, 'MoveBox A should be locked');
        assert(move_box_a.slot_0 == 1, 'Slot 0 mismatch');
        assert(move_box_a.slot_4 == 5, 'Slot 4 mismatch');
        assert(move_box_a.round == 1, 'Round mismatch');

        // Lock moves for player B
        testing::set_contract_address(player_b);
        let slots_b = array![6, 7, 8, 9, 10];
        lock_moves.lock_moves(match_id, slots_b.span());

        // Verify both players locked and match state changed
        let match_data: Match = world.read_model(match_id);
        assert(match_data.match_state == MatchState::Locked, 'Match should be Locked');
    }

    #[test]
    #[should_panic]
    fn test_lock_moves_wrong_slot_count() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };
        testing::set_contract_address(player_a);
        let match_id = match_setup.create_match(player_b, 3);
        testing::set_contract_address(player_b);
        match_setup.join_match(match_id);

        let (lock_moves_address, _) = world.dns(@"LockMoves").unwrap();
        let lock_moves = ILockMovesDispatcher { contract_address: lock_moves_address };
        testing::set_contract_address(player_a);
        let wrong_slots = array![1, 2, 3]; // Only 3 slots, should be 5
        lock_moves.lock_moves(match_id, wrong_slots.span()); // Should panic
    }

    // ============================================================================
    // Test: Resolve Slot
    // ============================================================================

    #[test]
    fn test_resolve_slot_strike_vs_strike() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        // Initialize cards
        let (init_cards_address, _) = world.dns(@"InitCards").unwrap();
        let init_cards = IInitCardsDispatcher { contract_address: init_cards_address };
        testing::set_contract_address(player_a);
        init_cards.init_default_cards();

        // Create match, join, and lock moves
        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };
        testing::set_contract_address(player_a);
        let match_id = match_setup.create_match(player_b, 3);
        testing::set_contract_address(player_b);
        match_setup.join_match(match_id);

        let (lock_moves_address, _) = world.dns(@"LockMoves").unwrap();
        let lock_moves = ILockMovesDispatcher { contract_address: lock_moves_address };
        testing::set_contract_address(player_a);
        lock_moves.lock_moves(match_id, array![1, 1, 1, 1, 1].span()); // All Basic Strikes
        testing::set_contract_address(player_b);
        lock_moves.lock_moves(match_id, array![1, 1, 1, 1, 1].span()); // All Basic Strikes

        // Resolve first slot
        let (resolve_slot_address, _) = world.dns(@"ResolveSlot").unwrap();
        let resolve_slot = IResolveSlotDispatcher { contract_address: resolve_slot_address };
        resolve_slot.resolve_slot(match_id, 0);

        // Verify life was drained (both players take 10 knock)
        let player_a_data: Player = world.read_model(player_a);
        let player_b_data: Player = world.read_model(player_b);
        assert(player_a_data.life == STARTING_LIFE - 10, 'Player A life should be 90');
        assert(player_b_data.life == STARTING_LIFE - 10, 'Player B life should be 90');
    }

    #[test]
    fn test_resolve_slot_strike_vs_defense() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        // Initialize cards
        let (init_cards_address, _) = world.dns(@"InitCards").unwrap();
        let init_cards = IInitCardsDispatcher { contract_address: init_cards_address };
        testing::set_contract_address(player_a);
        init_cards.init_default_cards();

        // Create match, join, and lock moves
        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };
        testing::set_contract_address(player_a);
        let match_id = match_setup.create_match(player_b, 3);
        testing::set_contract_address(player_b);
        match_setup.join_match(match_id);

        let (lock_moves_address, _) = world.dns(@"LockMoves").unwrap();
        let lock_moves = ILockMovesDispatcher { contract_address: lock_moves_address };
        testing::set_contract_address(player_a);
        lock_moves.lock_moves(match_id, array![1, 1, 1, 1, 1].span()); // All Strikes
        testing::set_contract_address(player_b);
        lock_moves.lock_moves(match_id, array![4, 4, 4, 4, 4].span()); // All Blocks

        // Resolve first slot (Strike vs Defense)
        let (resolve_slot_address, _) = world.dns(@"ResolveSlot").unwrap();
        let resolve_slot = IResolveSlotDispatcher { contract_address: resolve_slot_address };
        resolve_slot.resolve_slot(match_id, 0);

        // Verify defense blocked the strike
        let player_a_data: Player = world.read_model(player_a);
        let player_b_data: Player = world.read_model(player_b);
        // Player A's strike (10 knock) should be blocked, so Player B takes 0 damage
        // Player B's block (0 knock) does nothing, so Player A takes 0 damage
        assert(player_a_data.life == STARTING_LIFE, 'Player A life unchanged');
        assert(player_b_data.life == STARTING_LIFE, 'Player B life unchanged');
    }

    #[test]
    fn test_resolve_slot_finisher() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        // Initialize cards
        let (init_cards_address, _) = world.dns(@"InitCards").unwrap();
        let init_cards = IInitCardsDispatcher { contract_address: init_cards_address };
        testing::set_contract_address(player_a);
        init_cards.init_default_cards();

        // Create match, join
        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };
        testing::set_contract_address(player_a);
        let match_id = match_setup.create_match(player_b, 3);
        testing::set_contract_address(player_b);
        match_setup.join_match(match_id);

        // Set player B's life low enough for finisher
        let mut player_b_data: Player = world.read_model(player_b);
        player_b_data.life = 25; // Below FINISHER_THRESHOLD (30)
        world.write_model_test(@player_b_data);

        // Lock moves
        let (lock_moves_address, _) = world.dns(@"LockMoves").unwrap();
        let lock_moves = ILockMovesDispatcher { contract_address: lock_moves_address };
        testing::set_contract_address(player_a);
        lock_moves.lock_moves(match_id, array![9, 1, 1, 1, 1].span()); // Finisher in slot 0
        testing::set_contract_address(player_b);
        lock_moves.lock_moves(match_id, array![1, 1, 1, 1, 1].span());

        // Resolve first slot (Finisher)
        let (resolve_slot_address, _) = world.dns(@"ResolveSlot").unwrap();
        let resolve_slot = IResolveSlotDispatcher { contract_address: resolve_slot_address };
        resolve_slot.resolve_slot(match_id, 0);

        // Verify finisher ended the round
        let match_data: Match = world.read_model(match_id);
        assert(match_data.match_state == MatchState::RoundEnd, 'Round should end with finisher');
    }

    // ============================================================================
    // Test: Resolve Round
    // ============================================================================

    #[test]
    fn test_resolve_round() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        // Initialize cards
        let (init_cards_address, _) = world.dns(@"InitCards").unwrap();
        let init_cards = IInitCardsDispatcher { contract_address: init_cards_address };
        testing::set_contract_address(player_a);
        init_cards.init_default_cards();

        // Create match, join, and lock moves
        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };
        testing::set_contract_address(player_a);
        let match_id = match_setup.create_match(player_b, 3);
        testing::set_contract_address(player_b);
        match_setup.join_match(match_id);

        let (lock_moves_address, _) = world.dns(@"LockMoves").unwrap();
        let lock_moves = ILockMovesDispatcher { contract_address: lock_moves_address };
        testing::set_contract_address(player_a);
        lock_moves.lock_moves(match_id, array![1, 1, 1, 1, 1].span());
        testing::set_contract_address(player_b);
        lock_moves.lock_moves(match_id, array![1, 1, 1, 1, 1].span());

        // Verify match is locked
        let match_check: Match = world.read_model(match_id);
        assert(match_check.match_state == MatchState::Locked, 'Match should be locked');

        // Resolve entire round
        let (resolve_round_address, _) = world.dns(@"ResolveRound").unwrap();
        let resolve_round = IResolveRoundDispatcher { contract_address: resolve_round_address };
        resolve_round.resolve_round(match_id);

        // Verify round ended
        let match_data: Match = world.read_model(match_id);
        assert(match_data.match_state == MatchState::RoundEnd, 'Match should be RoundEnd');

        // Verify both players took damage (5 slots × 10 knock each = 50 damage)
        let player_a_data: Player = world.read_model(player_a);
        let player_b_data: Player = world.read_model(player_b);
        assert(player_a_data.life == STARTING_LIFE - 50, 'Player A should have 50 life');
        assert(player_b_data.life == STARTING_LIFE - 50, 'Player B should have 50 life');
    }

    // ============================================================================
    // Test: End Round
    // ============================================================================

    #[test]
    fn test_end_round_player_a_wins() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        // Initialize cards
        let (init_cards_address, _) = world.dns(@"InitCards").unwrap();
        let init_cards = IInitCardsDispatcher { contract_address: init_cards_address };
        testing::set_contract_address(player_a);
        init_cards.init_default_cards();

        // Create match
        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };
        testing::set_contract_address(player_a);
        let match_id = match_setup.create_match(player_b, 3);
        testing::set_contract_address(player_b);
        match_setup.join_match(match_id);

        // Set player B's life to 0
        let mut player_b_data: Player = world.read_model(player_b);
        player_b_data.life = 0;
        world.write_model_test(@player_b_data);

        // Set match state to RoundEnd
        let mut match_data: Match = world.read_model(match_id);
        match_data.match_state = MatchState::RoundEnd;
        world.write_model_test(@match_data);

        // End round
        let (end_round_address, _) = world.dns(@"EndRound").unwrap();
        let end_round = IEndRoundDispatcher { contract_address: end_round_address };
        end_round.end_round(match_id);

        // Verify player A won the round
        let match_data: Match = world.read_model(match_id);
        assert(match_data.player_a_wins == 1, 'Player A should have 1 win');
        assert(match_data.player_b_wins == 0, 'Player B should have 0 wins');
    }

    #[test]
    fn test_end_round_reset_for_next_round() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        // Initialize cards
        let (init_cards_address, _) = world.dns(@"InitCards").unwrap();
        let init_cards = IInitCardsDispatcher { contract_address: init_cards_address };
        testing::set_contract_address(player_a);
        init_cards.init_default_cards();

        // Create match
        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };
        testing::set_contract_address(player_a);
        let match_id = match_setup.create_match(player_b, 3);
        testing::set_contract_address(player_b);
        match_setup.join_match(match_id);

        // Set player B's life lower (player A wins round)
        let mut player_a_data: Player = world.read_model(player_a);
        player_a_data.life = 30;
        world.write_model_test(@player_a_data);
        let mut player_b_data: Player = world.read_model(player_b);
        player_b_data.life = 20; // Lower, so player A wins (more life = winner)
        world.write_model_test(@player_b_data);

        // Set match state to RoundEnd
        let mut match_data: Match = world.read_model(match_id);
        match_data.match_state = MatchState::RoundEnd;
        world.write_model_test(@match_data);

        // End round
        let (end_round_address, _) = world.dns(@"EndRound").unwrap();
        let end_round = IEndRoundDispatcher { contract_address: end_round_address };
        end_round.end_round(match_id);

        // Verify round reset for next round
        let match_data: Match = world.read_model(match_id);
        assert(match_data.round == 2, 'Round should be 2');
        assert(match_data.match_state == MatchState::Setup, 'Match Setup for next round');
        assert(match_data.player_a_wins == 1, 'Player A should have 1 win'); // Player A has more life (30 > 20)

        // Verify players reset to full life
        let player_a_data: Player = world.read_model(player_a);
        let player_b_data: Player = world.read_model(player_b);
        assert(player_a_data.life == STARTING_LIFE, 'Player A should be reset to 100');
        assert(player_b_data.life == STARTING_LIFE, 'Player B should be reset to 100');
    }

    // ============================================================================
    // Test: End Match
    // ============================================================================

    #[test]
    fn test_end_match() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        // Create match
        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };
        testing::set_contract_address(player_a);
        let match_id = match_setup.create_match(player_b, 3);
        testing::set_contract_address(player_b);
        match_setup.join_match(match_id);

        // Set match to complete (player A wins 2 rounds in best of 3)
        let mut match_data: Match = world.read_model(match_id);
        match_data.match_state = MatchState::MatchEnd;
        match_data.player_a_wins = 2;
        match_data.player_b_wins = 0;
        world.write_model_test(@match_data);

        // End match
        let (end_match_address, _) = world.dns(@"EndMatch").unwrap();
        let end_match = IEndMatchDispatcher { contract_address: end_match_address };
        end_match.end_match(match_id);

        // Verify match is finalized
        let match_data: Match = world.read_model(match_id);
        assert(match_data.match_state == MatchState::MatchEnd, 'Match should be MatchEnd');
    }

    // ============================================================================
    // Test: Complete Game Flow
    // ============================================================================

    #[test]
    #[available_gas(100000000)]
    fn test_complete_match_flow() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        // Step 1: Initialize cards
        let (init_cards_address, _) = world.dns(@"InitCards").unwrap();
        let init_cards = IInitCardsDispatcher { contract_address: init_cards_address };
        testing::set_contract_address(player_a);
        init_cards.init_default_cards();

        // Step 2: Create match
        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };
        testing::set_contract_address(player_a);
        let match_id = match_setup.create_match(player_b, 3);

        // Step 3: Join match
        testing::set_contract_address(player_b);
        match_setup.join_match(match_id);

        // Step 4: Lock moves for both players
        let (lock_moves_address, _) = world.dns(@"LockMoves").unwrap();
        let lock_moves = ILockMovesDispatcher { contract_address: lock_moves_address };
        testing::set_contract_address(player_a);
        lock_moves.lock_moves(match_id, array![1, 2, 3, 4, 5].span());
        testing::set_contract_address(player_b);
        lock_moves.lock_moves(match_id, array![1, 1, 1, 1, 1].span());

        // Verify match is locked
        let match_check: Match = world.read_model(match_id);
        assert(match_check.match_state == MatchState::Locked, 'Match should be locked');

        // Step 5: Resolve round
        let (resolve_round_address, _) = world.dns(@"ResolveRound").unwrap();
        let resolve_round = IResolveRoundDispatcher { contract_address: resolve_round_address };
        resolve_round.resolve_round(match_id);

        // Step 6: End round
        let (end_round_address, _) = world.dns(@"EndRound").unwrap();
        let end_round = IEndRoundDispatcher { contract_address: end_round_address };
        end_round.end_round(match_id);

        // Verify match progressed
        let match_data: Match = world.read_model(match_id);
        assert(match_data.round == 2, 'Round should be 2');
        assert(match_data.match_state == MatchState::Setup, 'Match Setup for round 2');

        // Verify players reset
        let player_a_data: Player = world.read_model(player_a);
        let player_b_data: Player = world.read_model(player_b);
        assert(player_a_data.life == STARTING_LIFE, 'Player A should be reset');
        assert(player_b_data.life == STARTING_LIFE, 'Player B should be reset');
    }

    // ============================================================================
    // Test: Edge Cases
    // ============================================================================

    #[test]
    #[should_panic]
    fn test_lock_moves_already_locked() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };
        testing::set_contract_address(player_a);
        let match_id = match_setup.create_match(player_b, 3);
        testing::set_contract_address(player_b);
        match_setup.join_match(match_id);

        let (lock_moves_address, _) = world.dns(@"LockMoves").unwrap();
        let lock_moves = ILockMovesDispatcher { contract_address: lock_moves_address };
        testing::set_contract_address(player_a);
        lock_moves.lock_moves(match_id, array![1, 1, 1, 1, 1].span());

        // Try to lock again
        lock_moves.lock_moves(match_id, array![2, 2, 2, 2, 2].span()); // Should panic
    }

    #[test]
    #[should_panic]
    fn test_resolve_slot_match_not_locked() {
        let player_a = PLAYER_A();
        let player_b = PLAYER_B();
        let ndef = namespace_def();
        let mut world = spawn_test_world(world::TEST_CLASS_HASH, [ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (match_setup_address, _) = world.dns(@"MatchSetup").unwrap();
        let match_setup = IMatchSetupDispatcher { contract_address: match_setup_address };
        testing::set_contract_address(player_a);
        let match_id = match_setup.create_match(player_b, 3);
        testing::set_contract_address(player_b);
        match_setup.join_match(match_id);

        // Try to resolve without locking
        let (resolve_slot_address, _) = world.dns(@"ResolveSlot").unwrap();
        let resolve_slot = IResolveSlotDispatcher { contract_address: resolve_slot_address };
        resolve_slot.resolve_slot(match_id, 0); // Should panic
    }
}
