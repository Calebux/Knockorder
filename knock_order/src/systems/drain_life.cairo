#[dojo::contract]
pub mod DrainLife {
    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;
    use dojo_starter::base::events::LifeDrained;
    use dojo_starter::interfaces::IDrainLife::IDrainLife;
    use dojo_starter::models::{Match, Player};
    use starknet::{ContractAddress, get_block_timestamp};

    #[abi(embed_v0)]
    impl DrainLifeImpl of IDrainLife<ContractState> {
        fn drain_life(
            ref self: ContractState, match_id: u64, player_a_knock: u32, player_b_knock: u32,
        ) {
            let mut world = self.world_default();

            // Read match
            let match_data: Match = world.read_model(match_id);

            // Read players
            let mut player_a: Player = world.read_model(match_data.player_a);
            let mut player_b: Player = world.read_model(match_data.player_b);

            // Calculate life drain
            // Life Drain = Knock × DrainMultiplier / 100 (for fixed-point math)
            // For MVP, using simple 1:1 ratio (DrainMultiplier = 100)
            let drain_a = player_b_knock;  // Player B's knock drains Player A's life
            let drain_b = player_a_knock;  // Player A's knock drains Player B's life

            // Apply drain (life only decreases, minimum 0)
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

            // Write updated players
            world.write_model(@player_a);
            world.write_model(@player_b);

            // Emit events
            world.emit_event(@LifeDrained {
                match_id,
                player: match_data.player_a,
                knock: player_b_knock,
                life_drained: drain_a,
                remaining_life: player_a.life,
                timestamp: get_block_timestamp(),
            });

            world.emit_event(@LifeDrained {
                match_id,
                player: match_data.player_b,
                knock: player_a_knock,
                life_drained: drain_b,
                remaining_life: player_b.life,
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
