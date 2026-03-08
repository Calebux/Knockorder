/// EGS SNIP-5 interface ID (XOR of extended function selectors for IMinigame)
/// Source: https://github.com/Provable-Games/game-components
pub const IMINIGAME_ID: felt252 =
    0x3d1730c22937da340212dec5546ff5826895259966fa6a92d1191ab068cc2b4;

/// Standard SRC5 introspection interface ID
pub const ISRC5_ID: felt252 =
    0x3f918d17e5ee77373b56385708f855659a07eb2ca0352b4bb00200e4ce364ad;

/// Mandatory EGS interface — platforms query score and game_over by token_id.
/// token_id == match_id (u64 cast to felt252).
#[starknet::interface]
pub trait IMinigameTokenData<TState> {
    fn score(self: @TState, token_id: felt252) -> u64;
    fn game_over(self: @TState, token_id: felt252) -> bool;
    fn score_batch(self: @TState, token_ids: Span<felt252>) -> Array<u64>;
    fn game_over_batch(self: @TState, token_ids: Span<felt252>) -> Array<bool>;
}

/// SRC5 introspection — allows platforms to confirm EGS compliance on-chain.
#[starknet::interface]
pub trait ISRC5<TState> {
    fn supports_interface(self: @TState, interface_id: felt252) -> bool;
}
