use starknet::ContractAddress;

#[starknet::interface]
pub trait IVault<TContractState> {
    fn deposit_funds(ref self: TContractState, amount: u256);
    fn withdraw_funds(ref self: TContractState, amount: u256);
    fn emergency_freeze(ref self: TContractState);
    fn unfreeze_vault(ref self: TContractState);
    // fn bulk_transfer(ref self: TContractState, recipients: Span<ContractAddress>);
    fn pay_member(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn get_balance(self: @TContractState) -> u256;
    fn get_bonus_allocation(self: @TContractState) -> u256;
}
