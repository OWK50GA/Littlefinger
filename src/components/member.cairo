#[starknet::component]
pub mod MemberManagerComponent {
    use core::num::traits::Zero;
    use salzstark::interfaces::member::IMemberManager;
    use salzstark::structs::member::{Member, MemberRole, MemberStatus};
    use starknet::storage::{
        Map, StorageMapReadAccess, StoragePathEntry, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};

    #[storage]
    pub struct Storage {
        admins: Map<u256, Member>, //Map <Member-id, Member>
        admin_count: u64,
        members: Map<u256, Member>, //map for all members
        member_count: u256,
    }

    #[embeddable_as(MemberManagerImpl)]
    pub impl MemberManager<
        TContractState, +HasComponent<TContractState>,
    > of IMemberManager<ComponentState<TContractState>> {
        fn register(
            ref self: ComponentState<TContractState>,
            fname: felt252,
            lname: felt252,
            alias: felt252,
            role: MemberRole,
        ) -> u256 {
            // In this implementation, we are imagining the person who wants to register is calling
            // the function with their wallet actually.
            // This means that we'll have to put verify_member to add to it
            // We'll have to find another means to hash the id, or not. Let us see how things go
            let caller = get_caller_address();
            let id: u256 = self.member_count.read() + 1;
            assert(!caller.is_zero(), 'Zero Address Caller');
            let reg_time = get_block_timestamp();
            let new_member = Member {
                fname,
                lname,
                alias,
                role,
                id,
                address: caller,
                status: MemberStatus::UNVERIFIED,
                pending_allocations: Option::None,
                total_received: Option::None,
                last_disbursement_timestamp: Option::None,
                total_disbursements: Option::None,
                reg_time,
            };
            self.members.entry(id).write(new_member);
            self.member_count.write(id);
            id
        }

        fn update_member_details(
            ref self: ComponentState<TContractState>,
            member_id: u256,
            fname: Option<felt252>,
            lname: Option<felt252>,
            alias: Option<felt252>,
        ) {
            let mut member = self.members.entry(member_id).read();
            assert(member.status == MemberStatus::ACTIVE, 'Member must be active');
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
                let current_member = self.members.read(i);
                members.append(current_member);
            }

            members.span()
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
            let new_admin = Member {
                fname,
                lname,
                alias,
                role: MemberRole::ADMIN,
                id,
                address: caller,
                status: MemberStatus::UNVERIFIED,
                pending_allocations: Option::None,
                total_received: Option::None,
                last_disbursement_timestamp: Option::None,
                total_disbursements: Option::None,
                reg_time,
            };
            self.members.entry(id).write(new_admin);
            let admin_count: u256 = self.admin_count.read().into();
            self.admins.entry(admin_count + 1).write(new_admin);
            self.member_count.write(self.member_count.read() + 1);
        }
    }
}
