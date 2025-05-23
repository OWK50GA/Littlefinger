use starknet::ContractAddress;
use starknet::storage::{Mutable, StoragePath};
use super::base::ContractAddressDefault;

#[derive(Copy, Drop, Serde, Default, PartialEq, starknet::Store)]
pub struct MemberResponse {
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

#[derive(Copy, Drop, Serde, Default, PartialEq, starknet::Store)]
pub struct MemberDetails {
    pub fname: felt252,
    pub lname: felt252,
    pub alias: felt252,
}

#[derive(Copy, Drop, Serde, Default, PartialEq, starknet::Store)]
pub struct Member {
    pub id: u256,
    pub address: ContractAddress,
    pub status: MemberStatus,
    pub role: MemberRole,
}

#[starknet::storage_node]
pub struct MemberNode {
    pub details: MemberDetails,
    pub member: Member,
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

// use a function called get_role_value()

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

    fn is_active(self: @Member) -> bool {
        *self.status == MemberStatus::ACTIVE
    }

    fn verify(self: @Member, caller: ContractAddress) {
        assert(self.is_active() && *self.address == caller, 'VERIFICATION FAILED');
    }

    fn is_admin(self: @Member) -> bool {
        if let MemberRole::ADMIN(_) = *self.role {
            return true;
        }
        return false;
    }

    fn with_details(
        id: u256,
        fname: felt252,
        lname: felt252,
        status: MemberStatus,
        role: MemberRole,
        alias: felt252,
        address: ContractAddress,
    ) -> (Member, MemberDetails) {
        let member = Member { id, address, status, role };
        let details = MemberDetails { fname, lname, alias };

        (member, details)
    }

    fn suspend(ref self: Member) {
        assert(
            self.status != MemberStatus::SUSPENDED
                && self.status != MemberStatus::UNVERIFIED
                && self.status != MemberStatus::REMOVED,
            'Invalid member selection',
        );
        self.status = MemberStatus::SUSPENDED;
    }

    fn reinstate(ref self: Member) {
        assert(self.status == MemberStatus::SUSPENDED, 'Invalid member selection');
        self.status = MemberStatus::ACTIVE;
    }

    fn to_response(self: @Member, storage: StoragePath<MemberNode>) -> MemberResponse {
        // Implement To Member Response
        Default::default()
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

#[derive(Drop, starknet::Event)]
pub struct MemberEvent {
    pub fname: felt252,
    pub lname: felt252,
    pub address: ContractAddress,
    pub status: MemberStatus,
    pub value: felt252,
    pub timestamp: u64,
}

#[derive(Drop, Serde, PartialEq, Default)]
pub struct MemberConfigInit {
    // assign weight for each role, else use the into.
    pub weight: Array<u16>, // currently there are three roles
    pub visibility: u8 // ranges from 0 to 2
}

#[starknet::storage_node]
pub struct MemberConfigNode {}

// #[drop, starknet::Event]
// pub struct MemberEvent {
//     pub fname: felt252,
//     pub lname: felt252,
//     pub address: felt252,
// }

#[derive(Drop, starknet::Event)]
pub enum MemberEnum {
    Invited: MemberEvent,
    Added: MemberEvent,
    Removed: MemberEvent,
    Suspended: MemberEvent,
}
