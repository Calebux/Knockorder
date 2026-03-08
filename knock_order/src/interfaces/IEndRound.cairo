#[starknet::interface]
pub trait IEndRound<T> {
    fn end_round(ref self: T, match_id: u64);
}
