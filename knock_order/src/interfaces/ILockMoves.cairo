#[starknet::interface]
pub trait ILockMoves<T> {
    fn lock_moves(ref self: T, match_id: u64, slots: Span<u32>);
}
