use starknet::ContractAddress;

// Some functions here might require multiple signing to execute.
#[starknet::interface]
pub trait IOrganization<TContractState> {
    fn transfer_ownership(ref self: TContractState, to: ContractAddress);
    fn adjust_committee(
        ref self: TContractState, add: Array<ContractAddress>, subtract: Array<ContractAddress>,
    );
}
