use starknet::ContractAddress;

#[starknet::interface]
pub trait IFactory<T> {
    // fn deploy_vault(
    //     ref self: T,
    //     // class_hash: felt252, //unwrap it into class has using into, and it will be removed once I declare the vault
    //     available_funds: u256,
    //     starting_bonus_allocation: u256,
    //     token: ContractAddress,
    //     salt: felt252,
    // ) -> ContractAddress;
    // // Initialize organization
    // // Initialize member
    // // If custom owner is not supplied at deployment, deployer is used as owner, and becomes the first admin
    // fn deploy_org_core(
    //     ref self: T,
    //     // class_hash: felt252,
    //     // Needed to initialize the organization component
    //     owner: Option<ContractAddress>, 
    //     name: ByteArray, 
    //     ipfs_url: ByteArray, 
    //     vault_address: ContractAddress,
    //     // Needed to initialize the member component
    //     first_admin_fname: felt252,
    //     first_admin_lname: felt252,
    //     first_admin_alias: felt252,
    //     salt: felt252,
    // ) -> ContractAddress;
    fn setup_org(
        ref self: T,
        // class_hash: felt252, //unwrap it into class has using into, and it will be removed once I declare the vault
        available_funds: u256,
        starting_bonus_allocation: u256,
        token: ContractAddress,
        salt: felt252,
        // class_hash: felt252,
        // Needed to initialize the organization component
        owner: ContractAddress, 
        name: ByteArray, 
        ipfs_url: ByteArray, 
        // vault_address: ContractAddress,
        // Needed to initialize the member component
        first_admin_fname: felt252,
        first_admin_lname: felt252,
        first_admin_alias: felt252,
        // salt: felt252,
    ) -> (ContractAddress, ContractAddress);
    fn get_deployed_vaults(
        self: @T
    ) -> Array<ContractAddress>;
    fn get_deployed_org_cores(self: @T) -> Array<ContractAddress>;
    fn get_vault_org_pair(self: @T, caller: ContractAddress) -> (ContractAddress, ContractAddress);
    // fn get_vault_org_pairs(self: @T) -> Array<(ContractAddress, ContractAddress)>;
}