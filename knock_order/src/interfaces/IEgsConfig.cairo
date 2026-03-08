use starknet::ContractAddress;

#[starknet::interface]
pub trait IEgsConfig<T> {
    /// Owner-only: point the world at the deployed KnockOrderEGS adapter contract.
    fn set_adapter(ref self: T, adapter: ContractAddress);
}
