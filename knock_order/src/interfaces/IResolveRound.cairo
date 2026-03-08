#[starknet::interface]
pub trait IResolveRound<T> {
    fn resolve_round(ref self: T, match_id: u64);
}
