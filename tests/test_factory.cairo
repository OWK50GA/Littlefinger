use littlefinger::interfaces::ifactory::{IFactoryDispatcher, IFactoryDispatcherTrait};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::ContractAddress;

fn owner() -> ContractAddress {
    1.try_into().unwrap()
}

fn setup() -> ContractAddress {
    let declare_result = declare("Factory");
    let declare_org = declare("0x0");
    let declare_vault = declare("0x1");

    assert(declare_result.is_ok(), 'factory declaration failed');
    assert(declare_org.is_ok(), 'org declaration failed');
    assert(declare_vault.is_ok(), 'vault declaration failed');

    let contract_class = declare_result.unwrap().contract_class();

    let deploy_result = contract_class.deploy(@array![owner(), '0x0', '0x1']);

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

    assert(org_address != 0.try_into().unwrap(), 'org deployment failed');
    assert(vault_address != 0.try_into().unwrap(), 'vault deployment failed');
}