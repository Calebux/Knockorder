#[starknet::interface]
pub trait IEndMatch<T> {
    fn end_match(ref self: T, match_id: u64);
}
