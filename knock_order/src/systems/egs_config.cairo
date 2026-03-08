/// Dojo system that stores the KnockOrderEGS adapter address in world state.
/// Call set_adapter(<adapter_addr>) once after deploying the EGS adapter contract.
#[dojo::contract]
pub mod EgsConfig {
    use dojo::model::ModelStorage;
    use dojo_starter::interfaces::IEgsConfig::IEgsConfig;
    use dojo_starter::models::EgsConfig;
    use starknet::{ContractAddress, get_caller_address};

    #[abi(embed_v0)]
    impl EgsConfigImpl of IEgsConfig<ContractState> {
        fn set_adapter(ref self: ContractState, adapter: ContractAddress) {
            let mut world = self.world_default();
            // Only the Dojo world owner may set this
            let caller = get_caller_address();
            assert(world.dispatcher.is_owner(0, caller), 'not world owner');

            let config = EgsConfig { id: 0_u8, adapter_address: adapter };
            world.write_model(@config);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
        }
    }
}
