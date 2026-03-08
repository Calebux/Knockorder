#[starknet::interface]
pub trait IInitCards<T> {
    fn init_default_cards(ref self: T);
}
