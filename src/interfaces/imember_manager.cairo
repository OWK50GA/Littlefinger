use littlefinger::structs::member_structs::{Member, MemberRole};
use starknet::ContractAddress;

#[starknet::interface]
pub trait IMemberManager<TContractState> {
    fn add_member(
        ref self: TContractState, fname: felt252, lname: felt252, alias: felt252, role: MemberRole,
        // weight: u256
    ); //-> u256;
    fn invite_member(
        ref self: TContractState,
        fname: felt252,
        lname: felt252,
        address: ContractAddress,
        renumeration: u256,
    );
    fn accept_invite(ref self: TContractState, nonce: felt252, metadataURL: felt252);
    fn verify_member(ref self: TContractState, address: ContractAddress);
    fn update_member_details(
        ref self: TContractState,
        member_id: u256,
        fname: Option<felt252>,
        lname: Option<felt252>,
        alias: Option<felt252>,
    );
    fn suspend_member(
        ref self: TContractState,
        member_id: u256 // suspension_duration: u64 //block timestamp operation
    );
    fn reinstate_member(ref self: TContractState, member_id: u256);
    fn get_members(self: @TContractState) -> Span<Member>;
    // ROLE MANAGEMENT

    // ALLOCATION WEIGHT MANAGEMENT (PROMOTION & DELETION)

}
