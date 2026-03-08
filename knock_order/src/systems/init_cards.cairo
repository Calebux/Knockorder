#[dojo::contract]
pub mod InitCards {
    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;
    use dojo_starter::base::events::CardInitialized;
    use dojo_starter::interfaces::IInitCards::IInitCards;
    use dojo_starter::models::{MoveCard, MoveType, Rarity};
    use starknet::get_block_timestamp;

    #[abi(embed_v0)]
    impl InitCardsImpl of IInitCards<ContractState> {
        fn init_default_cards(ref self: ContractState) {
            let mut world = self.world_default();

            // Initialize 10 core move cards as specified in MVP scope
            // Card 1: Basic Strike
            let card1 = MoveCard {
                card_id: 1,
                name: 'Basic Strike',
                move_type: MoveType::Strike,
                rarity: Rarity::Common,
                base_knock: 10,
                priority: 5,
                drain_multiplier: 100,
            };
            world.write_model(@card1);
            world.emit_event(@CardInitialized { card_id: 1, name: 'Basic Strike', timestamp: get_block_timestamp() });

            // Card 2: Heavy Strike
            let card2 = MoveCard {
                card_id: 2,
                name: 'Heavy Strike',
                move_type: MoveType::Strike,
                rarity: Rarity::Common,
                base_knock: 15,
                priority: 3,
                drain_multiplier: 100,
            };
            world.write_model(@card2);
            world.emit_event(@CardInitialized { card_id: 2, name: 'Heavy Strike', timestamp: get_block_timestamp() });

            // Card 3: Quick Strike
            let card3 = MoveCard {
                card_id: 3,
                name: 'Quick Strike',
                move_type: MoveType::Strike,
                rarity: Rarity::Common,
                base_knock: 8,
                priority: 7,
                drain_multiplier: 100,
            };
            world.write_model(@card3);
            world.emit_event(@CardInitialized { card_id: 3, name: 'Quick Strike', timestamp: get_block_timestamp() });

            // Card 4: Block
            let card4 = MoveCard {
                card_id: 4,
                name: 'Block',
                move_type: MoveType::Defense,
                rarity: Rarity::Common,
                base_knock: 0,
                priority: 6,
                drain_multiplier: 100,
            };
            world.write_model(@card4);
            world.emit_event(@CardInitialized { card_id: 4, name: 'Block', timestamp: get_block_timestamp() });

            // Card 5: Perfect Block
            let card5 = MoveCard {
                card_id: 5,
                name: 'Perfect Block',
                move_type: MoveType::Defense,
                rarity: Rarity::Rare,
                base_knock: 0,
                priority: 8,
                drain_multiplier: 100,
            };
            world.write_model(@card5);
            world.emit_event(@CardInitialized { card_id: 5, name: 'Perfect Block', timestamp: get_block_timestamp() });

            // Card 6: Counter
            let card6 = MoveCard {
                card_id: 6,
                name: 'Counter',
                move_type: MoveType::Counter,
                rarity: Rarity::Rare,
                base_knock: 12,
                priority: 9,
                drain_multiplier: 100,
            };
            world.write_model(@card6);
            world.emit_event(@CardInitialized { card_id: 6, name: 'Counter', timestamp: get_block_timestamp() });

            // Card 7: Dodge
            let card7 = MoveCard {
                card_id: 7,
                name: 'Dodge',
                move_type: MoveType::Evasion,
                rarity: Rarity::Common,
                base_knock: 0,
                priority: 10,
                drain_multiplier: 100,
            };
            world.write_model(@card7);
            world.emit_event(@CardInitialized { card_id: 7, name: 'Dodge', timestamp: get_block_timestamp() });

            // Card 8: Control
            let card8 = MoveCard {
                card_id: 8,
                name: 'Control',
                move_type: MoveType::Control,
                rarity: Rarity::Epic,
                base_knock: 5,
                priority: 4,
                drain_multiplier: 100,
            };
            world.write_model(@card8);
            world.emit_event(@CardInitialized { card_id: 8, name: 'Control', timestamp: get_block_timestamp() });

            // Card 9: Finisher
            let card9 = MoveCard {
                card_id: 9,
                name: 'Finisher',
                move_type: MoveType::Finisher,
                rarity: Rarity::Legendary,
                base_knock: 30,
                priority: 2,
                drain_multiplier: 100,
            };
            world.write_model(@card9);
            world.emit_event(@CardInitialized { card_id: 9, name: 'Finisher', timestamp: get_block_timestamp() });

            // Card 10: Feint
            let card10 = MoveCard {
                card_id: 10,
                name: 'Feint',
                move_type: MoveType::Strike,  // Feint is a special strike
                rarity: Rarity::Rare,
                base_knock: 5,
                priority: 6,
                drain_multiplier: 100,
            };
            world.write_model(@card10);
            world.emit_event(@CardInitialized { card_id: 10, name: 'Feint', timestamp: get_block_timestamp() });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
        }
    }
}
