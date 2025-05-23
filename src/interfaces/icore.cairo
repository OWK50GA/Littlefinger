use crate::structs::core::Config;

#[starknet::interface]
pub trait IConfig<TContractState> {
    fn update_config(ref self: TContractState, config: Config);
}
