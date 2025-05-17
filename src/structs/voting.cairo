use core::num::traits::Zero;
use starknet::ContractAddress;
use super::base::ContractAddressDefault;

#[derive(Drop, Clone, Serde, PartialEq, Default, starknet::Store)]
pub struct Poll {
    pub owner: ContractAddress,
    pub name: ByteArray,
    pub desc: ByteArray,
    pub yes_votes: u256,
    pub no_votes: u256,
    pub status: PollStatus,
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
