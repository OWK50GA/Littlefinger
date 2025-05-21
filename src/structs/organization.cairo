use starknet::ContractAddress;
use crate::structs::base::ContractAddressDefault;

#[derive(Drop, Serde, Clone, Default)]
pub struct OrganizationInfo {
    pub name: ByteArray,
    pub deployer: ContractAddress,
    pub additional_data: Array<felt252>,
    pub ipfs_url: ByteArray,
}

#[starknet::storage_node]
pub struct OrganizationInfoNode {
    // pub additional_data: Vec<felt252>,
}
