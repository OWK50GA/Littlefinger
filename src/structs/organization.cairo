use starknet::ContractAddress;
use starknet::storage::Vec;
use crate::structs::base::ContractAddressDefault;

#[derive(Drop, Serde, Clone, Default, PartialEq)]
pub struct OrganizationInfo {
    pub name: ByteArray,
    pub deployer: ContractAddress,
    pub additional_data: Array<felt252>,
    pub ipfs_url: ByteArray,
}


#[derive(Drop, Copy, Serde, PartialEq)]
pub struct OwnerInit {
    pub address: ContractAddress,
    pub fnmae: felt252,
    pub lastname: felt252,
}

#[derive(Drop, Serde, PartialEq)]
pub struct OrganizationConfig {
    pub name: Option<ByteArray>,
    pub admins: Array<ContractAddress>,
}

#[starknet::storage_node]
pub struct OrganizationConfigNode {
    pub additional_data: Vec<felt252>,
}
