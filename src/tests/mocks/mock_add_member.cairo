use littlefinger::structs::member_structs::{MemberRole, MemberResponse};
use starknet::ContractAddress;

#[starknet::interface]
pub trait IMockAddMember<TContractState> {
    fn add_member_pub(
        ref self: TContractState, fname: felt252, lname: felt252, alias: felt252, role: MemberRole,
    );
    fn get_member_pub(self: @TContractState, member_id: u256) -> MemberResponse;
}

#[starknet::contract]
pub mod MockAddMember {
    use littlefinger::components::member_manager::MemberManagerComponent;
    use littlefinger::structs::member_structs::{MemberRole, MemberResponse};

    component!(path: MemberManagerComponent, storage: member_add, event: MemberAddEvent);

    #[abi(embed_v0)]
    pub impl MemberAddImpl = MemberManagerComponent::MemberManager<ContractState>;

    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        pub member_add: MemberManagerComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        MemberAddEvent: MemberManagerComponent::Event,
    }

    #[abi(embed_v0)]
    pub impl MockAddMemberImpl of super::IMockAddMember<ContractState> {
        fn add_member_pub(
            ref self: ContractState,
            fname: felt252,
            lname: felt252,
            alias: felt252,
            role: MemberRole,
        ) {
            self.member_add.add_member(fname, lname, alias, role);
        }

        fn get_member_pub(self: @ContractState, member_id: u256) -> MemberResponse{
            self.member_add.get_member(member_id)
        }
    }
}
