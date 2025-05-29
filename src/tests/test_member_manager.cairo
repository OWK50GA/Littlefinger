use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, start_cheat_block_timestamp, stop_cheat_block_timestamp
};
use littlefinger::structs::member_structs::{MemberRole, MemberResponse};

use littlefinger::tests::mocks::mock_add_member::{MockAddMember, IMockAddMemberDispatcher, IMockAddMemberDispatcherTrait};
use starknet::ContractAddress;
use starknet::contract_address_const;

fn deploy_mock_contract() -> IMockAddMemberDispatcher {
    let contract_class = declare("MockAddMember").unwrap().contract_class();
    let mut calldata = array![];
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    IMockAddMemberDispatcher { contract_address }
}

fn get_mock_contract_state() -> MockAddMember::ContractState {
    MockAddMember::contract_state_for_testing()
}

fn caller() -> ContractAddress {
    contract_address_const::<'caller'>()
}

#[test]
fn test_add_member(){
    let mock_contract = deploy_mock_contract();

    let fname = 'John';
    let lname = 'Doe';
    let alias = 'johndoe';
    let role = MemberRole::EMPLOYEE(5);
    
    let caller = caller();

    start_cheat_caller_address(mock_contract.contract_address, caller);
    mock_contract.add_member_pub(fname, lname, alias, role);

    let member_response = mock_contract.get_member_pub(1);

    stop_cheat_caller_address(mock_contract.contract_address);
    assert(member_response.fname == fname, 'Wrong first name');
    assert(member_response.lname == lname, 'Wrong last name');
    assert(member_response.alias == alias, 'Wrong alias');
    assert(member_response.role == role, 'Wrong role');
}