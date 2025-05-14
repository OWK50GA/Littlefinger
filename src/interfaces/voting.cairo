use core::num::traits::Zero;
use starknet::ContractAddress;

#[starknet::interface]
pub trait IVote<TContractState> {
    fn create_poll(ref self: TContractState, name: ByteArray, desc: ByteArray) -> u256;
    fn vote(ref self: TContractState, support: bool, id: u256);
    fn get_poll(self: @TContractState, id: u256) -> Poll;
    fn end_poll(ref self: TContractState, id: u256);
}

#[derive(Drop, Clone, Serde, PartialEq, Default, starknet::Store)]
pub struct Poll {
    pub owner: ContractAddress,
    pub name: ByteArray,
    pub desc: ByteArray,
    pub yes_votes: u256,
    pub no_votes: u256,
    pub status: PollStatus,
}

pub impl ContractAddressDefault of Default<ContractAddress> {
    #[inline(always)]
    fn default() -> ContractAddress {
        Zero::zero()
    }
}

#[generate_trait]
pub impl PollImpl of PollTrait {
    fn resolve(ref self: Poll) {
        assert(self.yes_votes + self.no_votes >= DEFAULT_THRESHOLD, 'COULD NOT RESOLVE');
        let mut status = false;
        if self.yes_votes > self.no_votes {
            status = true;
        }
        self.status = PollStatus::Finished(status);
    }

    fn stop(ref self: Poll) {
        self.status = PollStatus::Finished(false);
    }
}

#[derive(Drop, Copy, Default, Serde, PartialEq, starknet::Store)]
pub enum PollStatus {
    #[default]
    Pending,
    Started,
    Finished: bool,
}

#[derive(Drop, starknet::Event)]
pub struct Voted {
    #[key]
    pub id: u256,
    #[key]
    pub voter: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct PollResolved {
    #[key]
    pub id: u256,
    pub outcome: bool,
}

pub const DEFAULT_THRESHOLD: u256 = 10;
pub type Power = u16;
