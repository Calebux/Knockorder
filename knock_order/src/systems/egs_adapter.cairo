/// KnockOrder EGS Adapter
///
/// Standalone Starknet contract (not a Dojo contract) that implements the
/// Provable Games Embeddable Game Standard (EGS) IMinigameTokenData interface.
///
/// Deployment:
///   1. Deploy this contract with the deployer address as `owner`.
///   2. Call set_authorized_caller(<EndMatch_contract_address>).
///   3. Register it in the EGS Registry (off-chain via Provable Games tooling).
///
/// Scoring:
///   score = winner_wins * 100 + loser_wins
///   Examples: 2-0 → 200 | 2-1 → 201 | 3-0 → 300 | 3-1 → 301 | 3-2 → 302
///   Higher score = cleaner win. game_over = true once match is finalised.
#[starknet::contract]
pub mod KnockOrderEGS {
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address};
    use dojo_starter::interfaces::IMinigameTokenData::{
        IMINIGAME_ID, ISRC5_ID, IMinigameTokenData, ISRC5,
    };
    use dojo_starter::interfaces::IEgsAdapter::IEgsAdapter;

    #[storage]
    struct Storage {
        /// EGS score per match_id (token_id)
        scores: Map<felt252, u64>,
        /// Whether a match has concluded
        game_overs: Map<felt252, bool>,
        /// SRC5 interface registry (inline — no OZ dependency needed)
        supported_interfaces: Map<felt252, bool>,
        /// Contract owner (deployer)
        owner: ContractAddress,
        /// Address allowed to call record_result (the EndMatch Dojo system)
        authorized_caller: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ScoreUpdate: ScoreUpdate,
        GameOver: GameOver,
    }

    #[derive(Drop, starknet::Event)]
    struct ScoreUpdate {
        #[key]
        match_id: felt252,
        score: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct GameOver {
        #[key]
        match_id: felt252,
        score: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
        // Register SRC5 itself
        self.supported_interfaces.write(ISRC5_ID, true);
        // Register IMinigameTokenData (the EGS interface)
        self.supported_interfaces.write(IMINIGAME_ID, true);
    }

    // ── IMinigameTokenData ───────────────────────────────────────────────────

    #[abi(embed_v0)]
    impl MinigameTokenDataImpl of IMinigameTokenData<ContractState> {
        fn score(self: @ContractState, token_id: felt252) -> u64 {
            self.scores.read(token_id)
        }

        fn game_over(self: @ContractState, token_id: felt252) -> bool {
            self.game_overs.read(token_id)
        }

        fn score_batch(self: @ContractState, token_ids: Span<felt252>) -> Array<u64> {
            let mut results: Array<u64> = array![];
            let mut i: u32 = 0;
            loop {
                if i >= token_ids.len() {
                    break;
                }
                results.append(self.scores.read(*token_ids.at(i)));
                i += 1;
            };
            results
        }

        fn game_over_batch(self: @ContractState, token_ids: Span<felt252>) -> Array<bool> {
            let mut results: Array<bool> = array![];
            let mut i: u32 = 0;
            loop {
                if i >= token_ids.len() {
                    break;
                }
                results.append(self.game_overs.read(*token_ids.at(i)));
                i += 1;
            };
            results
        }
    }

    // ── SRC5 introspection ───────────────────────────────────────────────────

    #[abi(embed_v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            self.supported_interfaces.read(interface_id)
        }
    }

    // ── IEgsAdapter (admin interface) ────────────────────────────────────────

    #[abi(embed_v0)]
    impl EgsAdapterImpl of IEgsAdapter<ContractState> {
        fn record_result(ref self: ContractState, match_id: felt252, score: u64) {
            let caller = get_caller_address();
            let auth = self.authorized_caller.read();
            let owner = self.owner.read();
            assert(caller == auth || caller == owner, 'not authorised');
            assert(!self.game_overs.read(match_id), 'already recorded');

            self.scores.write(match_id, score);
            self.game_overs.write(match_id, true);

            self.emit(ScoreUpdate { match_id, score });
            self.emit(GameOver { match_id, score });
        }

        fn set_authorized_caller(ref self: ContractState, caller: ContractAddress) {
            assert(get_caller_address() == self.owner.read(), 'not owner');
            self.authorized_caller.write(caller);
        }
    }
}
