use littlefinger::structs::member_structs::{MemberResponse, MemberRole};
use littlefinger::tests::mocks::mock_add_member::{
    IMockAddMemberDispatcher, IMockAddMemberDispatcherTrait, MockAddMember,
};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_block_timestamp,
    start_cheat_caller_address, stop_cheat_block_timestamp, stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const};

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

fn member() -> ContractAddress {
    contract_address_const::<'member'>()
}

#[test]
fn test_add_member() {
    let mock_contract = deploy_mock_contract();

    let fname = 'John';
    let lname = 'Doe';
    let alias = 'johndoe';
    let role = MemberRole::EMPLOYEE(5);
    let member = member();

    let caller = caller();

    start_cheat_caller_address(mock_contract.contract_address, caller);
    mock_contract.add_member_pub(fname, lname, alias, role, member);

    let member_response = mock_contract.get_member_pub(1);

    stop_cheat_caller_address(mock_contract.contract_address);
    assert(member_response.fname == fname, 'Wrong first name');
    assert(member_response.lname == lname, 'Wrong last name');
    assert(member_response.alias == alias, 'Wrong alias');
    assert(member_response.role == role, 'Wrong role');
    assert(member_response.address == member, 'Wrong address');
}
