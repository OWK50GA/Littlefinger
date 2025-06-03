use littlefinger::interfaces::ifactory::{IFactoryDispatcher, IFactoryDispatcherTrait};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address, stop_cheat_caller_address};
use starknet::ContractAddress;

fn owner() -> ContractAddress {
    1.try_into().unwrap()
}

fn setup() -> ContractAddress {
    let declare_result = declare("Factory");
    let core_class_hash = declare("Core").unwrap().contract_class().class_hash;
    let vault_class_hash = declare("Vault").unwrap().contract_class().class_hash;

    assert(declare_result.is_ok(), 'factory declaration failed');

    let contract_class = declare_result.unwrap().contract_class();

    let mut calldata: Array<felt252> = array![owner().into()];

    core_class_hash.serialize(ref calldata);
    vault_class_hash.serialize(ref calldata);

    let deploy_result = contract_class.deploy(@calldata);

    assert(deploy_result.is_ok(), 'contract deployment failed');

    let (contract_address, _) = deploy_result.unwrap();
    contract_address
}

#[test]
fn test_setup_org() {
    let contract_address = setup();

    let dispatcher = IFactoryDispatcher { contract_address };

    let (org_address, vault_address) = dispatcher.setup_org(
        available_funds: 1000000000000000000,
        starting_bonus_allocation: 1000000000000000000,
        token: 0.try_into().unwrap(),
        salt: 'test_salt',
        owner: owner(),
        name: "test_name",
        ipfs_url: "test_ipfs_url",
        first_admin_fname: 'test_fname',
        first_admin_lname: 'test_lname',
        first_admin_alias: 'test_alias',
    );

    let (org_address_, vault_address_) = dispatcher.get_vault_org_pair(owner());

    assert(org_address_ == org_address, 'address is not org_address');
    assert(vault_address_ == vault_address, 'address is not vault_address');

    assert(org_address != 0.try_into().unwrap(), 'org deployment failed');
    assert(vault_address != 0.try_into().unwrap(), 'vault deployment failed');

    assert(dispatcher.get_deployed_vaults().len() == 1, 'vaults length is not 1');
    assert(dispatcher.get_deployed_org_cores().len() == 1, 'orgs length is not 1');
}

#[test]
fn test_get_deployed_vaults() {
    let contract_address = setup();

    let dispatcher = IFactoryDispatcher { contract_address };

    let (_, _) = dispatcher.setup_org(
        available_funds: 1000000000000000000,
        starting_bonus_allocation: 1000000000000000000,
        token: 0.try_into().unwrap(),
        salt: 'test_salt',
        owner: owner(),
        name: "test_name",
        ipfs_url: "test_ipfs_url",
        first_admin_fname: 'test_fname',
        first_admin_lname: 'test_lname',
        first_admin_alias: 'test_alias',
    );

    assert(dispatcher.get_deployed_vaults().len() == 1, 'vaults length is not 1');
}


#[test]
fn test_get_deployed_orgs() {
    let contract_address = setup();

    let dispatcher = IFactoryDispatcher { contract_address };

    let (_, _) = dispatcher.setup_org(
        available_funds: 1000000000000000000,
        starting_bonus_allocation: 1000000000000000000,
        token: 0.try_into().unwrap(),
        salt: 'test_salt',
        owner: owner(),
        name: "test_name",
        ipfs_url: "test_ipfs_url",
        first_admin_fname: 'test_fname',
        first_admin_lname: 'test_lname',
        first_admin_alias: 'test_alias',
    );

    assert(dispatcher.get_deployed_org_cores().len() == 1, 'orgs length is not 1');
}

#[test]
fn test_update_vault_hash() {
    let contract_address = setup();
    let new_vault_class_hash = '0x01'.try_into().unwrap();

    let dispatcher = IFactoryDispatcher { contract_address };

    let (_, _) = dispatcher.setup_org(
        available_funds: 1000000000000000000,
        starting_bonus_allocation: 1000000000000000000,
        token: 0.try_into().unwrap(),
        salt: 'test_salt',
        owner: owner(),
        name: "test_name",
        ipfs_url: "test_ipfs_url",
        first_admin_fname: 'test_fname',
        first_admin_lname: 'test_lname',
        first_admin_alias: 'test_alias',
    );

    start_cheat_caller_address(contract_address, owner());

    dispatcher.update_vault_hash(new_vault_class_hash);

    stop_cheat_caller_address(contract_address);

    assert(dispatcher.get_vault_class_hash() == new_vault_class_hash, 'class_hash is not equal');
}

#[test]
fn test_update_org_core_hash() {
    let contract_address = setup();
    let new_org_core_class_hash = '0x01'.try_into().unwrap();

    let dispatcher = IFactoryDispatcher { contract_address };

    let (_, _) = dispatcher.setup_org(
        available_funds: 1000000000000000000,
        starting_bonus_allocation: 1000000000000000000,
        token: 0.try_into().unwrap(),
        salt: 'test_salt',
        owner: owner(),
        name: "test_name",
        ipfs_url: "test_ipfs_url",
        first_admin_fname: 'test_fname',
        first_admin_lname: 'test_lname',
        first_admin_alias: 'test_alias',
    );

    start_cheat_caller_address(contract_address, owner());

    dispatcher.update_core_hash(new_org_core_class_hash);

    stop_cheat_caller_address(contract_address);

    assert(dispatcher.get_org_core_class_hash() == new_org_core_class_hash, 'class_hash is not equal');
}