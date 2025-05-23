#[starknet::component]
pub mod DisbursementComponent {
    use littlefinger::interfaces::idisbursement::IDisbursement;
    use littlefinger::structs::disbursement_structs::{
        Disbursement, DisbursementSchedule, DisbursementStatus, ScheduleStatus, ScheduleType,
    };
    use littlefinger::structs::member_structs::{Member};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::syscalls::get_execution_info_syscall;
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};

    #[storage]
    struct Storage {
        authorized_callers: Map<ContractAddress, bool>,
        disbursement_schedules: Map<felt252, Option<DisbursementSchedule>>,
        current_schedule: DisbursementSchedule,
        failed_disbursements: Map<
            felt252, Disbursement,
        > //map disbursement id to a failed disbursement
    }

    #[embeddable_as(DisbursementManager)]
    pub impl DisbursementImpl<
        TContractState, +HasComponent<TContractState>,
    > of IDisbursement<ComponentState<TContractState>> {
        fn create_disbursement_schedule(
            ref self: ComponentState<TContractState>,
            schedule_type: ScheduleType,
            schedule_id: felt252, // generate schedule_id yourself later
            start: u64, //timestamp
            end: u64,
            interval: u64,
        ) {
            // let caller = get_caller_address();
            // assert(self.authorized_callers.entry(caller).read(), 'Caller Not Permitted');
            self._assert_caller();
            assert(
                !self.disbursement_schedules.entry(schedule_id).read().is_some(),
                'ID already taken',
            );
            let disbursement_schedule = DisbursementSchedule {
                schedule_id,
                status: ScheduleStatus::ACTIVE,
                schedule_type,
                start_timestamp: start,
                end_timestamp: end,
                interval,
                last_execution: Option::None,
            };
            self
                .disbursement_schedules
                .entry(schedule_id)
                .write(Option::Some(disbursement_schedule));
        }

        fn pause_disbursement_schedule(
            ref self: ComponentState<TContractState>, schedule_id: felt252,
        ) {
            // let caller = get_caller_address();
            // assert(self.authorized_callers.entry(caller).read(), 'Caller Not Permitted');
            self._assert_caller();
            let disbursement_schedule_ref = self.disbursement_schedules.entry(schedule_id).read();
            assert(disbursement_schedule_ref.is_some(), 'Schedule Does Not Exist');
            let mut disbursement_schedule = disbursement_schedule_ref.unwrap();
            assert(
                disbursement_schedule.status == ScheduleStatus::ACTIVE,
                'Schedule Paused or Deleted',
            );
            disbursement_schedule.status = ScheduleStatus::PAUSED;
            self
                .disbursement_schedules
                .entry(schedule_id)
                .write(Option::Some(disbursement_schedule));
        }

        fn resume_schedule(ref self: ComponentState<TContractState>, schedule_id: felt252) {
            // let caller = get_caller_address();
            // assert(self.authorized_callers.entry(caller).read(), 'Caller Not Permitted');
            self._assert_caller();
            let disbursement_schedule_ref = self.disbursement_schedules.entry(schedule_id).read();
            assert(disbursement_schedule_ref.is_some(), 'Schedule Does Not Exist');
            let mut disbursement_schedule = disbursement_schedule_ref.unwrap();
            assert(
                disbursement_schedule.status == ScheduleStatus::PAUSED,
                'Schedule Active or Deleted',
            );
            disbursement_schedule.status = ScheduleStatus::ACTIVE;
            self
                .disbursement_schedules
                .entry(schedule_id)
                .write(Option::Some(disbursement_schedule));
        }

        fn delete_schedule(ref self: ComponentState<TContractState>, schedule_id: felt252) {
            // let caller = get_caller_address();
            // assert(self.authorized_callers.entry(caller).read(), 'Caller Not Permitted');
            self._assert_caller();
            let disbursement_schedule_ref = self.disbursement_schedules.entry(schedule_id).read();
            assert(disbursement_schedule_ref.is_some(), 'Schedule Does Not Exist');
            let mut disbursement_schedule = disbursement_schedule_ref.unwrap();
            assert(
                disbursement_schedule.status != ScheduleStatus::DELETED, 'Scedule Already Deleted',
            );
            disbursement_schedule.status = ScheduleStatus::DELETED;
            self
                .disbursement_schedules
                .entry(schedule_id)
                .write(Option::Some(disbursement_schedule));
        }

        fn get_current_schedule(self: @ComponentState<TContractState>) -> DisbursementSchedule {
            let disbursement_schedule = self.current_schedule.read();
            disbursement_schedule
        }

        fn compute_renumeration(
            ref self: ComponentState<TContractState>,
            member: Member,
            total_bonus_available: u256,
            total_members_weight: u16,
            total_funds_available: u256,
        ) -> u256 {
            let member_base_pay = member.base_pay;
            let bonus_proportion = member.role.into() / total_members_weight;
            let bonus_pay: u256 = bonus_proportion.into() * total_bonus_available;

            let renumeration = member_base_pay + bonus_pay;
            renumeration
        }

        // This function should be in the core organization contract
        // TODO:
        // To complete this function, get the vault dispatcher and dispatcher trait, then run
        // vault_dispatcher.pay_member on each member, when you loop through the members
        // as far as each member is active
        // of not, skip.
        fn disburse(
            ref self: ComponentState<TContractState>,
            recipients: Array<Member>,
            token: ContractAddress,
        ) {
            let exec_info = get_execution_info_syscall().unwrap();
            let now = exec_info.block_info.block_timestamp;

            let current_schedule = self.current_schedule.read();
            assert(current_schedule.status == ScheduleStatus::ACTIVE, 'Schedule Not Active');
            let interval = current_schedule.interval;

            if let Option::Some(mut last_cycle) = current_schedule.last_execution {
                assert(now >= last_cycle + interval, 'Too early to pay');
            } else {
                let start_time = current_schedule.start_timestamp;
                assert(now > start_time, 'Too early to pay');
            }
        }

        fn update_schedule_interval(
            ref self: ComponentState<TContractState>, schedule_id: felt252, new_interval: u64,
        ) {
            self._assert_caller();
            let disbursement_schedule_ref = self.disbursement_schedules.entry(schedule_id).read();
            assert(disbursement_schedule_ref.is_some(), 'Schedule does not exist');

            let mut disbursement_schedule = disbursement_schedule_ref.unwrap();
            assert(disbursement_schedule.status != ScheduleStatus::DELETED, 'Schedule Deleted');

            disbursement_schedule.interval = new_interval;

            self
                .disbursement_schedules
                .entry(schedule_id)
                .write(Option::Some(disbursement_schedule));
        }

        fn update_schedule_type(
            ref self: ComponentState<TContractState>,
            schedule_id: felt252,
            schedule_type: ScheduleType,
        ) {
            self._assert_caller();
            let disbursement_schedule_ref = self.disbursement_schedules.entry(schedule_id).read();
            assert(disbursement_schedule_ref.is_some(), 'Schedule does not exist');

            let mut disbursement_schedule = disbursement_schedule_ref.unwrap();
            assert(disbursement_schedule.status != ScheduleStatus::DELETED, 'Schedule Deleted');

            disbursement_schedule.schedule_type = schedule_type;

            self
                .disbursement_schedules
                .entry(schedule_id)
                .write(Option::Some(disbursement_schedule));
        }


        fn retry_failed_disbursement(
            ref self: ComponentState<TContractState>, schedule_id: felt252,
        ) {
            self._assert_caller();
        }

        fn get_pending_failed_disbursements(self: @ComponentState<TContractState>) {}

        fn get_last_disburse_time(self: @ComponentState<TContractState>) -> u64 {
            let mut last_disburse_time = 0;
            if let Option::Some(mut last_execution) = self.current_schedule.read().last_execution {
                last_disburse_time = last_execution
            }
            last_disburse_time
        }

        fn get_next_disburse_time(self: @ComponentState<TContractState>) -> u64 {
            let current_schedule = self.current_schedule.read();
            let now = get_block_timestamp();
            assert(now < current_schedule.end_timestamp, 'No more disbursement');
            let mut next_disburse_time = 0;
            if let Option::Some(mut last_execution) = self.current_schedule.read().last_execution {
                next_disburse_time = last_execution + current_schedule.interval;
            } else {
                next_disburse_time = current_schedule.start_timestamp;
            }

            next_disburse_time
        }
    }

    #[generate_trait]
    pub impl InternalImpl<
        TContractState, +HasComponent<TContractState>,
    > of InternalTrait<TContractState> {
        fn _add_authorized_caller(ref self: ComponentState<TContractState>, user: ContractAddress) {
            // let caller = get_caller_address();
            // assert(self.authorized_callers.entry(caller).read(), 'Caller Not Permitted');
            self._assert_caller();
            self.authorized_callers.entry(user).write(true);
        }

        fn _assert_caller(ref self: ComponentState<TContractState>) {
            let caller = get_caller_address();
            assert(self.authorized_callers.entry(caller).read(), 'Caller Not Permitted');
        }
    }
}
