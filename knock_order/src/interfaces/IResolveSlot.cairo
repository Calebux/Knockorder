#[starknet::interface]
pub trait IResolveSlot<T> {
    fn resolve_slot(ref self: T, match_id: u64, slot_index: u8);
}
