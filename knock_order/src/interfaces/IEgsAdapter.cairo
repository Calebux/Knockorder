use starknet::ContractAddress;

/// Interface used by EndMatch to push results into the EGS adapter.
#[starknet::interface]
pub trait IEgsAdapter<T> {
    /// Record a completed match result. Called by the authorized Dojo EndMatch system.
    /// score = winner_wins * 100 + loser_wins (e.g. 2-0 → 200, 2-1 → 201, 3-2 → 302)
    fn record_result(ref self: T, match_id: felt252, score: u64);

    /// Owner-only: authorise the EndMatch contract address to call record_result.
    fn set_authorized_caller(ref self: T, caller: ContractAddress);
}
