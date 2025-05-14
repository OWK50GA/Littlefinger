use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, PartialEq, starknet::Store)]
pub struct Member {
    pub fname: felt252,
    pub lname: felt252,
    pub alias: felt252,
    pub role: MemberRole,
    pub id: u256,
    pub address: ContractAddress,
    pub status: MemberStatus,
    // pub allocation_weight: u256, -> This will be contained in the struct for each of the member roles, that is what we will do
    pub pending_allocations: Option<u256>,
    pub total_received: Option<u256>,
    pub last_disbursement_timestamp: Option<u64>,
    pub total_disbursements: Option<u64>,
    pub reg_time: u64,
}

#[derive(Copy, Drop, Serde, PartialEq, Debug, starknet::Store)]
pub enum MemberRole {
    // These variants of the member role enum will not just be variants very soon, each of them will have their own
    // structs, and your role in the company will mean much in your weight for governance, and your disbursement powers
    #[default]
    EMPLOYEE,
    ADMIN,
    CONTRACTOR
}

#[derive(Copy, Drop, Serde, PartialEq, Debug, starknet::Store)]
pub enum MemberStatus {
    #[default]
    UNVERIFIED,
    ACTIVE,
    SUSPENDED,
    PROBATION,
    REMOVED
}