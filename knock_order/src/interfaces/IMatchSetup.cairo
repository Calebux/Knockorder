use starknet::ContractAddress;

#[starknet::interface]
pub trait IMatchSetup<T> {
    fn create_match(ref self: T, opponent: ContractAddress, best_of: u8) -> u64;
    fn join_match(ref self: T, match_id: u64);
}
