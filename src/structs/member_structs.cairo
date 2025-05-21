use starknet::ContractAddress;
use super::base::ContractAddressDefault;

#[derive(Copy, Drop, Serde, Default, PartialEq, starknet::Store)]
pub struct Member {
    pub fname: felt252,
    pub lname: felt252,
    pub alias: felt252,
    pub role: MemberRole,
    pub id: u256,
    pub address: ContractAddress,
    pub status: MemberStatus,
    // pub allocation_weight: u256, -> This will be contained in the struct for each of the member
    // roles, that is what we will do
    // The base pay is agreed between the member and the company at the beginning of their work
    // together i.e. during registration
    pub base_pay: u256,
    pub pending_allocations: Option<u256>,
    pub total_received: Option<u256>,
    pub no_of_payouts: u32,
    pub last_disbursement_timestamp: Option<u64>,
    pub total_disbursements: Option<u64>,
    pub reg_time: u64,
}

#[derive(Copy, Drop, Serde, PartialEq, Default, starknet::Store)]
pub enum MemberRole {
    // These variants of the member role enum will not just be variants very soon, each of them will
    // have their own structs, and your role in the company will mean much in your weight for
    // governance, and your disbursement powers
    #[default]
    None,
    EMPLOYEE: u16,
    ADMIN: u16,
    CONTRACTOR: u16,
}

// subject to change, but hard coded for now
// may be subject to customization
const CONTRACTOR: u16 = 1;
const EMPLOYEE: u16 = 3;
const ADMIN: u16 = 20;


/// For voting purposes, a trait to convert Role to Voting Power
pub impl MemberRoleIntoU16 of Into<MemberRole, u16> {
    #[inline(always)]
    fn into(self: MemberRole) -> u16 {
        match self {
            MemberRole::EMPLOYEE(val) => EMPLOYEE * val,
            MemberRole::ADMIN(val) => ADMIN * val,
            MemberRole::CONTRACTOR(val) => CONTRACTOR * val,
            _ => 0,
        }
    }
}

#[generate_trait]
pub impl MemberImpl of MemberTrait {
    fn is_member(self: @Member) -> bool {
        *self.status == MemberStatus::ACTIVE
            || *self.status == MemberStatus::SUSPENDED
            || *self.status == MemberStatus::PROBATION
    }

    fn is_verified(self: @Member) -> bool {
        true
    }

    fn new(
        id: u256,
        fname: felt252,
        lname: felt252,
        role: MemberRole,
        alias: felt252,
        caller: ContractAddress,
        reg_time: u64,
    ) -> Member {
        let mut member: Member = Default::default();
        // checks, if necessary
        member.fname = fname;
        member.lname = lname;
        member.role = role;
        member.alias = alias;
        member.address = caller;
        member.reg_time = reg_time;
        member
    }
}


#[derive(Copy, Drop, Serde, Default, PartialEq, starknet::Store)]
pub enum MemberStatus {
    #[default]
    UNVERIFIED,
    ACTIVE,
    SUSPENDED,
    PROBATION,
    REMOVED,
}
