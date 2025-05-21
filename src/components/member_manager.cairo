#[starknet::component]
pub mod MemberManagerComponent {
    // use starknet::storage::StorageMapReadAccess;
    use core::num::traits::Zero;
    use littlefinger::interfaces::imember_manager::IMemberManager;
    use littlefinger::structs::member_structs::{
        Member, MemberEnum, MemberEvent, MemberRole, MemberStatus, MemberTrait,
    };
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};

    #[storage]
    pub struct Storage {
        pub admins: Map<u256, Member>, //Map <Member-id, Member>
        pub admin_count: u64,
        pub members: Map<u256, Member>, //map for all members
        pub member_count: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        MemberEvent: MemberEvent,
        MemberEnum: MemberEnum,
    }


    #[embeddable_as(MemberManager)]
    pub impl MemberManagerImpl<
        TContractState, +HasComponent<TContractState>,
    > of IMemberManager<ComponentState<TContractState>> {
        fn add_member(
            ref self: ComponentState<TContractState>,
            fname: felt252,
            lname: felt252,
            alias: felt252,
            role: MemberRole,
        ) {
            // In this implementation, we are imagining the person who wants to register is calling
            // the function with their wallet actually.
            // This means that we'll have to put verify_member to add to it
            // Will have to find another means to hash the id, or not. Let us see how things go
            let caller = get_caller_address();
            let id: u256 = (self.member_count.read() + 1).into();
            assert(!caller.is_zero(), 'Zero Address Caller');
            let reg_time = get_block_timestamp();
            let new_member = MemberTrait::new(id, fname, lname, role, alias, caller, reg_time);
            self.members.entry(id).write(new_member);
            self.member_count.write(self.member_count.read() + 1);
        }

        fn update_member_details(
            ref self: ComponentState<TContractState>,
            member_id: u256,
            fname: Option<felt252>,
            lname: Option<felt252>,
            alias: Option<felt252>,
        ) {
            let mut member = self.members.entry(member_id).read();
            assert(member != Default::default(), 'Member does not exist');
            assert(member.status == MemberStatus::ACTIVE, 'Member must be active');
            // check for now
            // in the future, an admin might override this check in the case a member loses
            // access to it's address, or you can use a catridge controller
            assert(member.address == get_caller_address(), 'Unauthorized.');
            let (mut member_fname, mut member_lname, mut member_alias) = (
                member.fname, member.lname, member.alias,
            );
            if fname.is_some() {
                member_fname = fname.unwrap()
            }
            if lname.is_some() {
                member_lname = lname.unwrap()
            }
            if alias.is_some() {
                member_alias = alias.unwrap()
            }

            member.fname = member_fname;
            member.lname = member_lname;
            member.alias = member_alias;

            self.members.entry(member_id).write(member);
        }

        fn suspend_member(
            ref self: ComponentState<TContractState>,
            member_id: u256 // suspension_duration: u64 //block timestamp operation
        ) {
            let mut member = self.members.entry(member_id).read();
            assert(
                member.status != MemberStatus::SUSPENDED
                    && member.status != MemberStatus::UNVERIFIED
                    && member.status != MemberStatus::REMOVED,
                'Invalid member selection',
            );
            member.status = MemberStatus::SUSPENDED;
            self.members.entry(member_id).write(member);
        }

        fn reinstate_member(ref self: ComponentState<TContractState>, member_id: u256) {
            let mut member = self.members.entry(member_id).read();
            assert(member.status == MemberStatus::SUSPENDED, 'Invalid member selection');
            member.status = MemberStatus::ACTIVE;
            self.members.entry(member_id).write(member);
        }

        fn get_members(self: @ComponentState<TContractState>) -> Span<Member> {
            let member_count: u256 = self.member_count.read().into();
            let mut members: Array<Member> = array![];
            for i in 1..member_count {
                let current_member = self.members.entry(i).read();
                members.append(current_member);
            }

            members.span()
        }

        fn invite_member(
            ref self: ComponentState<TContractState>,
            fname: felt252,
            lname: felt252,
            address: ContractAddress,
            renumeration: u256,
        ) -> felt252 {
            // The flow:
            // any admin can invite a member
            // the member can accept
            // For this protocol, the member must accept before other admins verify the member...
            // this can only happen when the member config requires multisig.
            let id: u256 = (self.member_count.read() + 1).into();
            let new_member = MemberTrait::new(id, fname, lname, Default::default(), '', address, 0);
            self.members.entry(id).write(new_member);
            let status: MemberStatus = Default::default();
            let timestamp = get_block_timestamp();
            let event = MemberEvent { fname, lname, address, status, value: '', timestamp };
            self.emit(MemberEnum::Invited(event));

            // stores and returns a hash, or zero if multisig is switched off.
            0
        }

        fn accept_invite(
            ref self: ComponentState<TContractState>, nonce: felt252, metadataURL: felt252,
        ) {}

        fn verify_member(
            ref self: ComponentState<TContractState>, address: ContractAddress,
        ) { // can be verified only if invitee has accepted, and config is checked.
        }
    }

    #[generate_trait]
    pub impl InternalImpl<
        TContractState, +HasComponent<TContractState>,
    > of InternalTrait<TContractState> {
        fn initializer(
            ref self: ComponentState<TContractState>,
            fname: felt252,
            lname: felt252,
            alias: felt252,
        ) {
            // This will be for making admins and giving people control/taking it away
            let caller = get_caller_address();
            let id: u256 = (self.member_count.read() + 1).into();
            assert(!caller.is_zero(), 'Zero Address Caller');

            let reg_time = get_block_timestamp();
            let role = MemberRole::ADMIN(0);
            let new_admin = MemberTrait::new(id, fname, lname, role, alias, caller, reg_time);
            self.members.entry(id).write(new_admin);
            let admin_count: u256 = self.admin_count.read().into();
            self.admins.entry(admin_count + 1).write(new_admin);
            self.member_count.write(self.member_count.read() + 1);
        }
    }
}
