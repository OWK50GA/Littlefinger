use littlefinger::interfaces::imember_manager::IMemberManager as IMockMemberManager;
use littlefinger::structs::member_structs::{
    InviteStatus, Member, MemberConfig, MemberConfigNode, MemberDetails, MemberEnum, MemberEvent,
    MemberInvite, MemberInvited, MemberNode, MemberResponse, MemberRole, MemberStatus, MemberTrait,
};
use starknet::ContractAddress;

#[starknet::contract]
pub mod MockMemberManager {
    use littlefinger::components::member_manager::MemberManagerComponent;
    use littlefinger::structs::member_structs::{MemberConfig, MemberResponse, MemberRole};
    use starknet::ContractAddress;
    use starknet::storage::{
        Map, MutableVecTrait, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
        Vec, VecTrait,
    };

    component!(path: MemberManagerComponent, storage: member_manager, event: MemberManagerEvent);

    #[abi(embed_v0)]
    pub impl MemberManagerImpl =
        MemberManagerComponent::MemberManager<ContractState>;

    pub impl InternalImpl = MemberManagerComponent::InternalImpl<ContractState>;

    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        pub member_manager: MemberManagerComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        MemberManagerEvent: MemberManagerComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        first_admin_fname: felt252,
        first_admin_lname: felt252,
        first_admin_alias: felt252,
        admin: ContractAddress,
    ) {
        self
            .member_manager
            ._initialize(first_admin_fname, first_admin_lname, first_admin_alias, admin);

        // Initialize role values if needed
        self.member_manager.role_value.append().write(1);
        self.member_manager.role_value.append().write(2);
        self.member_manager.role_value.append().write(3);
    }

    pub impl MockMemberManagerImpl of super::IMockMemberManager<ContractState> {
        fn add_member(
            ref self: ContractState,
            fname: felt252,
            lname: felt252,
            alias: felt252,
            role: MemberRole,
            address: ContractAddress,
        ) {
            self.member_manager.add_member(fname, lname, alias, role, address);
        }

        fn add_admin(ref self: ContractState, member_id: u256) {
            self.member_manager.add_admin(member_id);
        }

        fn update_member_details(
            ref self: ContractState,
            member_id: u256,
            fname: Option<felt252>,
            lname: Option<felt252>,
            alias: Option<felt252>,
        ) {
            self.member_manager.update_member_details(member_id, fname, lname, alias);
        }

        fn get_member(self: @ContractState, member_id: u256) -> MemberResponse {
            self.member_manager.get_member(member_id)
        }

        fn get_members(self: @ContractState) -> Span<MemberResponse> {
            self.member_manager.get_members()
        }

        fn update_member_base_pay(ref self: ContractState, member_id: u256, base_pay: u256) {
            self.member_manager.update_member_base_pay(member_id, base_pay);
        }

        fn get_member_base_pay(ref self: ContractState, member_id: u256) -> u256 {
            self.member_manager.get_member_base_pay(member_id)
        }

        fn suspend_member(ref self: ContractState, member_id: u256) {
            self.member_manager.suspend_member(member_id);
        }

        fn reinstate_member(ref self: ContractState, member_id: u256) {
            self.member_manager.reinstate_member(member_id);
        }

        fn invite_member(
            ref self: ContractState, role: u16, address: ContractAddress, renumeration: u256,
        ) -> felt252 {
            self.member_manager.invite_member(role, address, renumeration)
        }

        fn accept_invite(ref self: ContractState, fname: felt252, lname: felt252, alias: felt252) {
            self.member_manager.accept_invite(fname, lname, alias);
        }

        fn record_member_payment(
            ref self: ContractState, member_id: u256, amount: u256, timestamp: u64,
        ) {
            self.member_manager.record_member_payment(member_id, amount, timestamp);
        }

        fn update_member_config(ref self: ContractState, config: MemberConfig) {
            self.member_manager.update_member_config(config);
        }
    }
}
