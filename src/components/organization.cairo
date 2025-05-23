#[starknet::component]
pub mod OrganizationComponent {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use crate::interfaces::icore::IConfig;
    use crate::structs::core::Config;
    use crate::interfaces::organization::IOrganization;
    use crate::structs::organization::{OrganizationConfigNode, OrganizationConfig};
    use crate::structs::member_structs::MemberTrait;
    use super::super::member_manager::MemberManagerComponent;


    #[storage]
    pub struct Storage {
        pub owner: ContractAddress,
        pub commitee: Map<ContractAddress, u16>, // address -> level of power
        pub config: OrganizationConfigNode // refactor to OrganizationConfig
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {}

    #[embeddable_as(OrganizationImpl)]
    pub impl Organization<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>,
        impl Member: MemberManagerComponent::HasComponent<TContractState>,
    > of IOrganization<ComponentState<TContractState>> {
        fn transfer_ownership(ref self: ComponentState<TContractState>, to: ContractAddress) {
        }
        fn adjust_committee(
            ref self: ComponentState<TContractState>,
            add: Array<ContractAddress>,
            subtract: Array<ContractAddress>,
        ) { // any one subtracted, power would be taken down to zero.
            
        }
    }

    #[generate_trait]
    pub impl InternalImpl<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>,
        impl Member: MemberManagerComponent::HasComponent<TContractState>,
    > of OrganizationInternalTrait<TContractState> {
        fn _init(ref self: ComponentState<TContractState>, owner: ContractAddress) {
        }
    }

    #[abi(embed_v0)]
    pub impl OrganizationConfigImpl<TContractState, +HasComponent<TContractState>> of IConfig<ComponentState<TContractState>> {
        fn update_config(ref self: ComponentState<TContractState>, config: Config) {
            if let Config::Organization(_) = config {

            }
        }
    }
}
