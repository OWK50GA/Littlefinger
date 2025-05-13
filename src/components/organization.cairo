#[starknet::component]
pub mod OrganizationComponent {
    use starknet::ContractAddress;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use crate::interfaces::organization::IOrganization;
    use crate::structs::config::CoreConfigNode;


    #[storage]
    pub struct Storage {
        pub owner: ContractAddress,
        pub commitee: Map<ContractAddress, u16>,    // address -> level of power
        pub config: CoreConfigNode,
    }

    #[embeddable_as(OrganizationImpl)]
    pub impl Organization<
        TContractState, +HasComponent<TContractState>,
    > of IOrganization<ComponentState<TContractState>> {
        fn transfer_ownership(ref self: ComponentState<TContractState>, to: ContractAddress) {}
        fn adjust_committee(
            ref self: ComponentState<TContractState>,
            add: Array<ContractAddress>,
            subtract: Array<ContractAddress>,
        ) {
            // any one subtracted, power would be taken down to zero.
        }
    }

    #[generate_trait]
    pub impl InternalImpl<
        TContractState, +HasComponent<ComponentState<TContractState>>,
    > of OrganizationInternalTrait<TContractState> {
        fn _init(ref self: ComponentState<TContractState>, owner: ContractAddress) {
            self.owner.write(owner);
        }
    }
}
