// use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, PartialEq, Debug, starknet::Store)]
pub struct DisbursementSchedule {
    schedule_id: felt252,
    is_active: bool,
    schedule_type: ScheduleType,
    start_timestamp: u64,
    end_timestamp: u64,
    interval: u64,
    last_execution: u64,
}

#[derive(Copy, Drop, Serde, PartialEq, Debug, starknet::Store)]
pub enum ScheduleType {
    RECURRING,
    #[default]
    ONETIME,
    CONDITIONAL,
}

