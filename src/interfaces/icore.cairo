use crate::structs::core::{CoreConfigParams, PollConfigParams};

#[starknet::interface]
pub trait IConfig<TContractState> {
    fn update_config(ref self: TContractState, config: Config);
}

#[derive(Drop, Copy, Serde, PartialEq)]
pub enum Config {
    #[default]
    Core: CoreConfigParams,
    Poll: PollConfigParams,
}

#[starknet::storage_node]
pub struct CoreConfigNode {}
