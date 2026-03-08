#[starknet::interface]
pub trait IDrainLife<T> {
    fn drain_life(ref self: T, match_id: u64, player_a_knock: u32, player_b_knock: u32);
}
