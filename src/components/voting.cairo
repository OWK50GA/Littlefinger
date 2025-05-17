#[starknet::component]
pub mod VotingComponent {
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address};
    use crate::interfaces::core::Config;
    use crate::structs::voting::{DEFAULT_THRESHOLD, Poll, PollStatus, PollTrait, Voted};
    use crate::interfaces::voting::IVote;
    use crate::structs::config::PollConfig;

    #[storage]
    pub struct Storage {
        pub polls: Map<u256, Poll>,
        pub voters: Map<(ContractAddress, u256), bool>,
        pub nonce: u256,
        pub config: PollConfig,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Voted: Voted,
    }

    #[embeddable_as(VotingImpl)]
    pub impl Voting<
        TContractState, +HasComponent<TContractState>,
    > of IVote<ComponentState<TContractState>> {
        fn create_poll(
            ref self: ComponentState<TContractState>, name: ByteArray, desc: ByteArray,
        ) -> u256 {
            let id = self.nonce.read() + 1;
            assert(name != "" && desc != "", 'NAME OR DESC IS EMPTY');
            let mut poll: Poll = Default::default();
            poll.name = name;
            poll.desc = desc;
            self.polls.entry(id).write(poll);
            self.nonce.write(id);
            id
        }

        fn vote(ref self: ComponentState<TContractState>, support: bool, id: u256) {
            let mut poll = self.polls.entry(id).read();
            assert(poll != Default::default(), 'INVALID POLL');
            assert(poll.status == Default::default(), 'POLL NOT PENDING');
            let caller = get_caller_address();
            let has_voted = self.voters.entry((caller, id)).read();
            assert(!has_voted, 'CALLER HAS VOTED');

            match support {
                true => poll.yes_votes += 1,
                _ => poll.no_votes += 1,
            }

            let vote_count = poll.yes_votes + poll.no_votes;

            if vote_count >= DEFAULT_THRESHOLD {
                poll.resolve();
                // emit a Poll Resolved Event
            }

            self.polls.entry(id).write(poll);
            self.voters.entry((caller, id)).write(true);
            self.emit(Voted { id, voter: caller });
        }

        fn get_poll(self: @ComponentState<TContractState>, id: u256) -> Poll {
            self.polls.entry(id).read()
        }

        fn end_poll(ref self: ComponentState<TContractState>, id: u256) {}
    }

    #[generate_trait]
    pub impl VoteInternalImpl<
        TContractState, +HasComponent<ComponentState<TContractState>>,
    > of VoteTrait<TContractState> {
        fn _initialize(
            ref self: ComponentState<TContractState>, admin: ContractAddress, config: Config,
        ) {}
    }
}
