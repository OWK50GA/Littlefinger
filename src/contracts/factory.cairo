#[starknet::contract]
pub mod Factory {
    use starknet::{
        ContractAddress, get_caller_address, syscalls::deploy_syscall, class_hash::ClassHash, SyscallResultTrait,
        get_block_timestamp
    };
    use starknet::storage::{Map, StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry};
    use littlefinger::interfaces::ifactory::IFactory;
    // use littlefinger::structs::organization::{OrganizationInfo};

    #[storage]
    pub struct Storage {
        deployed_orgs: Map::<u256, ContractAddress>, //org_id should be the same with vault_id
        deployed_vaults: Map::<u256, ContractAddress>,
        orgs_count: u64,
        vaults_count: u64, //Open to the possibility of an organization somehow having more than one vault
        vault_class_hash: ClassHash,
        org_core_class_hash: ClassHash,
    }

    #[constructor]
    fn constructor(ref self: ContractState, vault_class_hash: ClassHash, org_core_class_hash: ClassHash) {
        self.orgs_count.write(0);
        self.vaults_count.write(0);
        self.vault_class_hash.write(vault_class_hash);
        self.org_core_class_hash.write(org_core_class_hash);
    }

    pub impl FactoryImpl of IFactory<ContractState> {
        fn deploy_vault(
            ref self: ContractState,
            // class_hash: felt252, //unwrap it into class has using into, and it will be removed once I declare the vault
            available_funds: u256,
            starting_bonus_allocation: u256,
            token: ContractAddress,
            salt: felt252,
        ) -> ContractAddress {
            let vault_count = self.vaults_count.read();
            let vault_id: u256 = vault_count.try_into().unwrap();
            let mut constructor_calldata = array![];
            token.serialize(ref constructor_calldata);
            available_funds.serialize(ref constructor_calldata);
            starting_bonus_allocation.serialize(ref constructor_calldata);

            // Deploy the Vault
            let processed_class_hash: ClassHash = self.vault_class_hash.read();
            let result = deploy_syscall(
                processed_class_hash, salt, constructor_calldata.span(), false //Have to recheck if this is the right value, and why
            );
            let (vault_address, _) = result.unwrap_syscall();

            // Update state of storage
            self.vaults_count.write(self.vaults_count.read() + 1);
            self.deployed_vaults.entry(vault_id).write(vault_address);
            
            vault_address
        }

        // Initialize organization
        // Initialize member
        // If custom owner is not supplied at deployment, deployer is used as owner, and becomes the first admin
        fn deploy_org_core(
            ref self: ContractState,
            // class_hash: felt252,
            // Needed to initialize the organization component
            owner: Option<ContractAddress>, 
            name: ByteArray, 
            ipfs_url: ByteArray, 
            vault_address: ContractAddress,
            // Needed to initialize the member component
            first_admin_fname: felt252,
            first_admin_lname: felt252,
            first_admin_alias: felt252,
            salt: felt252,
        ) -> ContractAddress {
            let deployer = get_caller_address();
            let org_count = self.orgs_count.read();
            let org_id: u256 = org_count.try_into().unwrap();
            let mut viable_owner = deployer;
            if owner.is_some() {
                viable_owner = owner.unwrap()
            }
            let current_time = get_block_timestamp();
            // let organization_info = OrganizationInfo {
            //     org_id,
            // let felt_org_id: felt252 = org_id.into();
            // let felt_name: felt252 = name.into();
            //     name,
            //     deployer,
            //     owner: viable_owner,
            //     ipfs_url,
            //     vault_address,
            //     created_at: current_time
            // };
            let mut constructor_calldata = array![];
            org_id.serialize(ref constructor_calldata);
            name.serialize(ref constructor_calldata);
            owner.serialize(ref constructor_calldata);
            vault_address.serialize(ref constructor_calldata);
            first_admin_fname.serialize(ref constructor_calldata);
            first_admin_lname.serialize(ref constructor_calldata);
            first_admin_alias.serialize(ref constructor_calldata);
            deployer.serialize(ref constructor_calldata);

            let processed_class_hash: ClassHash = self.org_core_class_hash.read();

            // Deploy contract
            let (org_address, _) = deploy_syscall(
                processed_class_hash, salt, constructor_calldata.span(), false
            ).unwrap_syscall();

            self.deployed_orgs.entry(org_id).write(org_address);

            org_address
        }
        fn setup_org(ref self: ContractState) {
            let deployer = get_caller_address();

        }
        fn get_deployed_vaults(
            self: @ContractState
        ) -> Array<ContractAddress> {
            let mut vaults = array![];
            let vaults_count: u256 = (self.vaults_count.read()).try_into().unwrap();

            for i in 1..vaults_count {
                let current_vault = self.deployed_vaults.entry(i).read();
                vaults.append(current_vault);
            }
            vaults
        }
        fn get_deployed_org_cores(self: @ContractState) -> Array<ContractAddress> {
            let mut orgs = array![];
            let orgs_count: u256 = (self.orgs_count.read()).try_into().unwrap();

            for i in 1..orgs_count {
                let current_org_core = self.deployed_orgs.entry(i).read();
                orgs.append(current_org_core);
            }
            orgs
        }
        // fn get_vault_org_pairs(self: @ContractState) -> Array<(ContractAddress, ContractAddress)> {

        // }
    }
}