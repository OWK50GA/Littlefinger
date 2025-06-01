use interfaces::ifactory::IFactory::{IFactoryDispatcher, IFactoryDispatcherTrait};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::ContractAddress;

fn setup() -> ContractAddress {
    let declare_result = declare("Factory");
    assert(declare_result.is_ok(), 'contract decleration failed');

    let contract_class = declare_result.unwrap().contract_class();
    
    let deploy_result = contract_class.deploy(@array![1.try_into().unwrap(), '0x0', '0x1']);
    assert(deploy_result.is_ok(), 'contract deployment failed');

    let (contract_address, _) = deploy_result.unwrap();
    contract_address
}

#[test]
fn test_setup_org() {
    let factory_address = setup();
    let (org_address, vault_address) = factory_address.setup_org(
        available_funds: 1000000000000000000,
        starting_bonus_allocation: 1000000000000000000,
        token: 0.try_into().unwrap(),
        salt: 'test_salt',
        owner: 0.try_into().unwrap(),
        name: "test_name",
        ipfs_url: "test_ipfs_url",
        first_admin_fname: 'test_fname',
        first_admin_lname: 'test_lname',
        first_admin_alias: 'test_alias',
    );
    assert(org_address != 0.try_into().unwrap(), 'org deployment failed');
    assert(vault_address != 0.try_into().unwrap(), 'vault deployment failed');
}