#[starknet::contract]
pub mod Vault {
    use littlefinger::interfaces::ivault::IVault;
    use littlefinger::structs::vault_structs::{Transaction, TransactionType, VaultStatus};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{
        ContractAddress, get_block_timestamp, get_caller_address, get_contract_address, get_tx_info,
    };

    #[storage]
    struct Storage {
        permitted_addresses: Map<ContractAddress, bool>,
        available_funds: u256,
        total_bonus: u256,
        transaction_history: Map<
            u64, Transaction,
        >, // No 1. Transaction x, no 2, transaction y etc for history, and it begins with 1
        transactions_count: u64,
        vault_status: VaultStatus,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        DepositSuccessful: DepositSuccessful,
        WithdrawalSuccessful: WithdrawalSuccessful,
        VaultFrozen: VaultFrozen,
        VaultResumed: VaultResumed,
        TransactionRecorded: TransactionRecorded,
        // TODO:
        // Add an event here that gets emitted if the money goes below a certain threshold
        // Threshold Will be decided.
    }

    #[derive(Copy, Drop, starknet::Event)]
    pub struct DepositSuccessful {
        caller: ContractAddress,
        token: ContractAddress,
        amount: u256,
        timestamp: u64,
    }

    #[derive(Copy, Drop, starknet::Event)]
    pub struct WithdrawalSuccessful {
        caller: ContractAddress,
        token: ContractAddress,
        amount: u256,
        timestamp: u64,
    }

    #[derive(Copy, Drop, starknet::Event)]
    pub struct VaultFrozen {
        caller: ContractAddress,
        timestamp: u64,
    }

    #[derive(Copy, Drop, starknet::Event)]
    pub struct VaultResumed {
        caller: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TransactionRecorded {
        transaction_type: TransactionType,
        caller: ContractAddress,
        transaction_details: Transaction,
    }

    // TODO:
    // Add to this constructor, a way to add addresses and store them as permitted addresses here
    #[constructor]
    fn constructor(ref self: ContractState, available_funds: u256, bonus_allocation: u256) {
        self.available_funds.write(available_funds);
        self.total_bonus_available.write(bonus_allocation);
    }

    // TODO:
    // From the ivault, add functions in the interfaces for subtracting from and adding to bonus
    // IMPLEMENT HERE

    #[abi(embed_v0)]
    pub impl VaultImpl of IVault<ContractState> {
        fn deposit_funds(ref self: ContractState, token: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            assert(self.permitted_addresses.entry(caller).read(), 'Caller not permitted');
            let current_vault_status = self.vault_status.read();
            assert(
                current_vault_status != VaultStatus::VAULTFROZEN, 'Vault Frozen for Transactions',
            );
            let timestamp = get_block_timestamp();
            let this_contract = get_contract_address();
            let token_dispatcher = IERC20Dispatcher { contract_address: token };

            let transfer = token_dispatcher.transfer_from(caller, this_contract, amount);

            self._record_transaction(token, amount, TransactionType::DEPOSIT, caller);
            // Correct me if I'm wrong, but I think recording both failed and unfailed.

            assert(transfer, 'Transfer unsuccessful');

            let prev_available_funds = self.available_funds.read();
            self.available_funds.write(prev_available_funds + amount);
            self.available_funds.write(prev_available_funds + amount);
            self.emit(DepositSuccessful { caller, token, timestamp, amount })
        }

        fn withdraw_funds(ref self: ContractState, token: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            assert(self.permitted_addresses.entry(caller).read(), 'Caller Not Permitted');

            let current_vault_status = self.vault_status.read();
            assert(
                current_vault_status != VaultStatus::VAULTFROZEN, 'Vault Frozen for Transactions',
            );

            let timestamp = get_block_timestamp();
            assert(amount <= self.available_funds.read(), 'Insufficient Balance');
            // let this_contract = get_contract_address();
            let token_dispatcher = IERC20Dispatcher { contract_address: token };

            let transfer = token_dispatcher.transfer(caller, amount);
            self._record_transaction(token, amount, TransactionType::WITHDRAWAL, caller);
            assert(transfer, 'Withdrawal unsuccessful');

            let prev_available_funds = self.available_funds.read();
            self.available_funds.write(prev_available_funds - amount);

            self.emit(WithdrawalSuccessful { caller, token, amount, timestamp })
        }

        fn emergency_freeze(ref self: ContractState) {
            let caller = get_caller_address();
            assert(self.permitted_addresses.entry(caller).read(), 'Caller Not Permitted');
            assert(self.vault_status.read() != VaultStatus::VAULTFROZEN, 'Vault Already Frozen');

            self.vault_status.write(VaultStatus::VAULTRESUMED);
        }

        fn unfreeze_vault(ref self: ContractState) {
            let caller = get_caller_address();
            assert(self.permitted_addresses.entry(caller).read(), 'Caller Not Permitted');
            assert(self.vault_status.read() != VaultStatus::VAULTRESUMED, 'Vault Not Frozen');
        }
        // fn bulk_transfer(ref self: ContractState, recipients: Span<ContractAddress>) {}
        fn get_balance(self: @ContractState) -> u256 {
            let caller = get_caller_address();
            assert(self.permitted_addresses.entry(caller).read(), 'Caller Not Permitted');
            self.available_funds.read()
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalTrait {
        fn _add_transaction(ref self: ContractState, transaction: Transaction) {
            let caller = get_caller_address();
            assert(self.permitted_addresses.entry(caller).read(), 'Caller not permitted');
            let current_transaction_count = self.transactions_count.read();
            self.transaction_history.entry(current_transaction_count + 1).write(transaction);
            self.transactions_count.write(current_transaction_count + 1);
        }

        fn _record_transaction(
            ref self: ContractState,
            token_address: ContractAddress,
            amount: u256,
            transaction_type: TransactionType,
            caller: ContractAddress,
        ) {
            let caller = get_caller_address();
            assert(self.permitted_addresses.entry(caller).read(), 'Caller Not Permitted');
            let timestamp = get_block_timestamp();
            let tx_info = get_tx_info();
            let transaction = Transaction {
                transaction_type,
                token: token_address,
                amount,
                timestamp,
                tx_hash: tx_info.transaction_hash,
                caller,
            };
            self._add_transaction(transaction);
            self
                .emit(
                    TransactionRecorded {
                        transaction_type, caller, transaction_details: transaction,
                    },
                );
        }
    }
}
