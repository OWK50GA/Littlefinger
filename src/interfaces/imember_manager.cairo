use salzstark::structs::member_structs::{MemberRole, Member};
// use starknet::ContractAddress;

#[starknet::interface]
pub trait IManageMembers<TContractState> {
    fn add_member(
        ref self: TContractState, 
        fname: felt252, lname: felt252, 
        alias: felt252, role: MemberRole, 
        // weight: u256
    );
    fn update_member_details(
        ref self: TContractState,
        member_id: u256,
        fname: Option<felt252>, lname: Option<felt252>, 
        alias: Option<felt252>
    );
    fn suspend_member(
        ref self: TContractState,
        member_id: u256,
        // suspension_duration: u64 //block timestamp operation
    );
    fn reinstate_member(
        ref self: TContractState, member_id: u256
    );
    fn get_members(self: @TContractState) -> Span<Member>;

    // ROLE MANAGEMENT



    // ALLOCATION WEIGHT MANAGEMENT (PROMOTION & DELETION)


}