#[starknet::component]
pub mod MemberManagerComponent {
    use core::num::traits::Zero;
    use littlefinger::interfaces::icore::IConfig;
    use littlefinger::interfaces::imember_manager::IMemberManager;
    use littlefinger::structs::member_structs::{
        MemberEnum, MemberEvent, MemberNode, MemberResponse, MemberRole, MemberStatus, MemberTrait,
    };
    use littlefinger::structs::core::Config;
    use starknet::storage::{
        Map, MutableVecTrait, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
        Vec, VecTrait
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};

    #[storage]
    pub struct Storage {
        pub admin_count: u64,
        pub admin_ca: Map<ContractAddress, bool>,
        pub members: Map<u256, MemberNode>,
        pub member_count: u256,
        pub role_value: Vec<u16>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
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
            let id: u256 = self.member_count.read() + 1;
            assert(!caller.is_zero(), 'Zero Address Caller');
            let reg_time = get_block_timestamp();
            let status: MemberStatus = Default::default();
            let member = self.members.entry(id);

            let (new_member, details) = MemberTrait::with_details(
                id, fname, lname, status, role, alias, caller,
            );
            member.details.write(details);
            member.member.write(new_member);
            member.reg_time.write(reg_time);
            self.member_count.write(id);
        }

        fn update_member_details(
            ref self: ComponentState<TContractState>,
            member_id: u256,
            fname: Option<felt252>,
            lname: Option<felt252>,
            alias: Option<felt252>,
        ) {
            let m = self.members.entry(member_id);
            let member = m.member.read();
            assert(member != Default::default(), 'Member does not exist');
            // check for now
            // in the future, an admin might override this check in the case a member loses
            // access to it's address, or you can use a catridge controller
            member.verify(get_caller_address());
            let mut details = m.details.read();

            if let Option::Some(val) = fname {
                details.fname = val;
            }
            if let Option::Some(val) = lname {
                details.lname = val;
            }
            if let Option::Some(val) = alias {
                details.alias = val;
            }

            m.details.write(details);
        }

        fn suspend_member(
            ref self: ComponentState<TContractState>,
            member_id: u256 // suspension_duration: u64 //block timestamp operation
        ) {
            let m = self.members.entry(member_id);
            let mut member = m.member.read();
            member.suspend();
            m.member.write(member);
        }

        fn reinstate_member(ref self: ComponentState<TContractState>, member_id: u256) {
            let mut member = self.members.entry(member_id).member.read();
            member.reinstate();
            self.members.entry(member_id).member.write(member);
        }

        fn get_members(self: @ComponentState<TContractState>) -> Span<MemberResponse> {
            let member_count: u256 = self.member_count.read().into();
            let mut members: Array<MemberResponse> = array![];
            for i in 1..member_count + 1 {
                let m = self.members.entry(i);
                let current_member = m.member.read();
                members.append(current_member.to_response(m));
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
            let caller = get_caller_address();
            assert(self.admin_ca.entry(caller).read(), 'UNAUTHORIZED CALLER');

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
        // at some scenario, the config is checked, and this fuction just returns
        // if config.<param> != that, return;

        }
    }

    // this might init the public key, where necessary
    #[generate_trait]
    pub impl InternalImpl<TContractState, +HasComponent<ComponentState<TContractState>>,
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
            self.admin_ca.entry(caller).write(true);
            let admin_count: u256 = self.admin_count.read().into();
            self.admins.entry(admin_count + 1).write(new_admin);
            self.member_count.write(self.member_count.read() + 1);
        }

        fn get_role_value(self: @ComponentState<TContractState>, member_id: u256) -> u16 {
            // read member node
            let role = self.members.entry(member_id).member.read().role;
            assert(role != Default::default(), 'INVALID MEMBER ID');
            match role {
                MemberRole::CONTRACTOR(val) => val * self.role_value.at(0).read(),
                MemberRole::EMPLOYEE(val) => val * self.role_value.at(1).read(),
                MemberRole::ADMIN(val) => val * self.role_value.at(2).read(),
                _ => 0,
            }
        }

        fn assert_admin(self: @ComponentState<TContractState>) {
            let caller = get_caller_address();
            assert(self.admin_ca.entry(caller).read(), 'UNAUTHORIZED');
        }
    }

    #[abi(embed_v0)]
    pub impl MemberConfigImpl<
        TContractState, +HasComponent<TContractState>,
    > of IConfig<ComponentState<TContractState>> {
        fn update_config(ref self: ComponentState<TContractState>, config: Config) {
            if let Config::Member(_) = config {

            }
        }
    }
}
